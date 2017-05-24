//
//  ReviewsVC.swift
//  FoodTruckClient
//
//  Created by Tim Beals on 2017-05-24.
//  Copyright © 2017 Tim Beals. All rights reserved.
//

import UIKit

class ReviewsVC: UIViewController {


    @IBOutlet weak var foodTruckNameLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var selectedFoodTruck: FoodTruck?
    
    var dataService = DataService.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        dataService.delegate = self
        
        if let truck = selectedFoodTruck {
            foodTruckNameLabel.text = truck.name
            dataService.getAllReviews(truck)
        }
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140.0
    }
    
    @IBAction func backButtonTouched(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
}


extension ReviewsVC: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataService.reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "reviewCell", for: indexPath) as? ReviewCell {
            cell.configureCell(review: dataService.reviews[indexPath.row])
            return cell
        } else {
            return UITableViewCell()
        }
    }
}

extension ReviewsVC: DataServiceDelegate {
    
    func trucksLoaded() {
        //
    }
    
    func reviewsLoaded() {
        OperationQueue.main.addOperation {
            print("reviews updated")
            self.tableView.reloadData()
        }
    }
    
    func averageRatingUpdated() {
        //
    }
    
    
}
