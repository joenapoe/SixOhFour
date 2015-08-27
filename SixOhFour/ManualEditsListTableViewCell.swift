//
//  ManualEditsListTableViewCell.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/13/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class ManualEditsListTableViewCell: UITableViewCell {

    var dataManager = DataManager()
    
        @IBOutlet weak var companyLabel: UILabel!
        @IBOutlet weak var positionLabel: UILabel!
        @IBOutlet weak var dateLabel: UILabel!
        @IBOutlet weak var timeLabel: UILabel!
        @IBOutlet weak var jobColorView: JobColorView!
        
        
        var workedShift: WorkedShift! {
            didSet {
                companyLabel.text = workedShift.job.company.name
                positionLabel.text = workedShift.job.position
                jobColorView.color = workedShift.job.color.getColor
            }
    }
    

    var clockInTL: Timelog! {
        didSet {
            dateLabel.text = NSDateFormatter.localizedStringFromDate( (clockInTL.time) ,dateStyle: .LongStyle,  timeStyle: .NoStyle)
            timeLabel.text = "Clocked in at \(NSDateFormatter.localizedStringFromDate( (clockInTL.time) ,dateStyle: .NoStyle,  timeStyle: .MediumStyle))"

        }
    }
    
        override func awakeFromNib() {
            super.awakeFromNib()

    }
        
        override func setSelected(selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            
            // Configure the view for the selected state
        }
        
}
