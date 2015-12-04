//
//  JobOverviewViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/16/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class JobOverviewViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var payLabel: UILabel!
    
    var editButton: UIBarButtonItem!
    var jobs = [Job]()
    var job: Job!
    var timelog: Timelog!
    var workedshift: WorkedShift!
    var allWorkedShifts = [WorkedShift]()
    var selectedDate: NSDate!
    var monthSchedule: [ScheduledShift]!
    var daySchedule: [ScheduledShift]!
    var shift: ScheduledShift!
    var shouldShowDaysOut = true
    var animationFinished = true
    var currentMonth = CVDate(date: NSDate()).currentMonth
    var dataManager = DataManager()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        editButton = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "editJob")
        self.navigationItem.rightBarButtonItem = editButton
            
        self.title = "Job Overview"
    }
    
    override func viewWillAppear(animated: Bool) {
        let unitedStatesLocale = NSLocale(localeIdentifier: "en_US")
        let pay = job.payRate
        var numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        numberFormatter.locale = unitedStatesLocale
        
        nameLabel.text = job.company
        positionLabel.text = job.position
        payLabel.text = "\(numberFormatter.stringFromNumber(pay)!)/hr"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    
    func editJob() {
        self.performSegueWithIdentifier("editJob", sender: self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editJob" {
            let destinationVC = segue.destinationViewController as! AddJobTableViewController
            destinationVC.navigationItem.title = "Edit Job"
//            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: nil, action: nil)
            destinationVC.hidesBottomBarWhenPushed = true
            destinationVC.job = self.job
        }
        
        if segue.identifier == "showTimesheet" {
            let destinationVC = segue.destinationViewController as! TimesheetTableViewController
            
            destinationVC.hidesBottomBarWhenPushed = true
            destinationVC.selectedJob = self.job
        }
    }
    
}