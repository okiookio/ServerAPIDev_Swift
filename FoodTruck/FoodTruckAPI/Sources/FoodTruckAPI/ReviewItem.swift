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

extension ReviewItem : Equatable {
    public static func == (lhs: ReviewItem, rhs: ReviewItem) -> Bool {
        return lhs.docId == rhs.docId &&
        lhs.foodTruckId == rhs.foodTruckId &&
        lhs.reviewTitle == rhs.reviewTitle &&
        lhs.reviewText == rhs.reviewText &&
        lhs.starRating == rhs.starRating
    }
}

extension ReviewItem: DictionaryConvertible {
    
    internal func toDict() -> JSONDictionary {
        var result = JSONDictionary()
        result["docId"] = self.docId
        result["foodtruckid"] = self.foodTruckId
        result["reviewtitle"] = self.reviewTitle
        result["reviewtext"] = self.reviewText
        result["starrating"] = self.starRating
        return result
    }
}
