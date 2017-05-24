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
    
    //GET all trucks (using Alamofire)
//    func getAllFoodTrucks() {
//        let url = GET_ALL_FT_URL
//        
//        Alamofire.request(url, method: .get)
//            .validate(statusCode: 200..<300)
//            .responseData { (response:DataResponse<Data>) in
//                
//                guard response.result.error == nil else {
//                    print("Alamofire get error: \(response.result.error?.localizedDescription)")
//                    return
//                }
//                
//                guard let data = response.data, let statusCode = response.response?.statusCode else {
//                    print("An error occured obtaining data")
//                    return
//                }
//                
//                print("Alamofire request succeeded: \(statusCode)")
//                self.foodTrucks = FoodTruck.parseFoodTruckJSONData(data: data)
//                self.delegate?.trucksLoaded()
//        }
//    }
    

//    GET all trucks (NSURLSessions)
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
    
    //GET all reviews for a specific food truck
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
    
    //GET all reviews for a specific food truck
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
    
}
