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
    public let reviewsPath = "api/v1/reviews"
    
    public init(backend: FoodTruckAPI) {
        self.foodTruckDB = backend
        routeSetup()
    }
    
    public func routeSetup() {
        router.all("/*", middleware: BodyParser())
      
        //MARK: truck methods
        //get all trucks
        router.get(trucksPath, handler: getTrucks)
        
        //get truck count
        router.get("\(trucksPath)/count", handler: getTrucksCount)

        //get one truck by id
        router.get("\(trucksPath)/:id", handler: getTruckById)
        
        //add one truck
        router.post(trucksPath, handler: addTruck)
        
        //delete one truck
        router.delete("\(trucksPath)/:id", handler: deleteTruckById)
        
        //update one truck
        router.put("\(trucksPath)/:id", handler: updateTruckById)
    
        //MARK: review methods
        //get all reviews for a specific truck
        router.get("\(trucksPath)/reviews/:id", handler: getAllReviewsForTruck)
        
        //get single specific review
        router.get("\(reviewsPath)/:id", handler: getReviewById)
        
        //add review
        router.post("\(reviewsPath)/:id", handler: addReviewByTruckId)
        
        //update review (put)
        router.put("\(reviewsPath)/:id", handler: updateReviewById)
        
        //delete review
        router.delete("\(reviewsPath)/:id", handler: deleteReviewById)
        
        //reviews count (all)
        router.get("\(reviewsPath)/count", handler: getReviewsCount)
        
        //reviews count (one truck)
        router.get("\(reviewsPath)/count/:id", handler: getReviewsCountByTruckId)
        
        //avg rating (one truck)
        router.get("\(reviewsPath)/rating/:id", handler: getReviewsAverageByTruckId)
        
        
        
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
    
    private func deleteTruckById(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        guard let id = request.parameters["id"] else {
            response.status(.badRequest)
            Log.error("No id supplied")
            return
        }

        foodTruckDB.deleteTruck(docId: id) { (error: Error?) in
           
            do {
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                try response.status(.OK).end()
                Log.info("\(id) was successfully deleted")
            } catch {
                Log.error("Communication error")
            }
        }
    }
    
    private func  updateTruckById(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        
        guard let docId = request.parameters["id"] else {
            response.status(.badRequest)
            Log.error("ID not found in request")
            return
        }
        
        guard let body = request.body else {
            response.status(.badRequest)
            Log.error("Body not found in request")
            return
        }
        
        guard case let .json(json) = body else {
            response.status(.badRequest)
            Log.error("Invalid json supplied")
            return
        }
        
        let name: String? = json["name"].stringValue == "" ? nil : json["name"].stringValue
        let foodType: String? = json["foodtype"].stringValue == "" ? nil : json["foodtype"].stringValue
        let avgCost: Float? = json["avgcost"].floatValue == 0 ? nil : json["avgcost"].floatValue
        let latitude: Float? = json["laitude"].floatValue == 0 ? nil : json["latitude"].floatValue
        let longitude: Float? = json["longitude"].floatValue == 0 ? nil : json["longitude"].floatValue
        
        foodTruckDB.updateFoodTruck(docId: docId, name: name, foodtype: foodType, avgcost: avgCost, latitude: latitude, longitude: longitude) { (foodTruck:FoodTruckItem?, error:Error?) in
            
            do {
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                
                if let updatedTruck = foodTruck {
                    let result = JSON(updatedTruck.toDict())
                    try response.status(.OK).send(json: result).end()
                } else {
                    Log.error("Invalid truck returned")
                    try response.status(.badRequest).end()
                }
            } catch {
                Log.error("Communication error")
            }
        }
    }
    
    private func getTrucksCount(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        
        foodTruckDB.getTruckCount { (count:Int?, error:Error?) in
            
            do {
                
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                
                guard let count = count else {
                    try response.status(.internalServerError).end()
                    Log.error("Failed to get count")
                    return
                }
                
               let result = JSON(["count": count])
               try response.status(.OK).send(json: result).end()
            } catch {
                Log.error("Communication error")
            }
            
        }
    }
    
    //MARK: Reviews Methods
    
    private func getAllReviewsForTruck(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        
        guard let truckId = request.parameters["id"] else {
            response.status(.badRequest)
            Log.error("ID note found in request")
            return
        }
        
        foodTruckDB.getReviews(truckId: truckId) { (reviews:[ReviewItem]?, error:Error?) in
            do {
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                
                guard let reviews = reviews else {
                    try response.status(.internalServerError).end()
                    Log.error("Reviews unable to be unwrapped")
                    return
                }
                
                //toDict() created as extension for array in FoodTruckItem.swift
                let json = JSON(reviews.toDict())
                try response.status(.OK).send(json: json).end()
                
            } catch {
                Log.error("Communications error")
            }
        }
    }
    
    private func getReviewById(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        
        guard let docId = request.parameters["id"] else {
            response.status(.badRequest)
            Log.error("ID not found in request")
            return
        }
        
        foodTruckDB.getReviewById(docId: docId) { (review:ReviewItem?, error:Error?) in
            
            do {
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }

                guard let review = review else {
                    try response.status(.notFound).end()
                    Log.error("Could not find a review by provided id")
                    return
                }

                let reviewJSON = JSON(review.toDict())
                try response.status(.OK).send(json: reviewJSON).end()
                
            } catch {
                Log.error("Communications error")
            }
        }
    }

    private func addReviewByTruckId(request: RouterRequest, response: RouterResponse, next: () -> Void) {

        guard let truckId = request.parameters["id"] else {
            response.status(.badRequest)
            Log.error("Truck ID not found in request")
            return
        }
        
        guard let body = request.body else {
            response.status(.badRequest)
            Log.error("No body in request")
            return
        }
        
        //ensures that variable json is of type .json
        guard case let .json(json) = body else {
            response.status(.badRequest)
            Log.error("invalid json sent in body")
            return
        }
        
        let reviewtitle = json["reviewtitle"].stringValue
        let reviewtext = json["reviewtext"].stringValue
        let reviewstarrating = json["reviewstarrating"].intValue
        
        
        guard reviewtitle != "" else {
            response.status(.badRequest)
            Log.error("necessary field empty")
            return
        }
        
        foodTruckDB.addReview(truckId: truckId, reviewTitle: reviewtitle, reviewText: reviewtext, reviewStarRating: reviewstarrating) { (review:ReviewItem?, error:Error?) in
            
            do {
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                
                guard let review = review else {
                    try response.status(.internalServerError).end()
                    Log.error("Review not found")
                    return
                }
                
                let result = JSON(review.toDict())
                Log.info("\(reviewtitle) added to vehicle list")
                
                do {
                    try response.status(.OK).send(json: result).end()
                } catch {
                    Log.error("error sending response")
                }
            } catch {
                Log.error("Communications error")
            }
        }
    }

    private func updateReviewById(request: RouterRequest, response: RouterResponse, next: () -> Void) {
     
        guard let docId = request.parameters["id"] else {
            response.status(.badRequest)
            Log.error("ID not found in request")
            return
        }
        
        guard let body = request.body else {
            response.status(.badRequest)
            Log.error("Body not included in request")
            return
        }

        guard case let .json(json) = body else {
            response.status(.badRequest)
            Log.error("invalid json in body of request")
            return
        }
        
        let truckid: String? = json["foodtruckid"].stringValue == "" ? nil : json["foodtruckid"].stringValue
        let reviewtitle: String? = json["reviewtitle"].stringValue == "" ? nil : json["reviewtitle"].stringValue
        let reviewtext: String? = json["reviewtext"].stringValue == "" ? nil : json["reviewtext"].stringValue
        let reviewstarrating: Int? = json["starrating"].intValue == 0 ? nil : json["starrating"].intValue
        
        foodTruckDB.updateReview(docId: docId, truckId: truckid, reviewTitle: reviewtitle, reviewText: reviewtext, reviewStarRating: reviewstarrating) { (review:ReviewItem?, error:Error?) in
            
            do {
                
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }

                guard let review = review else {
                    try response.status(.internalServerError).end()
                    Log.error("Review not found")
                    return
                }

                let result = JSON(review.toDict())
                Log.info("\(reviewtitle) was updated")
                
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

    private func deleteReviewById(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        
        guard let docId = request.parameters["id"] else {
            response.status(.badRequest)
            Log.error("ID not found in request")
            return
        }
        
        foodTruckDB.deleteReview(docId: docId) { (error:Error?) in
            do {
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                
                try response.status(.OK).end()
                Log.info("\(docId) was successfully deleted")
                
            } catch {
                Log.error("Communications error")
            }
        }
    }
    
    private func getReviewsCount(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        
        foodTruckDB.getAllReviewsCount { (count:Int?, error:Error?) in

            do {
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                
                guard let count = count else {
                    try response.status(.internalServerError).end()
                    Log.error("Failed to get count")
                    return
                }

                let result = JSON(["count": count])
                try response.status(.OK).send(json: result).end()
                Log.info("Count was successfully retrieved")
            } catch {
                Log.error("Communications error")
            }
        }
    }
    
    
    private func getReviewsCountByTruckId(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        
        guard let truckId = request.parameters["id"] else {
            response.status(.badRequest)
            Log.error("Truck id not found in request")
            return
        }
        
        foodTruckDB.getReviewsCountForTruck(truckId: truckId) { (count:Int?, error:Error?) in
            
            do {
                
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }

                
                guard let count = count else {
                    try response.status(.internalServerError).end()
                    Log.error("Failed to get count")
                    return
                }

                let result = JSON(["count": count])
                try response.status(.OK).send(json: result).end()
            
                Log.info("Count for truck \(truckId) was successfully retrieved")
            } catch {
                Log.error("Communications error")
            }
        }
    }
    
    private func getReviewsAverageByTruckId(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        
        guard let truckId = request.parameters["id"] else {
            response.status(.badRequest)
            Log.error("Truck id not found in request")
            return
        }
        
        foodTruckDB.getAvgRating(truckId: truckId) { (avg:Int?, error:Error?) in
            
            do {
                guard error == nil else {
                    try response.status(.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                
                guard let avg = avg else {
                    try response.status(.internalServerError).end()
                    Log.error("Failed to get average")
                    return
                }

                let result = JSON(["averagerating": avg])
                try response.status(.OK).send(json: result).end()
                Log.info("Average successfully retrieved")
                
            } catch {
                Log.error("Communications error")
            }
        }
    }
    
}
