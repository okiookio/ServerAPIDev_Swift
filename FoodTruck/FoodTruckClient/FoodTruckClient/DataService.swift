//
//  DataService.swift
//  FoodTruckClient
//
//  Created by Tim Beals on 2017-05-23.
//  Copyright © 2017 Tim Beals. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


//The purpose of this delegate is to let other classes know when one of these networking tasks has been completed.

protocol DataServiceDelegate: class {
    
    func trucksLoaded()
    func reviewsLoaded()
    func averageRatingUpdated()
}

class DataService {
    //This is our singleton
    static let sharedInstance = DataService()
    
    weak var delegate: DataServiceDelegate?
    var foodTrucks = [FoodTruck]()
    var reviews = [FoodTruckReview]()
    var averageRating: Int = 0
    

//    GET all trucks (NSURLSESSIONS)
    func getAllFoodTrucks() {
        
        //create session and optionally set URLSessionDelegate
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        //create a request
        guard let url = URL(string: GET_ALL_FT_URL) else { return }
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data:Data?, response:URLResponse?, error:Error?) in
            
            if error == nil {
                //success 
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("URLSessions task succeeded: HTTP \(statusCode)")
                if let data = data {
                    self.foodTrucks = FoodTruck.parseFoodTruckJSONData(data: data)
                    self.delegate?.trucksLoaded()
                }
            } else {
                print("NSURLSession get error: \(error?.localizedDescription)")
            }
            
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    //GET all reviews for a specific food truck (NSURLSESSIONS)
    func getAllReviews(_ foodTruck: FoodTruck) {
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        guard let url = URL(string: "\(GET_FT_REVIEWS_URL)/\(foodTruck.docId)") else { return }
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data:Data?, response:URLResponse?, error:Error?) in
            
            if error == nil {
                if let data = data {
                    let statusCode = (response as! HTTPURLResponse).statusCode
                    print("URLSessions datatask succeeded: HTTP \(statusCode)")
                    self.reviews = FoodTruckReview.parseReviewsJSON(data: data)
                    self.delegate?.reviewsLoaded()
                }
            } else {
                print("URLSession datatask error: \(error?.localizedDescription)")
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    //POST add a new foodtruck (NSURLSESSIONS)
    
    func addNewFoodTruck(_ name: String, foodType: String, avgCost: Double, latitude: Double, longitude: Double, completion: @escaping callback) {
        
        //setup request with URL and json data
        guard let url = URL(string: POST_FT_URL) else {
            completion(false)
            return
        }
        
        let urlRequest = NSMutableURLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        let bodyJSON: [String: Any] = [
            "name": name,
            "foodtype": foodType,
            "avgcost": avgCost,
            "latitude": latitude,
            "longitude": longitude,
            ]
        
        var bodyData: Data
        do {
            bodyData = try JSONSerialization.data(withJSONObject: JSON(bodyJSON), options: [])
            urlRequest.httpBody = bodyData
        } catch let error {
            print("Could not convert json to data: \(error.localizedDescription)")
            completion(false)
            return
        }
    
        //setup configuration and session
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        let task = session.dataTask(with: urlRequest as URLRequest) { (data:Data?, response:URLResponse?, error:Error?) in
            
            guard error == nil else {
                print("Error in POST datatask: \(error?.localizedDescription)")
                completion(false)
                return
            }
            
            let statusCode = (response as! HTTPURLResponse).statusCode
            print("URLSessions POST request succeeded: HTTP \(statusCode)")
            self.getAllFoodTrucks()
            completion(true)
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    //POST add foodtruck review (NSURLSESSIONS)
    func addNewReviewTo(_ foodtruckId: String, title: String, text: String, rating: Int, completion: @escaping callback) {
        
        //url
        guard let url = URL(string: "\(POST_REVIEW_URL)/\(foodtruckId)") else {
            print("error creating url")
            completion(false)
            return
        }
        
        //request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        
        let bodyJSON: [String: Any] = [
            "truckid": foodtruckId,
            "reviewtitle": title,
            "reviewtext": text,
            "starrating": rating
        ]
        
        var bodyData: Data
        do {
            bodyData = try JSONSerialization.data(withJSONObject: JSON(bodyJSON), options: [])
            urlRequest.httpBody = bodyData
        } catch {
            print("could not convert json to data")
            completion(false)
            return
        }
        
        
        //configuration
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        //session performs datatask
        let task = session.dataTask(with: urlRequest) { (data:Data?, response:URLResponse?, error:Error?) in
            
            guard error == nil else {
                print("An error occured in POST review datatask: \(error?.localizedDescription)")
                completion(false)
                return
            }

            let statusCode = (response as! HTTPURLResponse).statusCode
            print("POST review data task succeeded with status code: \(statusCode)")
            completion(true)
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }

    //GET average star rating for specific truck (NSURLSESSIONS)

    func getAvgRating(_ foodtruck: FoodTruck) {
        
        //url 
        guard let url = URL(string: "\(GET_FT_STAR_URL)/\(foodtruck.docId)") else {
            print("error creating url")
            return
        }

        let urlRequest = URLRequest(url: url)
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        //datatask
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            
            guard error == nil else {
                print("An error occured in GET average rating: \(error?.localizedDescription)")
                return
            }

            if let data = data {
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("GET average rating succeeded with status code: HTTP \(statusCode)")
                
                let json = JSON(data: data)
                if let avgRating = json["averagerating"].int {
                    self.averageRating = avgRating
                } else {
                    self.averageRating = 0
                }
                self.delegate?.averageRatingUpdated()
            } else {
                print("Could not unwrap data")
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    
    //MARK: ALAMOFIRE METHODS
    
    //GET all trucks (ALAMOFIRE)
//        func getAllFoodTrucks() {
//            let url = GET_ALL_FT_URL
//    
//            Alamofire.request(url, method: .get)
//                .validate(statusCode: 200..<300)
//                .responseData { (response:DataResponse<Data>) in
//    
//                    guard response.result.error == nil else {
//                        print("Alamofire get error: \(response.result.error?.localizedDescription)")
//                        return
//                    }
//    
//                    guard let data = response.data, let statusCode = response.response?.statusCode else {
//                        print("An error occured obtaining data")
//                        return
//                    }
//    
//                    print("Alamofire request succeeded: \(statusCode)")
//                    self.foodTrucks = FoodTruck.parseFoodTruckJSONData(data: data)
//                    self.delegate?.trucksLoaded()
//            }
//        }
    
    //GET all reviews for a specific food truck (ALAMOFIRE)
    //    func getAllReviews(_ foodTruck: FoodTruck) {
    //
    //        let url = "\(GET_FT_REVIEWS_URL)/\(foodTruck.docId)"
    //
    //        Alamofire.request(url, method: .get)
    //            .validate(statusCode: 200..<300)
    //            .responseData { (response:DataResponse<Data>) in
    //
    //                guard response.result.error == nil else {
    //                    print("Alamofire GET error: \(response.result.error?.localizedDescription)")
    //                    return
    //                }
    //
    //                guard let data = response.data, let statusCode = response.response?.statusCode else {
    //                    print("An error occured obtaining data")
    //                    return
    //                }
    //                print("Alamofire get request succeeded: HTTP \(statusCode)")
    //                self.reviews = FoodTruckReview.parseReviewsJSON(data: data)
    //                self.delegate?.reviewsLoaded()
    //        }
    //    }
    
    //POST add a new foodtruck (ALAMOFIRE)
//        func addNewFoodTruck(_ name: String, foodType: String, avgCost: Double, latitude: Double, longitude: Double, completion: @escaping callback) {
//    
//            let url = POST_FT_URL
//    
//            let headers = [
//                "Content-Type":"application/json; charset=utf-8",
//            ]
//    
//            let body: [String: Any] = [
//                "name": name,
//                "foodtype": foodType,
//                "avgcost": avgCost,
//                "latitude": latitude,
//                "longitude": longitude,
//            ]
//    
//            Alamofire.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
//            .validate(statusCode: 200..<300)
//                .responseJSON { (response:DataResponse<Any>) in
//                    if response.result.error == nil {
//                        guard let statusCode = response.response?.statusCode else {
//                            print("An error occured")
//                            completion(false)
//                            return
//                        }
//                        print("Alamofire POST request succeeded: HTTP \(statusCode)")
//                        self.getAllFoodTrucks()
//                        completion(true)
//                    } else {
//                        print("Alamofire POST request error \(response.result.error?.localizedDescription)")
//                        completion(false)
//                    }
//            }
//        }

    //POST add foodtruck review (ALAMOFIRE)
    //    func addNewReviewTo(_ foodtruckId: String, title: String, text: String, rating: Int, completion: @escaping callback) {
    //
    //        let url = "\(POST_REVIEW_URL)/\(foodtruckId)"
    //
    //        let headers = ["Content-Type": "application/json; charset=utf8"]
    //
    //        let body: [String: Any] = [
    //            "truckid": foodtruckId,
    //            "reviewtitle": title,
    //            "reviewtext": text,
    //            "starrating": rating
    //        ]
    //
    //        Alamofire.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
    //        .validate(statusCode: 200..<300)
    //            .responseJSON { (response:DataResponse<Any>) in
    //
    //                //check error nil
    //                guard response.result.error == nil else {
    //                    print("Alamofire request responded with error: HTTP \(response.result.error)")
    //                    completion(false)
    //                    return
    //                }
    //
    //                //get status code
    //                guard let statusCode = response.response?.statusCode else {
    //                    print("error getting status code")
    //                    completion(false)
    //                    return
    //                }
    //
    //                print("Alamofire successfully added review: HTTP \(statusCode)")
    //                //self.getAllReviews(foodtruck)
    //                completion(true)
    //        }
    //    }
    
    //GET average star rating for specific truck (ALAMOFIRE)
    
    //    func getAvgRating(_ foodtruck: FoodTruck) {
    //
    //        let url = "\(GET_FT_STAR_URL)/\(foodtruck.docId)"
    //
    //        Alamofire.request(url, method: .get)
    //        .validate(statusCode: 200..<300)
    //            .responseJSON { (response:DataResponse<Any>) in
    //
    //                //check error is nil
    //                guard response.result.error == nil else {
    //                    print("An error occured in the GET star rating request: \(response.result.error)")
    //
    //                    return
    //                }
    //
    //                //get status code and json object
    //                if let statusCode = response.response?.statusCode, let data = response.result.value {
    //
    //                    print("GET average star rating succeeded with code: HTTP \(statusCode)")
    //
    //                    let json = JSON(data)
    //                    if let avgRating = json["averagerating"].int {
    //                        self.averageRating = avgRating
    //                        self.delegate?.averageRatingUpdated()
    //
    //                    } else {
    //                        print("could not unwrap json value")
    //                        self.averageRating = 0
    //                        self.delegate?.averageRatingUpdated()
    //                    }
    //                } else {
    //                    print("could not unwrap response")
    //
    //                }
    //        }
    //    }


}
