//
//  FoodTruckController.swift
//  FoodTruckAPI
//
//  Created by Tim Beals on 2017-05-10.
//
//

import Foundation
import Kitura
import LoggerAPI
import SwiftyJSON


//final keyword means that the class is not able to be extended
//trucks is your delegate. The class that you assign to trucks will conform to the protoco. When you call the protocol methods in this class, the trucks property will perform those methods according to their implementation in its class.
//routeSetup: 'all' indicates that all requests (get, put post etc) will go through the root and be handled by middleware. Bodyparser is provided by Kitura. It allows us to parse the body of a request and pull values out of it.



public final class FoodTruckController {
    
    public let foodTruckDB: FoodTruckAPI
    public let router = Router()
    public let trucksPath = "api/v1/trucks"
    
    public init(backend: FoodTruckAPI) {
        self.foodTruckDB = backend
        routeSetup()
    }
    
    public func routeSetup() {
        router.all("/*", middleware: BodyParser())
      
        //get all trucks
        router.get(trucksPath, handler: getTrucks)
        //get one truck by id
        router.get("\(trucksPath)/:id", handler: getTruckById)
        
        //add one truck
        router.post(trucksPath, handler: addTruck)
        
    
    }
    
    private func getTrucks(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        foodTruckDB.getAllTrucks { (trucks: [FoodTruckItem]?, error: Error?) in
            do {
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                
                guard let trucks = trucks else {
                    try response.status(.internalServerError).end()
                    Log.error("failed to get trucks")
                    return
                }
                
                let json = JSON(trucks.toDict())
                try response.status(.OK).send(json: json).end()
            } catch {
                Log.error("Communication error")
            }
        }
    }
    
    
    //the truck will be in the request body
    private func addTruck(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        guard let body = request.body else {
            response.status(.badRequest)
            Log.error("No body in request")
            return
        }
        
        //kitura parsed body enum checks the body type is json
        guard case let .json(json) = body else {
            response.status(.badRequest)
            Log.error("invalid json supplied in body")
            return
        }
        
        //provided the json is legitimate, we can pull values out of the document
        let name: String = json["name"].stringValue
        let foodType: String = json["foodtype"].stringValue
        let avgCost: Float = json["avgcost"].floatValue
        let latitude: Float = json["latitude"].floatValue
        let longitude: Float = json["longitude"].floatValue
        
        guard name != "" else {
            response.status(.badRequest)
            Log.error("necessary json field not supplied")
            return
        }
        
        foodTruckDB.addFoodTruck(name: name, foodType: foodType, avgCost: avgCost, latitude: latitude, longitude: longitude) { (foodTruckItem: FoodTruckItem?, error: Error?) in
            
            do {
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                
                guard let foodTruckItem = foodTruckItem else {
                    try response.status(.internalServerError).end()
                    Log.error("Truck not found")
                    return
                }
                
                let result = JSON(foodTruckItem.toDict())
                Log.info("\(name) added to vehicles")
                
                do {
                    try response.status(.OK).send(json: result).end()
                } catch {
                    Log.error("Error sending response")
                }
                
            } catch {
                Log.error("Communications error")
            }
        }
    }
    
    private func getTruckById(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        
        guard let id = request.parameters["id"] else {
            response.status(.badRequest)
            Log.error("No id supplied")
            return
        }
        
        foodTruckDB.getTruck(docId: id) { (foodTruckItem: FoodTruckItem?, error:Error?) in
            do {
                
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }

                
                guard let foodTruckItem = foodTruckItem else {
                    try response.status(.notFound).end()
                    Log.error("Could not find item with provided id")
                    return
                }
                
                let result = JSON(foodTruckItem.toDict())
                
                do {
                    try response.status(.OK).send(json: result).end()
                } catch {
                    Log.error("Error sending response")
                }
                
            } catch {
                Log.error("Communications error")
            }
        }
        
    }
}
