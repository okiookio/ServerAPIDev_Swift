//FoodTruckAPI (protocol) outlines the functionality
//FoodTruck (class) handles interfacing with the database
//FoodTruckController (class) handles request code

public protocol FoodTruckAPI {
    
    
    //MARK: Food Truck Methods

    //Get all food trucks
    func getAllTrucks(completion: @escaping([FoodTruckItem]?, Error?) -> Void)
    
    //Get one specific truck
    func getTruck(docId: String, completion: @escaping(FoodTruckItem?, Error?) -> Void)
    
    //Create a food truck
    func addFoodTruck(name: String, foodType: String, avgCost: Float, latitude: Float, longitude: Float, completion: @escaping(FoodTruckItem?, Error?) -> Void)
    
    //Tear down method
    func clearAll(completion: @escaping(Error?) -> Void)
    
    //Delete one specific food truck
    func deleteTruck(docId: String, completion: @escaping(Error?) -> Void)

    //Update specific foodtruck
    func updateFoodTruck(docId: String, name: String?, foodtype: String?, avgcost: Float?, latitude: Float?, longitude: Float?, completion: @escaping(FoodTruckItem?, Error?) -> Void)
    
    //Get count of all foodtrucks
    func getTruckCount(completion: @escaping(Int?, Error?) -> Void)
    
    
    //MARK: Reviews
    //Get all reviews for a specific truck
    func getReviews(truckId: String, completion: @escaping([ReviewItem]?, Error?) -> Void)
    
    //Get a specific review by id
    func getReviewById(docId: String, completion: @escaping(ReviewItem?, Error?) -> Void)
    
    //Add a review for a specific truck
    func addReview(truckId: String, reviewTitle: String, reviewText: String, reviewStarRating: Int, completion: @escaping(ReviewItem?, Error?) -> Void)
    
    //Update a specific review
    func updateReview(docId: String, truckId: String?, reviewTitle: String?, reviewText: String?, reviewStarRating: Int?, completion: @escaping(ReviewItem?, Error?) -> Void)
    
    //Delete specific review
    func deleteReview(docId: String, completion: @escaping(Error?) -> Void)
    
    //count all reviews
    func getAllReviewsCount(completion: @escaping(Int?, Error?) -> Void)
    
    //count all reviews for specific truck
    func getReviewsCountForTruck(truckId: String, completion: @escaping(Int?, Error?) -> Void)
    
    //Avg star rating for a specific truck
    func getAvgRating(truckId: String, completion: @escaping(Int?, Error?) -> Void)
}
