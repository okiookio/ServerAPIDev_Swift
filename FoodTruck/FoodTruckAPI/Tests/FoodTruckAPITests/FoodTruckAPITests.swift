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

                foodTruckDB.getTruck(docId: addedTruck.docId, completion: { (returnedTruck:FoodTruckItem?, error:Error?) in
                    
                    //assert that the added truck and returned truck are the same. Note that this uses the equatable extension method defined in FoodTruckItem
                    
                    XCTAssertEqual(addedTruck, returnedTruck)
                    addExpectation.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 3) { (error) in
            XCTAssertNil(error, "Add Truck timed out")
        }
    }
    
    
    
    
}
