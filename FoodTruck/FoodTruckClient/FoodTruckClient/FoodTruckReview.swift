//
//  FoodTruckReview.swift
//  FoodTruckClient
//
//  Created by Tim Beals on 2017-05-22.
//  Copyright © 2017 Tim Beals. All rights reserved.
//

import Foundation
import SwiftyJSON

struct FoodTruckReview {
    
    var docId: String = ""
    var truckId: String = ""
    var reviewTitle: String = ""
    var reviewText: String = ""
    var starRating: Int = 0
    
    static func parseReviewsJSON(data: Data) -> [FoodTruckReview] {
        
        var foodTruckReviews = [FoodTruckReview]()
        
        //This is the serialization method declared in Foundation as opposed to Swifty JSON (which we used in the FoodTruck Model).
        do {
            let reviews = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            
            if let reviews = reviews as? [Dictionary<String, AnyObject>] {
                
                for review in reviews {
                    
                    var newReview = FoodTruckReview()
                    
                    newReview.docId = review["id"] as! String
                    newReview.truckId = review["truckid"] as! String
                    newReview.reviewTitle = review["reviewtitle"] as! String
                    newReview.reviewText = review["reviewtext"] as! String
                    newReview.starRating = review["starrating"] as! Int
                    
                    foodTruckReviews.append(newReview)
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
        
        
        return foodTruckReviews
    }
}
