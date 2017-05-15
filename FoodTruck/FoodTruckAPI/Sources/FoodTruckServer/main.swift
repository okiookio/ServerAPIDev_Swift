import Foundation
import Kitura
import HeliumLogger
import LoggerAPI
import CloudFoundryEnv
import Configuration
import FoodTruckAPI

HeliumLogger.use()

//FoodTruck is the back-end class that implemens the protocol methods for dealing with couchDB
let foodTruckDB: FoodTruckDB

//Initialization will be attempted using CF Environment for bluemix and if that doesn't succeed then we will initialize locally. Notice the two different init methods being called.

do {
    Log.info("Attempting init with CF Environment")
    let service = try getConfig()
    Log.info("Init with service")
    foodTruckDB = FoodTruckDB(service: service)
} catch {
    Log.info("Could not init with CF Environment. Proceed with defaults")
    foodTruckDB = FoodTruckDB()
}

let controller = FoodTruckController(backend: foodTruckDB)

//CloudFoundry gets the app environment from bluemix. However, because it is not connected during development, it will set defaults. For example it will set port to 8080.

//DEPRECATED
//do {
//    let port = try CloudFoundryEnv.getAppEnv().port
//    Log.verbose("Assigned port \(port)")
//
//    Kitura.addHTTPServer(onPort: port, with: controller.router)
//    Kitura.run()
//
//} catch {
//    Log.error("Server failed to start")
//}


let configMgr =  ConfigurationManager().load(.environmentVariables)

if let port = configMgr.getApp()?.port {
    
    Log.verbose("Assigned port \(port)")
    
    Kitura.addHTTPServer(onPort: port, with: controller.router)
    
    Kitura.run()
    
} else {
    
    Log.error("Failed to get environment variables, Server failed to start!")
    exit(EXIT_FAILURE)
}

