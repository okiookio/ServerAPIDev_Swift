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
    func getAllFoodTrucks() {
        let url = GET_ALL_FT_URL
        
        Alamofire.request(url, method: .get)
            .validate(statusCode: 200..<300)
            .responseData { (response:DataResponse<Data>) in
                
                guard response.result.error == nil else {
                    print("Alamofire get error: \(response.result.error?.localizedDescription)")
                    return
                }
                
                guard let data = response.data, let statusCode = response.response?.statusCode else {
                    print("An error occured obtaining data")
                    return
                }
                
                print("Alamofire request succeeded: \(statusCode)")
                self.foodTrucks = FoodTruck.parseFoodTruckJSONData(data: data)
                self.delegate?.trucksLoaded()
        }
    }
    
    
    
}
