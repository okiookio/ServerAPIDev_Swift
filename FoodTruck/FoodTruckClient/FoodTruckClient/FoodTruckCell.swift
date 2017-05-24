//
//  FoodTruckCell.swift
//  FoodTruckClient
//
//  Created by Tim Beals on 2017-05-24.
//  Copyright © 2017 Tim Beals. All rights reserved.
//

import UIKit

class FoodTruckCell: UITableViewCell {

    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var foodTypeLabel: UILabel!
    
    @IBOutlet weak var avgCostLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(foodTruck: FoodTruck) {
        
        nameLabel.text = foodTruck.name
        foodTypeLabel.text = foodTruck.foodType
        avgCostLabel.text = "$\(foodTruck.avgCost)"
    }
    
    
    

}
