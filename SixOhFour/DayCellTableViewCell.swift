//
//  DayCellTableViewCell.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/27/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class DayCellTableViewCell: UITableViewCell {

    var dataManager = DataManager()
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var jobColorView: JobColorView!
    @IBOutlet weak var durationLabel: UILabel!
    
    var workedShift: WorkedShift! {
        didSet {
            jobColorView.color = workedShift.job.color.getColor
            durationLabel.text = "\(workedShift.hoursWorked()) hrs"
        }
    }
    
    var timelog: Timelog! {
        didSet {
            dateLabel.text = NSDateFormatter.localizedStringFromDate(timelog.time, dateStyle: .LongStyle, timeStyle: .NoStyle)
            timeLabel.text = "Clocked in at \(NSDateFormatter.localizedStringFromDate(timelog.time ,dateStyle: .NoStyle,  timeStyle: .MediumStyle))"
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