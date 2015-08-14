//
//  TimelogCell.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/12/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class TimelogCell: UITableViewCell {
    
    @IBOutlet weak var jobColorView: JobColorView!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var time: UILabel!
    
    var job: Job! {
        didSet {
            jobColorView.color = job.color.getColor
        }
    }
    
    var timelog: Timelog! {
        didSet {
            type.text = timelog.type
            time.text = NSDateFormatter.localizedStringFromDate( (timelog.time) , dateStyle: .MediumStyle, timeStyle: .MediumStyle)
            jobColorView.color = timelog.workedShift.job.color.getColor
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
