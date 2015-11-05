//
//  JobsListCell.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/10/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class JobsListCell: UITableViewCell {

    @IBOutlet weak var jobColorView: JobColorView!
    @IBOutlet weak var jobNameLabel: UILabel!
    @IBOutlet weak var jobPositionLabel: UILabel!
    
    var job: Job! {
        didSet {
            jobNameLabel.text = job.company
            jobPositionLabel.text = job.position
            jobColorView.color = job.color.getColor
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
