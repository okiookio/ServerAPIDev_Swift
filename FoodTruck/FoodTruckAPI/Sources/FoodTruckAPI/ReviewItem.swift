//
//  ReviewItem.swift
//  FoodTruckAPI
//
//  Created by Tim Beals on 2017-05-15.
//
//

import Foundation
import SwiftyJSON
import CouchDB
import LoggerAPI

public struct ReviewItem {
    
    public let docId: String
    public let foodTruckId: String
    public let reviewTitle: String
    public let reviewText: String
    public let starRating: Int
}
