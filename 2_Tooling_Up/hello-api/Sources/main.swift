import Foundation
import Kitura
import HeliumLogger
import SwiftyJSON
import LoggerAPI


//MARK: Get Kitura up and running!

//Disable buffering for HeliumLogger
setbuf(stdout, nil)
Log.logger = HeliumLogger()


//Call a get method on the root URL "/"
//If the status is .OK send the jsonMsg
let router = Router()
router.get("/") { request, response, next in
    let jsonMsg = JSON(["Hello": "Kitura!"])
    response.status(.OK).send(json: jsonMsg)
    next()
}

//start the server
Log.info("starting server")

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()

