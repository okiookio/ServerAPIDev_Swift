import Foundation
import Kitura
import HeliumLogger
import LoggerAPI
import CloudFoundryEnv
import FoodTruckAPI

HeliumLogger.use()

let trucks: FoodTruck

//Initialization will be attempted using CF Environment for bluemix and if that doesn't succeed then we will initialize locally. Notice the two different init methods being called.

do {
    Log.info("Attempting init with CF Environment")
    let service = try getConfig()
    Log.info("Init with service")
    trucks = FoodTruck(service: service)
} catch {
    Log.info("Could not init with CF Environment. Proceed with defaults")
    trucks = FoodTruck()
}
