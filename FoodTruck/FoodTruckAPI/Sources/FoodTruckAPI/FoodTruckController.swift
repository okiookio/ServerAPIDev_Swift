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
    
    public let trucks: FoodTruckAPI
    public let router = Router()
    public let trucksPath = "api/v1/trucks"
    
    public init(backend: FoodTruckAPI) {
        self.trucks = backend
        routeSetup()
    }
    
    public func routeSetup() {
        router.all("/*", middleware: BodyParser())
    }
    
    
}
