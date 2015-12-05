//
//  TodayScheduleCell.swift
//  SixOhFour
//
//  Created by jemsomniac on 7/2/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class TodayScheduleCell: UITableViewCell {

    @IBOutlet weak var jobColorView: JobColorView!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var primaryLabel: UILabel!
    @IBOutlet weak var secondaryLabel: UILabel!
    
    var schedule: ScheduledShift! {
        didSet {
            jobColorView.color = schedule.job.color.getColor
            
            companyLabel.text = schedule.job.company
            positionLabel.text = schedule.job.position
            
            let formatter = NSDateFormatter()
            formatter.dateStyle = .NoStyle
            formatter.timeStyle = .ShortStyle
            
            primaryLabel.text = "\(formatter.stringFromDate(schedule.startTime)) - \(formatter.stringFromDate(schedule.endTime))"
            
            formatter.dateStyle = .ShortStyle
            formatter.timeStyle = .NoStyle
 
            let start = "\(formatter.stringFromDate(schedule.startTime))"
            let end = "\(formatter.stringFromDate(schedule.endTime))"
            
            
            if start == end {
                secondaryLabel.hidden = true
            } else {
                secondaryLabel.hidden = false
            }
        }
    }
    
    var shift: WorkedShift! {
        didSet {
            jobColorView.color = shift.job.color.getColor
            
            companyLabel.text = shift.job.company
            positionLabel.text = shift.job.position
            
            let formatter = NSDateFormatter()
            formatter.dateStyle = .NoStyle
            formatter.timeStyle = .ShortStyle
            
            primaryLabel.text = "\(shift.hoursWorked()) hours"            
            secondaryLabel.text = "\(formatter.stringFromDate(shift.startTime)) - \(formatter.stringFromDate(shift.endTime))"
        
        }
    }
}
