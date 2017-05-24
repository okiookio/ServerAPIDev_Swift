//
//  Constants.swift
//  FoodTruckClient
//
//  Created by Tim Beals on 2017-05-22.
//  Copyright © 2017 Tim Beals. All rights reserved.
//

import Foundation

//Callbacks
//type alias for callbacks used in data service
typealias callback = (_ success: Bool) -> ()

//base url
let BASE_API_URL = "http://localhost:8080/api/v1"
//let BASE_API_URL = "https://foodtruck-api.mybluemix.net/api/v1"


//GET all foodtrucks url
let GET_ALL_FT_URL = "\(BASE_API_URL)/trucks"

//GET all reviews for a specific truck
let GET_FT_REVIEWS_URL = "\(BASE_API_URL)/trucks/reviews"

//GET average star rating for a specific foodtruck
let GET_FT_STAR_URL = "\(BASE_API_URL)/reviews/rating"

//POST food truck
let POST_FT_URL = "\(BASE_API_URL)/trucks"

//POST review to specific truck
let POST_REVIEW_URL = "\(BASE_API_URL)/reviews"
