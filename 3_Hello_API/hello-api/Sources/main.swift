import Kitura
import LoggerAPI
import HeliumLogger
import Foundation


do {
    HeliumLogger.use(LoggerMessageType.info)
    let controller = try Controller()
    Log.info("Server will be started on '\(controller.url)'.")
    
    Kitura.addHTTPServer(onPort: controller.port, with: controller.router)
    Kitura.run()
} catch let error {
    Log.error(error.localizedDescription)
    Log.error("Server did not start")
}
