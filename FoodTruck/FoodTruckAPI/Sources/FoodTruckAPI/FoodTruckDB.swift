//
//  FoodTruck.swift
//  FoodTruckAPI
//
//  Created by Tim Beals on 2017-05-09.
//
//

import Foundation
import CloudFoundryEnv
import SwiftyJSON
import CouchDB
import LoggerAPI

#if os(Linux)
    typealias Valuetype = Any
#else
    typealias Valuetype = AnyObject
#endif

//our enum conforms to the Error protocol
public enum APICollectionError: Error {
    case ParseError
    case AuthError
}

//If we are unable to get our app config from the CFEnv we are going to provide some defaults so that we can run on our local host.
//These properties can then be put into the CouchDB struct ConnectionProperties note that the username and password inputs are optional.
// secured - We are testing if the API is running on the localhost (default) then it is unsecured otherwise it is running on bluemix and is secured.
//The convenience is an extra initializer. The first is the default initializer. Note that in main.swift (if there is no service)we call the default initializer with no input parameters. This means that it is initialized with the default parameters we have entered.

public class FoodTruckDB: FoodTruckAPI {
    
    static let defaultDBHost = "localhost"
    static let defaultDBPort = Int16(5984)
    static let defaultDBName = "foodtruckapi"
    static let defaultDBUsername = "tim"
    static let defaultDBPassword = "123456"
    
    let dbName: String
    let designName = "foodtruckdesign"
    
    let connectionProps: ConnectionProperties

    //create initializers
    
    public init (database: String = FoodTruckDB.defaultDBName, host: String = FoodTruckDB.defaultDBHost, port: Int16 = FoodTruckDB.defaultDBPort, username: String? = FoodTruckDB.defaultDBUsername, password: String? = FoodTruckDB.defaultDBPassword) {
        
        dbName = database
        let secured  = (host == FoodTruckDB.defaultDBHost) ? false : true
        connectionProps = ConnectionProperties(host: host, port: port, secured: secured, username: username, password: password)
        
        setupDB()
    }

    public convenience init (service: Service) {
        let host: String
        let port: Int16
        let username: String?
        let password: String?
        
        if let credentials = service.credentials, let tempHost = credentials["host"] as? String, let tempUsername = credentials["username"] as? String, let tempPassword = credentials["password"] as? String, let tempPort = credentials["port"] as? Int16 {
            
            host = tempHost
            port = tempPort
            username = tempUsername
            password = tempPassword
            Log.info("Using CF service credentials")
        } else {
            
            host = FoodTruckDB.defaultDBHost
            port = FoodTruckDB.defaultDBPort
            username = FoodTruckDB.defaultDBUsername
            password = FoodTruckDB.defaultDBPassword
            
            Log.info("Using service development credentials")
        }
        
        //default initializer
        self.init(host: host, port: port, username: username, password: password)
    }
    
    private func setupDB() {
        let couchClient = CouchDBClient(connectionProperties: connectionProps)
        couchClient.dbExists(dbName) { (nameExists: Bool, error: NSError?) in
            if nameExists {
                Log.info("DB exists")
            } else {
                Log.error("DB does not exist \(error)")
                couchClient.createDB(self.dbName, callback: { (database: Database?, error: NSError?) in
                    if database != nil {
                        Log.info("DB was created")
                        self.setupDBDesign(database: database!)
                    } else {
                        Log.error("unable to create database \(self.dbName): Error \(error)")
                    }
                })
            }
        }
    }
    
    private func setupDBDesign(database: Database) {
        let design: [String: Any] = [
            "_id": "design/\(self.designName)",
            "views": [
                "all_documents": [
                    "map": "function(doc) { emit(doc._id, [ doc._id, doc._rev]); }"
                ],
                "all_trucks": [
                    "map": "function(doc) { if (doc.type == 'foodtruck') { emit(doc._id, [doc._id, doc.name, doc.foodtype, doc.avgcost, doc.latitude, doc.longitude]); }}"
                ],
                "total_trucks": [
                    "map": "function(doc) { if (doc.type == 'foodtruck') { emit(doc._id, 1); }}",
                    "reduce": "_count"
                ]
            ]
        ]
        database.createDesign(self.designName, document: JSON(design)) { (json: JSON?, error: NSError?) in
            if error != nil {
                Log.error("Failed to create database design: \(error)")
            } else {
                Log.info("Design created \(json)")
            }
        }
    }
    
    //MARK: FoodTruckAPI Protocol Methods
    
    public func getAllTrucks(completion: @escaping([FoodTruckItem]?, Error?) -> Void) {
        
        let couchClient = CouchDBClient(connectionProperties: connectionProps)
        let database = couchClient.database(dbName)
        database.queryByView("all_trucks", ofDesign: self.designName, usingParameters: [.descending(true), .includeDocs(true)]) { (doc: JSON?, error: NSError?) in
            if let doc = doc, error == nil {
                do {
                    let trucks = try self.parseTrucks(doc)
                    completion(trucks, nil)
                } catch {
                    completion(nil, error)
                }
            } else {
                completion(nil, error)
            }
        }
    }
    
    //Get one specific truck
    public func getTruck(docId: String, completion: @escaping(FoodTruckItem?, Error?) -> Void) {
        
        let couchClient = CouchDBClient(connectionProperties: connectionProps)
        let database = couchClient.database(dbName)
        
        database.retrieve(docId) { (doc:JSON?, error: NSError?) in

            guard let doc = doc,
                let docId = doc["_id"].string,
                let name = doc["name"].string,
                let foodType = doc["foodtype"].string,
                let avgCost = doc["avgcost"].float,
                let latitude = doc["latitude"].float,
                let longitude = doc["longitude"].float
                else {
                    completion(nil, error)
                    return
            }
            
            let foodTruckItem = FoodTruckItem(docId: docId, name: name, foodType: foodType, avgCost: avgCost, latitude: latitude, longitude: longitude)
            completion(foodTruckItem, nil)
        }
        
        
    }
    
    //Create a food truck
    public func addFoodTruck(name: String, foodType: String, avgCost: Float, latitude: Float, longitude: Float, completion: @escaping(FoodTruckItem?, Error?) -> Void) {
        
        let truckJSON: [String: Any] = [
            "type": "foodtruck",
            "name": name,
            "foodtype": foodType,
            "avgcost": avgCost,
            "latitude": latitude,
            "longitude": longitude
        ]
        
        let couchClient = CouchDBClient(connectionProperties: connectionProps)
        let database = couchClient.database(dbName)
        database.create(JSON(truckJSON)) { (id: String?, rev: String?, doc: JSON?, err: NSError?) in
            if let id = id {
                let foodTruckItem = FoodTruckItem(docId: id, name: name, foodType: foodType, avgCost: avgCost, latitude: latitude, longitude: longitude)
                completion(foodTruckItem, nil)
            } else if err != nil {
                completion(nil, err)
            }
            
        }
        
    }
    
    //Tear down method for testing only. No route available in controller
    public func clearAll(completion: @escaping(Error?) -> Void) {
        let couchClient = CouchDBClient(connectionProperties: connectionProps)
        let database = couchClient.database(dbName)
        
        database.queryByView("all_documents", ofDesign: designName, usingParameters: [.descending(true), .includeDocs(true)]) { (doc: JSON?, error: NSError?) in
            
            guard let doc = doc else {
                completion(error)
                return
            }

            guard let idAndRevs = try? self.getIdAndRev(doc) else {
                completion(error)
                return
            }
            
            if idAndRevs.count == 0 {
                completion(nil)
            } else {
                for idAndRev in idAndRevs {
                    database.delete(idAndRev.0, rev: idAndRev.1, callback: { (error: NSError?) in
                        guard error == nil else {
                            Log.error("Deletion error")
                            completion(error)
                            return
                        }
                    })
                }
                completion(nil)
            }
        }
    }
    
    //this method returns an array of tuples.
    private func getIdAndRev(_ document: JSON) throws -> [(String, String)] {
        guard let rows = document["rows"].array else {
            throw APICollectionError.ParseError
        }
        
        return rows.flatMap {
            let doc = $0["doc"]
            let id = doc["_id"].stringValue
            let rev = doc["_rev"].stringValue
            
            return (id, rev)
        }
    }
    
    //Delete one specific food truck
    public func deleteTruck(docId: String, completion: @escaping(Error?) -> Void) {
        
        let couchClient = CouchDBClient(connectionProperties: connectionProps)
        let database = couchClient.database(dbName)
        
        database.retrieve(docId) { (doc: JSON?, error: NSError?) in
            guard let doc = doc, error == nil else {
                completion(error)
                return
            }
            
            //TODO: fetch all reviews for the truck
            
            let rev = doc["_rev"].stringValue
            database.delete(docId, rev: rev, callback: { (error:NSError?) in
                if error == nil {
                    completion(nil)
                } else {
                    completion(error)
                }
            })
        }
    }

    func parseTrucks(_ document: JSON) throws -> [FoodTruckItem] {

        guard let rows = document["rows"].array else {
            throw APICollectionError.ParseError
        }

        let trucks: [FoodTruckItem] = rows.flatMap {
            
            let doc = $0["value"]
            
            guard let id = doc[0].string,
            let name = doc[1].string,
            let foodType = doc[2].string,
            let avgCost = doc[3].float,
            let latitude = doc[4].float,
            let longitude = doc[5].float else {
                return nil
            }
            return FoodTruckItem(docId: id, name: name, foodType: foodType, avgCost: avgCost, latitude: latitude, longitude: longitude)
        }
        return trucks
    }
    
    
    //update single foodtruck
    public func updateFoodTruck(docId: String, name: String?, foodtype: String?, avgcost: Float?, latitude: Float?, longitude: Float?, completion: @escaping (FoodTruckItem?, Error?) -> Void) {
        
        let couchClient = CouchDBClient(connectionProperties: connectionProps)
        let database = couchClient.database(dbName)
        
        database.retrieve(docId) { (doc:JSON?, error:NSError?) in
            
            guard let doc = doc else {
                completion(nil, APICollectionError.AuthError)
                return
            }
            
            guard let revision = doc["_rev"].string else {
                completion(nil, APICollectionError.ParseError)
                return
            }
            
            let type = "foodtruck"
            let name = name ?? doc["name"].stringValue
            let foodtype = foodtype ?? doc["foodtype"].stringValue
            let avgcost = avgcost ?? doc["avgcost"].floatValue
            let latitude = latitude ?? doc["latitude"].floatValue
            let longitude = longitude ?? doc["longitude"].floatValue
            
            let json: [String: Any] = [
                "type": type,
                "name": name,
                "foodtype": foodtype,
                "avgcost": avgcost,
                "latitude": latitude,
                "longitude": longitude
            ]
            
            database.update(docId, rev: revision, document: JSON(json), callback: { (rev:String?, doc:JSON?, err:NSError?) in
                
                guard err == nil else {
                    completion(nil, err)
                    return
                }
                
                
                let updatedTruck = FoodTruckItem(docId: docId, name: name, foodType: foodtype, avgCost: avgcost, latitude: latitude, longitude: longitude)
                
                completion(updatedTruck, nil)
            })
        }
    }
    
    public func getTruckCount(completion: @escaping (Int?, Error?) -> Void) {
        let couchClient = CouchDBClient(connectionProperties: connectionProps)
        let database = couchClient.database(dbName)
        
        database.queryByView("total_trucks", ofDesign: self.designName, usingParameters: []) { (doc:JSON?, err:NSError?) in
            
            if let doc = doc, err == nil {
                if let count = doc["rows"][0]["value"].int {
                    completion(count, nil)
                } else {
                    completion(0, nil)
                }
            } else {
                completion(nil, err)
            }
        }
    }
}
