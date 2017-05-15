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
}
