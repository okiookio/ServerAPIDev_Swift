//
//  AddFoodTruckVC.swift
//  FoodTruckClient
//
//  Created by Tim Beals on 2017-05-24.
//  Copyright © 2017 Tim Beals. All rights reserved.
//

import UIKit

class AddFoodTruckVC: UIViewController {

    
    @IBOutlet weak var foodTruckNameTF: UITextField!
    @IBOutlet weak var foodTypeTF: UITextField!
    @IBOutlet weak var avgCostTF: UITextField!
    @IBOutlet weak var latitudeTF: UITextField!
    @IBOutlet weak var longitudeTF: UITextField!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    var dataService = DataService.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func showAlert(with title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        spinner.stopAnimating()
    }
    
    
    @IBAction func addFoodTruckButtonTapped(_ sender: UIButton) {
        
        spinner.startAnimating()
        
        guard foodTruckNameTF.text != "", let foodTruckName = foodTruckNameTF.text else {
            showAlert(with: "Error", message: "Please enter name of food truck")
            return
        }
        
        guard foodTypeTF.text != "", let foodType = foodTypeTF.text  else {
            showAlert(with: "Error", message: "Please enter a food type")
            return
        }
        
        guard let averageCost = Double(avgCostTF.text!), avgCostTF.text != "" else {
            showAlert(with: "Error", message: "Please enter average cost as decimal ex. 7.99")
            return
        }
        
        guard let lat = Double(latitudeTF.text!), lat >= -90.0, lat <= 90.0 else {
            showAlert(with: "Error", message: "Please enter a valid latitude between (+/-) 90.0")
            return
        }
        
        guard let long = Double(longitudeTF.text!), long >= -180.0, long <= 180.0 else {
            showAlert(with: "Error", message: "Please enter a valid longitude between (+/-) 180.0")
            return
        }

        dataService.addNewFoodTruck(foodTruckName, foodType: foodType, avgCost: averageCost, latitude: lat, longitude: long) { (success) in
            if success {
                self.dataService.getAllFoodTrucks(completion: { (success) in
                    if success {
                        print("Food truck saved successfully")
                        self.dismissViewController()
                    } else {
                        print("Unknown error occured")
                        self.showAlert(with: "Error", message: "An unknown error occured")
                    }
                })
            } else {
                self.showAlert(with: "Error", message: "An error occured saving food truck")
            }
        }
    }
    
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismissViewController()
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        dismissViewController()
    }
    
    func dismissViewController() {
        DispatchQueue.main.async {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
}
