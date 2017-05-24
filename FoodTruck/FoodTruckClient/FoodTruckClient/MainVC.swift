//
//  MainVC.swift
//  FoodTruckClient
//
//  Created by Tim Beals on 2017-05-24.
//  Copyright © 2017 Tim Beals. All rights reserved.
//

import UIKit

class MainVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    
    var dataService = DataService.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataService.delegate = self
        dataService.getAllFoodTrucks()
        
        tableView.delegate = self
        tableView.dataSource = self
        
    }

    
    @IBAction func addTruckButtonTapped(_ sender: UIButton) {
    
    
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "ShowDetailsVC" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationViewController = segue.destination as! DetailVC
                destinationViewController.selectedFoodTruck = dataService.foodTrucks[indexPath.row]
            }
        }
    }



}

extension MainVC: DataServiceDelegate {
    
    func trucksLoaded() {
        
        OperationQueue.main.addOperation {
            print("trucks loaded")
            self.tableView.reloadData()
        }
    }
    
    func reviewsLoaded() {
        //Do nothing
    }
    
    func averageRatingUpdated() {
        //Do nothing
    }
}

extension MainVC: UITableViewDelegate, UITableViewDataSource {
 
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataService.foodTrucks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "FoodTruckCell", for: indexPath) as? FoodTruckCell {
            cell.configureCell(foodTruck: dataService.foodTrucks[indexPath.row])
            return cell
        } else {
            return UITableViewCell()
        }
    }    
}

