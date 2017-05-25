//
//  AddReviewsVC.swift
//  FoodTruckClient
//
//  Created by Tim Beals on 2017-05-24.
//  Copyright © 2017 Tim Beals. All rights reserved.
//

import UIKit

class AddReviewsVC: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var reviewTitleTF: UITextField!
    @IBOutlet weak var reviewTextView: UITextView!
    @IBOutlet weak var starRatingLabel: UILabel!
    @IBOutlet weak var starRatingStepper: UIStepper!
    
    var selectedFoodTruck: FoodTruck?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let truck = selectedFoodTruck {
            headerLabel.text = truck.name
            starRatingLabel.text = "Star Rating: \(starRatingStepper.value)"
            
        } else {
            dismissViewController()
        }
        
        
    }

    func showAlert(with title: String, message: String) {
     
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func addReviewButtonTapped(_ sender: UIButton) {
    
    }
    
    
    @IBAction func stepperValueDidChange(_ sender: UIStepper) {
        let newValue = Int(sender.value)
        starRatingLabel.text = "Star Rating: \(newValue)"
        
    }
    
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismissViewController()
    }
    
    
    
    @IBAction func backButtonTouched(_ sender: Any) {
        dismissViewController()
    }
    
    func dismissViewController() {
        OperationQueue.main.addOperation {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
}
