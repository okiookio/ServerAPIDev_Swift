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
    
    init() throws{
        
        router = Router()
        
        router.get("/", handler: getMain)
    }

    public func getMain(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        
        Log.debug("GET / router handler...")
        
        var json = JSON([:])
        
        json["udemy-course"].stringValue = "learning swift API development with Kitura & bluemix"
        
        json["name"].stringValue = "AceGod"
        
        json["company"].stringValue = "SmartVault"
        
        try response.status(.OK).send(json:json).end()
        
    }
    
}
