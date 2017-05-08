//
//  Controller.swift
//  hello-api
//
//  Created by Tim Beals on 2017-05-07.
//
//

import Foundation
import SwiftyJSON
import Kitura
import LoggerAPI
import CloudFoundryEnv
import Configuration

//These are pre-processor directives
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

//CloudFoundryEnv: If you are on a cloud foundry environment (like Bluemix) it will attempt to read the appEnv environment variables found in appEnv. If they are not set, the environment will set defaults


public class Controller {
    
    let router: Router
    let appEnv = ConfigurationManager()
    
    var url: String {
        get {
            return appEnv.url
        }
    }

    var port: Int {
        get {
        return appEnv.port
        }
    }
    
    var vehicles: [Dictionary<String, Any>] = [["make":"Nissan", "model":"Centra", "year":2015],
                                     ["make": "Subaru", "model":"Forester", "year": 2017],
                                     ["make":"Ford", "model": "Focus", "year":2013]]
    
    init() throws{
        
        router = Router()
        
        router.get("/", handler: getMain)
        router.get("/vehicles", handler: getAllVehicles)
        router.get("/vehicles/random", handler: getRandomVehicle)
    }

    public func getMain(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        
        Log.debug("GET / router handler...")
        
        var json = JSON([:])
        
        json["flash"].stringValue = "thunder"
        
        try response.status(.OK).send(json:json).end()
        
    }
    
    public func getAllVehicles(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        
        let json = JSON(vehicles)
        try response.status(.OK).send(json: json).end()
    }
    
    public func getRandomVehicle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        #if os(Linux)
            srandom(UInt32(NSDate().timeIntervalSince1970))
            let index = random() % vehicles.count
        #else
            let index = Int(arc4random_uniform(UInt32(vehicles.count)))
        #endif
        
        let vehicle = vehicles[index]
        let json = JSON(vehicle)
        try response.status(.OK).send(json: json).end()
    }
    
    
    
}
