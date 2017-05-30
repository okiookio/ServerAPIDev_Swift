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
        performSegue(withIdentifier: "showReviewsVC", sender: self)
    }
    
    
    @IBAction func addReviewsButtonTouched(_ sender: UIButton) {
        performSegue(withIdentifier: "showAddReviewsVC", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showReviewsVC" {
            let destination = segue.destination as! ReviewsVC
            destination.selectedFoodTruck = self.selectedFoodTruck
        } else if segue.identifier == "showAddReviewsVC" {
            let destination = segue.destination as! AddReviewsVC
            destination.selectedFoodTruck = self.selectedFoodTruck
        }
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
        DispatchQueue.main.async {
            let rating = self.dataService.averageRating
            self.avgRatingLabel.text = "\(rating)"
        }
    }
    
    
}

