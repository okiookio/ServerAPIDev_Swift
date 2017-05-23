//
//  FoodTruck.swift
//  FoodTruckClient
//
//  Created by Tim Beals on 2017-05-22.
//  Copyright © 2017 Tim Beals. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import SwiftyJSON

//Note that your class needs to inherit from NSObject to be able to work with mapkit

class FoodTruck: NSObject, MKAnnotation {
    
    var docId: String = ""
    var name: String = ""
    var foodType: String = ""
    var avgCost: String = "0"
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    //'objective c decorators' for the annotation
    @objc  var title: String?
    @objc var subtitle: String?
    @objc var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
    
    static func parseFoodTruckJSONData(data: Data) -> [FoodTruck] {
        
        var foodTrucks = [FoodTruck]()
        
        var trucks = JSON(data: data)
        
        //Parse JSON data - the truck info is the value against the docId key. We don't need the key so we are using _
        
        for (_, truck)  in trucks {
            
            let newTruck = FoodTruck()
            
            newTruck.docId = truck["id"].stringValue
            newTruck.name = truck["name"].stringValue
            newTruck.foodType = truck["foodtype"].stringValue
            newTruck.avgCost = String(format: "%.2f", truck["avgcost"].doubleValue)
            newTruck.longitude = truck["longitude"].doubleValue
            newTruck.latitude = truck["latitude"].doubleValue
            
            //set title and subtitle for map annotation
            newTruck.title = newTruck.name
            newTruck.subtitle = newTruck.foodType
            
            foodTrucks.append(newTruck)
        }
        
        return foodTrucks
    }
}


