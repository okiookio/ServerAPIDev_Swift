//
//  Config.swift
//  FoodTruckAPI
//
//  Created by Tim Beals on 2017-05-09.
//
//

import Foundation
import LoggerAPI
import CloudFoundryEnv
import Configuration
import CouchDB

struct ConfigError: LocalizedError {
    var errorDescription: String? {
        return "Could not retrieve config info"
    }
}

//If the configuration manager is unable to get the environment services then it throws an error.

//CFENV V 4. LATEST
func getConfig() throws -> Service {
    let config: ConfigurationManager = ConfigurationManager()
    config.load(.environmentVariables)
    
    Log.warning("Attempting to retreive CF Env")
    
    let services = config.getServices()
    let servicePair = services.filter { $0.value.label == "cloudantNoSQLDB" }.first
    guard let service = servicePair?.value else { throw ConfigError() }
    
    return service
}

//DEPRECATED
//func getConfig() throws -> Service {
//    
//    var appEnv: AppEnv?
//    
//    do {
//        Log.warning("Attempting to retrieve CF Env")
//        appEnv = try CloudFoundryEnv.getAppEnv()
//        
//        let services = appEnv!.getServices()
//        let servicePair = services.filter { element in element .value.label == "cloudantNoSQLDB" }.first
//        guard let service = servicePair?.value else {
//            throw ConfigError()
//        }
//        return service
//    }
//}
