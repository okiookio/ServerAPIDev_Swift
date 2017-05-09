//
//  FoodTruck.swift
//  FoodTruckAPI
//
//  Created by Tim Beals on 2017-05-09.
//
//

import Foundation
import CloudFoundryEnv
import SwiftyJSON
import CouchDB
import LoggerAPI

#if os(Linux)
    typealias Valuetype = Any
#else
    typealias Valuetype = AnyObject
#endif

//our enum conforms to the Error protocol
public enum APICollectionError: Error {
    case ParseError
    case AuthError
}

//If we are unable to get our app config from the CFEnv are going to provide some defaults so that we can run on our local host.
//These properties can then be put into the CouchDB struct ConnectionProperties note that the username and password inputs are optional.
// secured - We are testing if the API is running on the localhost (default) then it is unsecured otherwise it is running on bluemix and is secured.
//The convenience is an extra initializer. The first is the default initializer. Note that in main.swift (if there is no service)we call the default initializer with no input parameters. This means that it is initialized with the default parameters we have entered.

public class FoodTruck: FoodTruckAPI {
    
    static let defaultDBHost = "localhost"
    static let defaultDBPort = Int16(5984)
    static let defaultDBName = "foodtruckapi"
    static let defaultDBUsername = "Tim"
    static let defaultDBPassword = "123456"
    
    let dbName = "foodtruckapi"
    let designName = "foodtruckdesign"
    
    let connectionProps: ConnectionProperties

    //create initializers
    
    public init (database: String = FoodTruck.defaultDBName, host: String = FoodTruck.defaultDBHost, port: Int16 = FoodTruck.defaultDBPort, username: String? = FoodTruck.defaultDBUsername, password: String? = FoodTruck.defaultDBPassword) {
        
        let secured  = (host == FoodTruck.defaultDBHost) ? false : true
        connectionProps = ConnectionProperties(host: host, port: port, secured: secured, username: username, password: password)
        
        setupDB()
    }

    public convenience init (service: Service) {
        let database: String = "foodtruckapi"
        let host: String
        let port: Int16
        let username: String?
        let password: String?
        
        if let credentials = service.credentials, let tempHost = credentials["host"] as? String, let tempUsername = credentials["username"] as? String, let tempPassword = credentials["password"] as? String, let tempPort = credentials["port"] as? Int16 {
            
            host = tempHost
            port = tempPort
            username = tempUsername
            password = tempPassword
            Log.info("Using CF service credentials")
        } else {
            
            host = FoodTruck.defaultDBHost
            port = FoodTruck.defaultDBPort
            username = FoodTruck.defaultDBUsername
            password = FoodTruck.defaultDBPassword
            
            Log.info("Using service development credentials")
        }
        
        //default initializer
        self.init(database: database, host: host, port: port, username: username, password: password)
    }
    
    private func setupDB() {
        
    }
    
    
    
}
