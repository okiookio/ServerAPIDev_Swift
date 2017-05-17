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
    
    //MARK: Setup views
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
                ],
                "all_reviews": [
                    "map": "function(doc) { if (doc.type == 'review') { emit(doc.foodtruckid, [doc.foodtruckid, doc._id, doc.reviewtitle, doc.reviewtext, doc.starrating]); }}"
                ],
                "total_reviews": [
                    "map": "function(doc) { if (doc.type == 'review') { emit(doc.foodtruckid, 1); }}",
                    "reduce": "_count"
                ],
                "avg_rating": [
                    "map": "function(doc) { if (doc.type == 'review') { emit(doc.foodtruckid, doc.starrating); }}",
                    "reduce": "_stats"
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
    
    //Get db once it has been setup
    func getDatabase() -> Database {
        let couchClient = CouchDBClient(connectionProperties: connectionProps)
        return couchClient.database(dbName)
    }
    
    //MARK: FoodTruckAPI Protocol Methods
    
    //Get all trucks
    public func getAllTrucks(completion: @escaping([FoodTruckItem]?, Error?) -> Void) {
        
        let database = getDatabase()
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
    
    //note that the parsing order is determined in the definition of the view "all_trucks".
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
    
    //Get one specific truck
    public func getTruck(docId: String, completion: @escaping(FoodTruckItem?, Error?) -> Void) {
        
        let database = getDatabase()
        
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
        
        let database = getDatabase()
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
        let database = getDatabase()
        
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
        
        let database = getDatabase()
        
        database.retrieve(docId) { (doc: JSON?, error: NSError?) in
            guard let doc = doc, error == nil else {
                completion(error)
                return
            }
            

            self.getReviews(truckId: docId, completion: { (reviews:[ReviewItem]?, error: Error?) in
                
                guard error == nil else {
                    completion(error)
                    return
                }
                
                guard let reviews = reviews, error == nil else {
                    completion(error)
                    return
                }
                
                for review in reviews {
                    self.deleteReview(docId: review.docId, completion: { (error:Error?) in
                        guard error == nil else {
                            completion(error)
                            return
                        }
                    })
                }
                
                let rev = doc["_rev"].stringValue
                database.delete(docId, rev: rev, callback: { (error:NSError?) in
                    if error == nil {
                        completion(nil)
                    } else {
                        completion(error)
                    }
                })
            })
        }
    }
    

    
    
    //update single foodtruck
    public func updateFoodTruck(docId: String, name: String?, foodtype: String?, avgcost: Float?, latitude: Float?, longitude: Float?, completion: @escaping (FoodTruckItem?, Error?) -> Void) {
        
        let database = getDatabase()
        
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
        let database = getDatabase()
        
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
    
    //MARK: Review methods from FoodTruckAPI Protocol
    
    //Get all reviews for a specific truck
    //Note that we need the .keys parameter. The view declaration shows the [key: value] as [truckId: [params]] so we need to pass our truckId into the query to only return the reviews for the one truck.
    
    public func getReviews(truckId: String, completion: @escaping([ReviewItem]?, Error?) -> Void) {
        let database = getDatabase()
        
        database.queryByView("all_reviews", ofDesign: self.designName, usingParameters: [.keys([truckId as Valuetype]), .descending(true), .includeDocs(true)]) { (doc:JSON?, error:NSError?) in
            
            if let doc = doc, error == nil {
                do {
                    let reviews = try self.parseReviews(doc)
                    completion(reviews, nil)
                } catch {
                    completion(nil, error)
                }
            } else {
                completion(nil, error)
            }
        }
    }
    
    func parseReviews(_ document: JSON) throws -> [ReviewItem] {
        
        guard let rows = document["rows"].array else {
            throw APICollectionError.ParseError
        }
        
        let reviews: [ReviewItem] = rows.flatMap {
            
            let doc = $0["value"]
            
            guard let foodtruckid = doc[0].string,
                let docid = doc[1].string,
                let reviewtitle = doc[2].string,
                let reviewtext = doc[3].string,
                let starrating = doc[4].int else {
                return nil
            }
            return ReviewItem(docId: docid, foodTruckId: foodtruckid, reviewTitle: reviewtitle, reviewText: reviewtext, starRating: starrating)
        }
        return reviews
    }
    
    
    //Get a specific review by id
    public func getReviewById(docId: String, completion: @escaping(ReviewItem?, Error?) -> Void) {

        let database = getDatabase()
        
        database.retrieve(docId) { (doc:JSON?, error:NSError?) in
            guard let doc = doc else {
                completion(nil, error)
                return
            }
            
            guard let docid = doc["_id"].string,
            let foodtruckid = doc["foodtruckid"].string,
            let reviewtitle = doc["reviewtitle"].string,
            let reviewtext = doc["reviewtext"].string,
                let starrating = doc["starrating"].int else {
                    completion(nil, error)
                    return
            }
            
            let review = ReviewItem(docId: docid, foodTruckId: foodtruckid, reviewTitle: reviewtitle, reviewText: reviewtext, starRating: starrating)
            completion(review, nil)
        }
    }
    
    //Add a review for a specific truck
    public func addReview(truckId: String, reviewTitle: String, reviewText: String, reviewStarRating: Int, completion: @escaping(ReviewItem?, Error?) -> Void) {
        
        let reviewJSON: [String: Any] = [
            "type": "review",
            "foodtruckid": truckId,
            "reviewtitle": reviewTitle,
            "reviewtext": reviewText,
            "starrating": reviewStarRating
        ]
        
        let database = getDatabase()
        database.create(JSON(reviewJSON)) { (id:String?, rev:String?, doc:JSON?, error:NSError?) in
            guard error != nil else {
                completion(nil, error)
                return
            }
            
            if let id = id {
                let review = ReviewItem(docId: id, foodTruckId: truckId, reviewTitle: reviewTitle, reviewText: reviewText, starRating: reviewStarRating)
                completion(review, nil)
            } else {
                completion(nil, nil)
            }
        }
    }
    
    //Update a specific review
    public func updateReview(docId: String, truckId: String?, reviewTitle: String?, reviewText: String?, reviewStarRating: Int?, completion: @escaping(ReviewItem?, Error?) -> Void) {
        
        let database = getDatabase()
        
        //perform retrieve to get existing params and revision number
        database.retrieve(docId) { (doc:JSON?, error:NSError?) in
            
            guard let doc = doc else {
                completion(nil, APICollectionError.AuthError)
                return
            }
            
            guard let revision = doc["_rev"].string else {
                completion(nil, APICollectionError.ParseError)
                return
            }
            
            let type = "review"
            let truckid = truckId ?? doc["foodtruckid"].stringValue
            let reviewtitle = reviewTitle ?? doc["reviewtitle"].stringValue
            let reviewtext = reviewText ?? doc["reviewtext"].stringValue
            let starrating = reviewStarRating ?? doc["starrating"].intValue
            
            let reviewJSON: [String: Any] = [
                "type": type,
                "foodtruckid": truckid,
                "reviewtitle": reviewtitle,
                "reviewtext": reviewtext,
                "starrating": starrating
            ]

            database.update(docId, rev: revision, document: JSON(reviewJSON), callback: { (revision:String?, doc:JSON?, error: NSError?) in
                guard error == nil else {
                    completion(nil, error)
                    return
                }
                
                let updatedReview = ReviewItem(docId: docId, foodTruckId: truckid, reviewTitle: reviewtitle, reviewText: reviewtext, starRating: starrating)
                completion(updatedReview, nil)
            })
        }
    }
    
    //Delete specific review
    public func deleteReview(docId: String, completion: @escaping(Error?) -> Void) {
        
        let database = getDatabase()
        
        database.retrieve(docId) { (doc:JSON?, error:NSError?) in
            
            guard let doc = doc, error == nil else {
                completion(error)
                return
            }

            guard let revision = doc["_rev"].string else {
                completion(APICollectionError.ParseError)
                return
            }
            
            database.delete(docId, rev: revision, callback: { (error:NSError?) in
                if error == nil {
                    completion(nil)
                } else {
                    completion(error)
                }
            })
        }
    }
    
    //count all reviews
    public func getAllReviewsCount(completion: @escaping(Int?, Error?) -> Void) {
        
        let database = getDatabase()
        database.queryByView("total_reviews", ofDesign: self.designName, usingParameters: []) { (doc:JSON?, error:NSError?) in
            
            if let doc = doc, error == nil {
                
                if let count = doc["rows"][0]["value"].int {
                    completion(count, nil)
                } else {
                    completion(0, error)
                }
            } else {
                completion(nil, error)
            }
        }
    }

    //count all reviews for specific truck
    public func getReviewsCountForTruck(truckId: String, completion: @escaping(Int?, Error?) -> Void) {
        
        let database = getDatabase()
        
        database.queryByView("total_reviews", ofDesign: self.designName, usingParameters: [.keys([truckId as Valuetype])]) { (doc:JSON?, error:NSError?) in
         
            if let doc = doc, error == nil {
                
                if let count = doc["rows"][0]["value"].int {
                    completion(count, nil)
                } else {
                    completion(0, nil)
                }
            } else {
                completion(nil, error)
            }
        }
        
    }
    
    //Avg star rating for a specific truck
    public func getAvgRating(truckId: String, completion: @escaping(Int?, Error?) -> Void) {
        
        let database = getDatabase()
        database.queryByView("avg_rating", ofDesign: self.designName, usingParameters: [.keys([truckId as Valuetype])]) { (doc:JSON?, error:NSError?) in
            
            if let doc = doc, error == nil {
                
                if let sum = doc["rows"][0]["value"]["sum"].float, let count = doc["rows"][0]["value"]["count"].float {
                    let avg = Int(round(sum / count))
                    completion(avg, nil)
                } else {
                    completion(1, nil)
                }
            } else {
                completion(nil, error)
            }
        }
    }
}
