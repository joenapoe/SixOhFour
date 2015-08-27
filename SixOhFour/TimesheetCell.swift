//
//  TimesheetCell.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/30/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class TimesheetCell: UITableViewCell {

    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var hoursLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
    


