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
    static let defaultDBUsername = "Tim"
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
                let docId = doc["id"].string,
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
    
    //Tear down method
    public func clearAll(completion: @escaping(Error?) -> Void) {
        
    }
    
    //Delete one specific food truck
    public func deleteTruck(docId: String, completion: @escaping(Error?) -> Void) {
        
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
}
