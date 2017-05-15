import XCTest
@testable import FoodTruckAPI

class FoodTruckAPITests: XCTestCase {

    static var allTests : [(String, (FoodTruckAPITests) -> () throws -> Void)] {
        return [
            ("testAddTruck", testAddAndGetTruck),
            
        ]
    }
    
    var foodTruckDB: FoodTruckDB?
    
    override func setUp() {
        
        foodTruckDB = FoodTruckDB()
        super.setUp()
        
    }
    
    //Add and get specific truck
    //Note that we are using the expectation because we are doing networking calls. The waitForExpectation call is saying that the system will wait three seconds for the requests to complete and execute the .fulfill command. If it is not called within this timeframe the assertNil is called which fails the test.

    func testAddAndGetTruck() {
        
        guard let foodTruckDB = foodTruckDB else {
            XCTFail()
            return
        }
        
        let addExpectation = expectation(description: "Add truck item")
        
        //add new truck
        foodTruckDB.addFoodTruck(name: "test add", foodType: "Test food type", avgCost: 10, latitude: 10, longitude: 10) { (addedTruck:FoodTruckItem?, error:Error?) in
            guard error == nil else {
                XCTFail()
                return
            }
            
            if let addedTruck = addedTruck {

                //XCTAssertEqual(addedTruck.name, "test add")
                //addExpectation.fulfill()
                
                foodTruckDB.getTruck(docId: addedTruck.docId, completion: { (returnedTruck:FoodTruckItem?, error:Error?) in
                    
                    //assert that the added truck and returned truck are the same. Note that this uses the equatable extension method defined in FoodTruckItem
                    
                    XCTAssertEqual(addedTruck, returnedTruck)
                    addExpectation.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error, "Add Truck timed out")
        }
    }
    
    
    //docker run --name couch2 -p 5984:5984 -e COUCHDB_USER=TIM COUCHDB_PASSWORD=1234567 klaemo/couchdb:2.0.0
    
    
    
    
}
