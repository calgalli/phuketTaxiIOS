//
//  customTableViewCell.swift
//  phuketTaxiM
//
//  Created by cake on 4/26/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit

class customTableViewCell: UITableViewCell {

    @IBOutlet weak var counter: UILabel!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var carType: UILabel!
    @IBOutlet weak var driverRegistrationNumber: UILabel!
    @IBOutlet weak var driverImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}


