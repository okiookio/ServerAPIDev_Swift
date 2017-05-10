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

//Equatable is a protocol that means that you are creating a type that can  be measured for equality.

extension FoodTruckItem: Equatable {
    
}
