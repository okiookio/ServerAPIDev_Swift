 import XCTest
@testable import FoodTruckAPI

class FoodTruckAPITests: XCTestCase {
    
    //test in Linux
    //docker run --name couch2 -p 5984:5984 -e COUCHDB_USER=TIM COUCHDB_PASSWORD=1234567 klaemo/couchdb:2.0.0

    static var allTests : [(String, (FoodTruckAPITests) -> () throws -> Void)] {
        return [
            ("testAddTruck", testAddAndGetTruck),
            ("testUpdateTruck", testUpdateTruck),
            ("testClearAll", testClearAll),
            ("testDeleteTruck", testDeleteTruck),
            ("testGetTruckCount", testGetTruckCount),
            ("testGetReviewsForTruck", testGetReviewsForTruck),
            ("testGetReviewById", testGetReviewById),
            ("testUpdateReview", testUpdateReview),
            ("testDeleteReview", testDeleteReview),
            ("testCountAllReviews", testCountAllReviews),
//            ("testCountReviewsForTruck", testCountReviewsForTruck),
            //("testGetAverageStarRating", testGetAverageStarRating),
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

    
    //MARK: Foodtruck tests
    
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
        waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error, "Add Truck timed out")
        }
    }
    
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
    
    func testClearAll() {
        
        guard let foodTruckDB = foodTruckDB else {
            XCTFail()
            return
        }
        
        let clearExpectation = expectation(description: "clear all db documents")
        
        foodTruckDB.addFoodTruck(name: "test value", foodType: "test value", avgCost: 0, latitude: 0, longitude: 0) { (foodTruck:FoodTruckItem?, error:Error?) in
            guard error == nil else {
                XCTFail()
                return
            }
            
            foodTruckDB.clearAll { (error:Error?) in
                guard error == nil else {
                    XCTFail()
                    return
                }
                
                foodTruckDB.getTruckCount { (truckCount:Int?, error:Error?) in
                    guard error == nil else {
                        XCTFail()
                        return
                    }
                    XCTAssertEqual(truckCount, 0)
                    
                    foodTruckDB.getAllReviewsCount(completion: { (reviewCount:Int?, error:Error?) in
                        
                        guard error == nil else {
                            XCTFail()
                            return
                        }

                        XCTAssertEqual(reviewCount, 0)
                        clearExpectation.fulfill()
                    })
                }
            }
        }
        waitForExpectations(timeout: 5) { (error:Error?) in
            XCTAssertNil(error, "clear all timed out")
        }
    }
    
    func testDeleteTruck() {
        
        guard let foodTruckDB = foodTruckDB else {
            XCTFail()
            return
        }

        let deleteExpectation = expectation(description: "delete a specific truck")
        
        //first add a truck
        foodTruckDB.addFoodTruck(name: "test delete", foodType: "test delete", avgCost: 0, latitude: 0, longitude: 0) { (addedTruck:FoodTruckItem?, error:Error?) in
            
            guard error == nil else {
                XCTFail()
                return
            }
            
            if let addedTruck = addedTruck {
                
                //now add a review to the truck
                foodTruckDB.addReview(truckId: addedTruck.docId, reviewTitle: "test title", reviewText: "test text", reviewStarRating: 4, completion: { (review:ReviewItem?, error:Error?) in
                    
                    guard error == nil else {
                        XCTFail()
                        return
                    }
                    
                    //now delete the truck (and associated review)
                    foodTruckDB.deleteTruck(docId: addedTruck.docId, completion: { (error:Error?) in
                        
                        guard error == nil else {
                            XCTFail()
                            return
                        }
                        
                        //count trucks and assert zero
                        foodTruckDB.getTruckCount(completion: { (truckCount:Int?, error:Error?) in
                            
                            guard error == nil else {
                                XCTFail()
                                return
                            }
                            
                            XCTAssertEqual(truckCount, 0)
                            
                            //count reviews and assert 0
                            foodTruckDB.getAllReviewsCount(completion: { (reviewCount:Int?, error:Error?) in
                                
                                guard error == nil else {
                                    XCTFail()
                                    return
                                }
                            
                                XCTAssertEqual(reviewCount, 0)
                                deleteExpectation.fulfill()
                            })
                        })
                    })
                })
            }
        }
        waitForExpectations(timeout: 5) { (error:Error?) in
            XCTAssertNil(error, "test delete timed out")
        }
    }

    func testGetTruckCount() {
        guard let foodTruckDB = foodTruckDB else {
            XCTFail()
            return
        }

        
        let countExpectation = expectation(description: "Truck count expectation")
    
        for _ in 0..<5 {
            foodTruckDB.addFoodTruck(name: "test value", foodType: "test value", avgCost: 0, latitude: 0, longitude: 0, completion: { (truck, err) in
                guard err == nil else {
                    XCTFail()
                    return
                }
            })
        }
        
        foodTruckDB.getTruckCount { (count:Int?, error:Error?) in
            guard error == nil else {
                XCTFail()
                return
            }
            //count should be equal to five
            XCTAssertEqual(count, 5)
            countExpectation.fulfill()
        }
        waitForExpectations(timeout: 5) { (error:Error?) in
            XCTAssertNil(error, "Get truck count timed out")
        }
    }
    
    //MARK: Review tests

    func testGetReviewsForTruck() {
        
        guard let foodTruckDB = foodTruckDB else {
            XCTFail()
            return
        }
        
        let getReviewsExpectation = expectation(description: "get all reviews for foodtruck")
        
        //add foodtruck
        foodTruckDB.addFoodTruck(name: "test value", foodType: "test value", avgCost: 0, latitude: 0, longitude: 0) { (addedFoodTruck:FoodTruckItem?, error:Error?) in
            
            guard error == nil else {
                XCTFail()
                return
            }
            
            if let addedFoodTruck = addedFoodTruck {
                
                //add review to truck
                foodTruckDB.addReview(truckId: addedFoodTruck.docId, reviewTitle: "test review", reviewText: "test review", reviewStarRating: 3, completion: { (addedReview:ReviewItem?, error:Error?) in
                    
                    guard error == nil else {
                        XCTFail()
                        return
                    }
                    
                    if let addedReviewOne = addedReview {
                        
                        //add a second review
                        foodTruckDB.addReview(truckId: addedFoodTruck.docId, reviewTitle: "another test review", reviewText: "another test review", reviewStarRating: 2, completion: { (anotherAddedReview: ReviewItem?, error:Error?) in
                            
                            guard error == nil else {
                                XCTFail()
                                return
                            }
                            
                            if let addedReviewTwo = anotherAddedReview {
                                
                                //get all reviews for the truck
                                foodTruckDB.getReviews(truckId: addedFoodTruck.docId, completion: { (reviews:[ReviewItem]?, error: Error?) in
                                    
                                    guard error == nil else {
                                        XCTFail()
                                        return
                                    }
                                    
                                    //test that the count is correct and the returned reviews are the same as the ones you sent
                                    if let reviews = reviews {
                                        
                                        XCTAssertEqual(reviews.count, 2)
                                        XCTAssertEqual(reviews[0].truckId, addedReviewOne.truckId)
                                        XCTAssertEqual(reviews[1].truckId, addedReviewTwo.truckId)
                                        getReviewsExpectation.fulfill()
                                    }
                                })
                            }
                        })
                    }
                })
            }
        }
        self.waitForExpectations(timeout: 5) { (error:Error?) in
            XCTAssertNil(error, "get reviews for truck timed out")
        }
    }
    
    func testGetReviewById() {
        
        guard let foodTruckDB = foodTruckDB else {
            XCTFail()
            return
        }
        
        let getReviewExpectation = expectation(description: "get review by id")
        
        //create a truck
        foodTruckDB.addFoodTruck(name: "test name", foodType: "test type", avgCost: 3, latitude: 0, longitude: 0) { (foodTruck:FoodTruckItem?, error:Error?) in
            
            guard error == nil else {
                XCTFail()
                return
            }

            //pull out truck id
            if let addedTruck = foodTruck {
                
                //create review for truck id
                foodTruckDB.addReview(truckId: addedTruck.docId, reviewTitle: "test title", reviewText: "test text", reviewStarRating: 3, completion: { (review:ReviewItem?, error: Error?) in
                    
                    guard error == nil else {
                        XCTFail()
                        return
                    }
                    
                    //pull out added review
                    if let addedReview = review {
                        
                        //get review by id
                        foodTruckDB.getReviewById(docId: addedReview.docId, completion: { (review:ReviewItem?, error:Error?) in
                            
                            guard error == nil else {
                                XCTFail()
                                return
                            }
                            if let retrievedReview = review {
                                
                                //test equal added review and retrieved review
                                XCTAssertEqual(addedReview, retrievedReview)
                                getReviewExpectation.fulfill()
                            }
                        })
                    } else {
                        XCTFail()
                        return
                    }
                })
            } else {
                XCTFail()
                return
            }
        }
        waitForExpectations(timeout: 5, handler: { (error:Error?) in
            XCTAssertNil(error, "test get review by id timed out")
        })
    }

    func testUpdateReview() {
        
        guard let foodTruckDB = foodTruckDB else {
            XCTFail()
            return
        }
        
        let updateReviewExpectation = expectation(description: "update review")
        
        //create a Foodtruck
        foodTruckDB.addFoodTruck(name: "test name", foodType: "test food type", avgCost: 3, latitude: 0, longitude: 0) { (foodtruck:FoodTruckItem?, error:Error?) in
            
            guard error == nil else {
                XCTFail()
                return
            }

            if let addedFoodTruck = foodtruck {
                
                //create a review for the foodtruck
                foodTruckDB.addReview(truckId: addedFoodTruck.docId, reviewTitle: "test title", reviewText: "test text", reviewStarRating: 4, completion: { (addedReview:ReviewItem?, error:Error?) in
                    
                    guard error == nil else {
                        XCTFail()
                        return
                    }
                    
                    //get review (byid or truck?)
                    if let addedReview = addedReview {
                        
                        foodTruckDB.getReviewById(docId: addedReview.docId, completion: { (retrievedReview:ReviewItem?, error:Error?) in
                            guard error == nil else {
                                XCTFail()
                                return
                            }
                            
                            if retrievedReview != nil {
                                
                                foodTruckDB.updateReview(docId: addedReview.docId, truckId: nil, reviewTitle: "retrieved review title", reviewText: nil, reviewStarRating: nil, completion: { (updatedReview:ReviewItem?, error:Error?) in
                                    
                                    guard error == nil else {
                                        XCTFail()
                                        return
                                    }
                                    
                                    if let updatedReview = updatedReview {
                                        
                                        XCTAssertEqual(addedReview.docId, updatedReview.docId)
                                        XCTAssertEqual(addedReview.reviewTitle, "test title")
                                        XCTAssertEqual(updatedReview.reviewTitle, "retrieved review title")
                                        updateReviewExpectation.fulfill()

                                    } else {
                                        XCTFail()
                                        return
                                    }
                                })
                            } else {
                                XCTFail()
                                return
                            }
                        })
                    } else {
                        XCTFail()
                        return
                    }
                })
            } else {
                XCTFail()
                return
            }
        }
        waitForExpectations(timeout: 5) { (error:Error?) in
            XCTAssertNil(error, "test update review timed out")
        }
    }

    
    func testDeleteReview() {
        
        guard let foodTruckDB = foodTruckDB else {
            XCTFail()
            return
        }
        
        let deleteExpectation = expectation(description: "delete review expectation")
        
        //create foodtruck
        foodTruckDB.addFoodTruck(name: "test name", foodType: "test type", avgCost: 6, latitude: 0, longitude: 0) { (foodTruck:FoodTruckItem?, error:Error?) in
            
            guard error == nil else {
                XCTFail()
                return
            }
            
            if let foodTruck = foodTruck {
                //create review
                foodTruckDB.addReview(truckId: foodTruck.docId, reviewTitle: "test title", reviewText: "test text", reviewStarRating: 3, completion: { (review:ReviewItem?, error:Error?) in
                    
                    guard error == nil else {
                        XCTFail()
                        return
                    }
                    
                    if let addedReview = review {
                        //delete the review
                        foodTruckDB.deleteReview(docId: addedReview.docId, completion: { (error:Error?) in
                            
                            guard error == nil else {
                                XCTFail()
                                return
                            }
                            
                            //try to get review you just deleted, assert that is it nil
                            foodTruckDB.getReviewById(docId: addedReview.docId, completion: { (retrievedReview:ReviewItem?, error:Error?) in
                                
                                XCTAssert(error != nil)
                                XCTAssert(retrievedReview == nil)
                                deleteExpectation.fulfill()
                            })
                        })
                    } else {
                        XCTFail()
                        return
                    }
                })
            } else {
                XCTFail()
                return
            }
        }
        waitForExpectations(timeout: 5) { (error: Error?) in
            XCTAssertNil(error, "test delete review timed out")
        }
    }
    
    func testCountAllReviews() {
        
        guard let foodTruckDB = foodTruckDB else {
            XCTFail()
            return
        }

        let countExpectation = expectation(description: "count all reviews expectation")
        
         //make a truck and add a review to it
        foodTruckDB.addFoodTruck(name: "test truck one", foodType: "test type", avgCost: 6, latitude: 0, longitude: 0) { (foodTruckOne:FoodTruckItem?, error:Error?) in
            
            guard error == nil else {
                XCTFail()
                return
            }

            if let foodTruckOne = foodTruckOne {
                
                foodTruckDB.addReview(truckId: foodTruckOne.docId, reviewTitle: "test title 1", reviewText: "test text 1", reviewStarRating: 3, completion: { (reviewOne:ReviewItem?, error:Error?) in
                    
                    guard error == nil else {
                        XCTFail()
                        return
                    }
                    
                    if reviewOne != nil {
                        
                        //make another truck and add a review to it
                        foodTruckDB.addFoodTruck(name: "test truck two", foodType: "test type", avgCost: 4, latitude: 0, longitude: 0, completion: { (foodTruckTwo:FoodTruckItem?, error:Error?) in
                            
                            guard error == nil else {
                                XCTFail()
                                return
                            }

                            if let foodTruckTwo = foodTruckTwo {
                                
                                foodTruckDB.addReview(truckId: foodTruckTwo.docId, reviewTitle: "test title 2", reviewText: "test text 2", reviewStarRating: 4, completion: { (reviewTwo:ReviewItem?, error:Error?) in
                                    
                                    guard error == nil else {
                                        XCTFail()
                                        return
                                    }
                                    
                                    if reviewTwo != nil {
                                        
                                        //get all reviews. Assert that the review count is two
                                        foodTruckDB.getAllReviewsCount(completion: { (count:Int?, error:Error?) in
                                            
                                            guard error == nil else {
                                                XCTFail()
                                                return
                                            }
                                            
                                            if let count = count {
                                                XCTAssertEqual(count, 2)
                                                countExpectation.fulfill()
                                            } else {
                                                XCTFail()
                                                return
                                            }
                                        })
                                    } else {
                                        XCTFail()
                                        return
                                    }
                                })
                            } else {
                                XCTFail()
                                return
                            }
                        })
                    } else {
                        XCTFail()
                        return
                    }
                })
            } else {
                XCTFail()
                return
            }
        }
        waitForExpectations(timeout: 5) { (error:Error?) in
            XCTAssertNil(error, "test count all reviews timed out")
        }
    }
    
    func testCountReviewsForTruck {
        
        guard let foodTruckDB = foodTruckDB else {
            XCTFail()
            return
        }
        
        let countReviewsExpectation = expectation(description: "count all reviews")
        
        //make a truck
        foodTruckDB.addFoodTruck(name: "test name", foodType: "test type", avgCost: 6, latitude: 0, longitude: 0) { (foodTruck:FoodTruckItem?, error:Error?) in
            
            guard error == nil else {
                XCTFail()
                return
            }
            
            //make two reviews for the truck
            if let foodTruck = foodTruck {
             
                foodTruckDB.addReview(truckId: foodTruck.docId, reviewTitle: "review one", reviewText: "review one", reviewStarRating: 3, completion: { (reviewOne:ReviewItem?, error:Error?) in
                    
                    guard error == nil else {
                        XCTFail()
                        return
                    }
                    
                    if let reviewOne = reviewOne {
                        
                        foodTruckDB.addReview(truckId: foodTruck.docId, reviewTitle: "review two", reviewText: "review two", reviewStarRating: 3, completion: { (reviewTwo:ReviewItem?, error:Error?) in
                            
                            guard error == nil else {
                                XCTFail()
                                return
                            }
                            
                            if let reviewTwo = reviewTwo {
                                
                                //assert that count for the truck is two
                                foodTruckDB.getReviewsCountForTruck(truckId: foodTruck.docId, completion: { (count:Int?, error:Error?) in
                                    
                                    guard error == nil else {
                                        XCTFail()
                                        return
                                    }
                                    
                                    if let count = count {
                                        
                                        XCTAssertEqual(count, 2)
                                        countReviewsExpectation.fulfill()
                                        
                                    } else {
                                        XCTFail()
                                        return
                                    }
                                })
                                
                            } else {
                                XCTFail()
                                return
                            }
                        })
                    } else {
                        XCTFail()
                        return
                    }
                })
            } else {
                XCTFail()
                return
            }
        }
        waitForExpectations(timeout: 5) { (error:Error?) in
            XCTAssertNil(error, "count reviews for truck timed out")
        }
    }
    
    //("testGetAverageStarRating", testGetAverageStarRating),
}
