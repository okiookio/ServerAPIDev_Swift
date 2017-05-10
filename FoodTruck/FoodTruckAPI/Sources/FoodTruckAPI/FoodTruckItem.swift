//
//  FoodTruckItem.swift
//  FoodTruckAPI
//
//  Created by Tim Beals on 2017-05-10.
//
//

import Foundation


typealias JSONDictionary = [String: Any]

protocol DictionaryConvertible {
    func toDict() -> JSONDictionary
}

public struct FoodTruckItem {
    
    //ID
    public let docId: String
    
    //Name of the foodtruck business
    public let name: String
    
    //Food type
    public let foodType: String
    
    //average cost of food
    public let avgCost: Float
    
    //coordinates
    public let latitude: Float
    public let longitude: Float
    
}

//Equatable is a protocol that means that you are creating a type that can  be measured for equality. Here we are overwriting the binary operator == so that when we put a foodtruckitem on either side, we can test all of their parameters against each other with a single operation.

extension FoodTruckItem: Equatable {
    public static func == (lhs: FoodTruckItem, rhs: FoodTruckItem) -> Bool {
        return lhs.docId == rhs.docId &&
        lhs.name == rhs.name &&
        lhs.foodType == rhs.foodType &&
        lhs.avgCost == rhs.avgCost &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
    }
}

//note that all of the keys use lowercase. This is the convention for databases.
extension FoodTruckItem: DictionaryConvertible {
    
    internal func toDict() -> JSONDictionary {
        var result = JSONDictionary()
        result["docId"] = self.docId
        result["name"] = self.name
        result["foodtype"] = self.foodType
        result["avgcost"] = self.avgCost
        result["latitude"] = self.latitude
        result["longitude"] = self.longitude
        return result
    }
}

//If we have an array where the elements conform to our DictionaryConvertible protocol, we can use the same method but perform the toDic for every element of the array.

extension Array where Element: DictionaryConvertible {
    func toDict() -> [JSONDictionary] {
        return self.map { $0.toDict()}
    }
}
