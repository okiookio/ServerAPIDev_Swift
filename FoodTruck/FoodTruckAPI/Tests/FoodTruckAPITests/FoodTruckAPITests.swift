import XCTest
@testable import FoodTruckAPI

class FoodTruckAPITests: XCTestCase {

    static var allTests : [(String, (FoodTruckAPITests) -> () throws -> Void)] {
        return [
            ("testAddTruck", testAddAndGetTruck),
            ("testUpdateTruck", testUpdateTruck),
            
        ]
    }
    
    var foodTruckDB: FoodTruckDB?
    
    override func setUp() {
        
        foodTruckDB = FoodTruckDB()
        super.setUp()
        
    }
    
    override func tearDown() {
        guard let foodtruckDB = foodTruckDB else {
            return
        }

        foodtruckDB.clearAll { (error:Error?) in
            guard error == nil else {
                return
            }
        }
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
    
    func testUpdateTruck() {
        
        guard let foodTruckDB = foodTruckDB else {
            XCTFail()
            return
        }
        
        let updateExpectation = expectation(description: "update truck expectation")
        
        //first add a new truck
        foodTruckDB.addFoodTruck(name: "test update", foodType: "test update", avgCost: 0, latitude: 0, longitude: 0) { (addedTruck:FoodTruckItem?, error:Error?) in
            guard error == nil else {
                XCTFail()
                return
            }
            
            if let addedTruck = addedTruck {
                
                let id = addedTruck.docId
                
                //now update the added truck
                foodTruckDB.updateFoodTruck(docId: id, name: "updated name", foodtype: nil, avgcost: 10, latitude: nil, longitude: nil, completion: { (updatedTruck:FoodTruckItem?, error:Error?) in
                    
                    guard error == nil else {
                        XCTFail()
                        return
                    }
                    
                    if let updatedTruck = updatedTruck {
                        
                        //finally fetch the updated truck and check that it is the same
                        foodTruckDB.getTruck(docId: updatedTruck.docId, completion: { (fetchedTruck:FoodTruckItem?, error:Error?) in
                            XCTAssertEqual(updatedTruck, fetchedTruck)
                            updateExpectation.fulfill()
                        })
                    }
                })
            }
        }
        waitForExpectations(timeout: 5) { (error:Error?) in
            XCTAssertNil(error, "Update truck timed out")
        }
    }
    
    
}
