//
//  driverModel.swift
//  phuketTaxiM
//
//  Created by cake on 4/26/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import Foundation

class driver {
    var name = ""
    var regisrationNumber = ""
    var rating = ""
    var carType = ""
    var driverImage = ""
    var counter = ""
    
    init(name : String, regisrationNumber: String, rating: String, carType: String, driverImage: String, counter:String){
        self.name = name;
        self.regisrationNumber = regisrationNumber
        self.rating = rating
        self.carType = carType
        self.driverImage = driverImage
        self.counter = counter
    }
    
}
