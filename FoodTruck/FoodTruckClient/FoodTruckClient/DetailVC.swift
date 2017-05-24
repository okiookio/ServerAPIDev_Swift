//
//  DetailVC.swift
//  FoodTruckClient
//
//  Created by Tim Beals on 2017-05-24.
//  Copyright © 2017 Tim Beals. All rights reserved.
//

import UIKit
import MapKit

class DetailVC: UIViewController {

    
    @IBOutlet weak var foodTruckNameLabel: UILabel!
    @IBOutlet weak var foodTypeLabel: UILabel!
    @IBOutlet weak var avgCostLabel: UILabel!
    @IBOutlet weak var avgRatingLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var selectedFoodTruck: FoodTruck?
    var dataService = DataService.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataService.delegate = self
        
        guard let truck = selectedFoodTruck else {
            _ = navigationController?.popViewController(animated: true)
            return
        }
        
        dataService.getAvgRating(truck)
        
        foodTruckNameLabel.text = truck.name
        foodTypeLabel.text = truck.foodType
        avgCostLabel.text = "$\(truck.avgCost)"
        avgRatingLabel.text = "\(dataService.averageRating)"
        
        mapView.addAnnotation(truck)
        centerMapOnLocation(CLLocation(latitude: truck.latitude, longitude: truck.longitude))
    }

    
    func centerMapOnLocation(_ location: CLLocation) {
        
        //create a region with the center coordinate and then radius in meters
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(selectedFoodTruck!.coordinate, 1000, 1000)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func reviewsButtonTouched(_ sender: UIButton) {
        
    }
    
    
    @IBAction func addReviewsButtonTouched(_ sender: UIButton) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //
    }
    
}

extension DetailVC: DataServiceDelegate {
    
    func trucksLoaded() {
        //not needed
    }
    
    func reviewsLoaded() {
        //not needed
    }
    
    func averageRatingUpdated() {
        OperationQueue.main.addOperation {
            let rating = self.dataService.averageRating
            self.avgRatingLabel.text = "\(rating)"
        }
    }
    
    
}

