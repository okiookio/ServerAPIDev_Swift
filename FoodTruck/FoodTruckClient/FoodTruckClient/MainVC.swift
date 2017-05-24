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
