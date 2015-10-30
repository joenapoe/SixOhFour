//
//  AddShiftViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/22/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class AddShiftViewController: UIViewController {
    
    @IBOutlet var addBreakButton: UIButton!
    @IBOutlet var worktimeLabel: UILabel!
    @IBOutlet var timelogTable: UITableView!
    @IBOutlet var earnedLabel: UILabel!
    
    var shift : WorkedShift!
    var timelogs : [Timelog]!
    var selectedTimelog : Timelog!
    var previousTimelog : Timelog!
    var nextTimelog : Timelog!
    var selectedJob : Job!
    var selectedDate: NSDate!
    
    var hasMinDate = false
    var hasMaxDate = false
    var isJobListEmpty = true
    var isNewShift = false
    var breakCount = 0
    let dataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Add Shift"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "saveWorkedShift")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelWorkedShift")
        
        timelogTable.sectionHeaderHeight = 1.0
        timelogTable.sectionFooterHeight = 1.0
        
        if shift != nil {
            selectedJob = shift.job
            
            let timelogArray = shift.timelogs.allObjects as NSArray
            timelogs = timelogArray as! [Timelog]
            
        } else {
            shift = dataManager.addItem("WorkedShift") as! WorkedShift
            shift.setValue(3, forKey: "status")
            shift.job = selectedJob
        
            timelogs = []
            createTimelog("Clocked In")
            createTimelog("Clocked Out")
        }
        
        worktimeLabel.text = "\(shift.hoursWorked()) hours worked"
        earnedLabel.text = "You earned $\(shift.moneyShiftOTx2()) for this shift"
    }
    
    override func viewDidAppear(animated: Bool) {
        selectedJob.color.getColor
        shift.sumUpDuration()
        timelogTable.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
     // MARK: IBActions
    
    @IBAction func addBreakPressed(sender: AnyObject) {
        breakCount++
        
        if breakCount == 1 {
            insertTimelog("Ended Break")
            insertTimelog("Started Break")
        } else if breakCount > 1 {
            for i in 2...breakCount{
                insertTimelog("Ended Break #\(breakCount)")
                insertTimelog("Started Break #\(breakCount)")
            }
        }
        
        var indexPathScroll = NSIndexPath(forRow: 0, inSection: 3)
        self.timelogTable.scrollToRowAtIndexPath(indexPathScroll, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        timelogTable.reloadData()
    }
    
    @IBAction func unwindFromJobsListTableViewControllerToDetails (segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! JobsListTableViewController
        selectedJob = sourceVC.selectedJob
        shift.job = selectedJob
        earnedLabel.text = "You earned $\(shift.moneyShiftOTx2()) for this shift"
    }
    
    @IBAction func unwindSaveDetailsTVC (segue: UIStoryboardSegue) {
        //by hitting the SAVE button
        let sourceVC = segue.sourceViewController as! DetailsTableViewController
        selectedTimelog = sourceVC.selectedTimelog
        
        shift.hoursWorked()
        worktimeLabel.text = "Work time = \(shift.hoursWorked()) hrs"
        earnedLabel.text = "You earned $\(shift.moneyShiftOTx2()) for this shift"
        selectedJob = sourceVC.selectedJob
        timelogTable.reloadData()
    }
    
    @IBAction func unwindCancelDetailsTVC (segue: UIStoryboardSegue) {
        //by hitting the CANCEL button
        //Nothing saved!
    }
    
    
    // MARK: Class functions
    
    func saveWorkedShift() {
        shift.startTime = timelogs.first!.time
        shift.startDateString = NSDateFormatter.localizedStringFromDate(shift.startTime, dateStyle: .LongStyle, timeStyle: .NoStyle)
  
        dataManager.save()
        self.performSegueWithIdentifier("unwindAfterSaveShift", sender: self)
    }
    
    func cancelWorkedShift() {
        if isNewShift {
            dataManager.delete(shift)
        }
        
        self.performSegueWithIdentifier("unwindAfterCancel", sender: self)
    }
    
    func createTimelog(type: String){
        let newTimelog = dataManager.addItem("Timelog") as! Timelog
        newTimelog.workedShift = shift
        newTimelog.comment = ""
        newTimelog.type = type
        newTimelog.time = selectedDate
        timelogs.append(newTimelog)
    }
    
    func insertTimelog(type: String){
        let newTimelog = dataManager.addItem("Timelog") as! Timelog
        newTimelog.workedShift = shift
        newTimelog.comment = ""
        newTimelog.type = type
        newTimelog.time = timelogs[breakCount*2-1].time
        timelogs.insert(newTimelog, atIndex: (breakCount*2-1))
    }
}

extension AddShiftViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("JobsListCell", forIndexPath: indexPath) as! JobsListCell
            
            cell.job = selectedJob
            cell.jobColorView.setNeedsDisplay()
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("TimelogCell", forIndexPath: indexPath) as! TimelogCell
            
            //TODO: Change the TLs so that NSDATE is not choosen for new entries
            if indexPath.section == 1 {
                cell.timelog = timelogs.first
            } else if indexPath.section == 3 {
                cell.timelog = timelogs.last
            } else {
                cell.timelog = timelogs[indexPath.row+1]
            }
            
            cell.job = selectedJob
            cell.jobColorView.setNeedsDisplay()
            
            return cell
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return (breakCount*2)
        } else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 45
        } else {
            return 30
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            let addJobStoryboard: UIStoryboard = UIStoryboard(name: "CalendarStoryboard", bundle: nil)
            let jobsListVC: JobsListTableViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("JobsListTableViewController")
                as! JobsListTableViewController
            jobsListVC.source = "details"
            jobsListVC.previousSelection = selectedJob
            
            self.navigationController?.pushViewController(jobsListVC, animated: true)
        } else {
            if indexPath.section == 1 {
                hasMinDate = false // user select CLOCKIN so noMinDate
                selectedTimelog = timelogs.first
            } else {
                hasMinDate = true
                
                if indexPath.section == 3 {
                    selectedTimelog = timelogs.last
                    self.previousTimelog = timelogs[timelogs.count-2]
                } else {
                    selectedTimelog = timelogs[indexPath.row+1]
                    self.previousTimelog = timelogs[indexPath.row]
                }
            }
            if indexPath.section == 3 {
                selectedTimelog = timelogs.last
                hasMaxDate = false //user select last TIMELOG so noMaxData is sent, and will use NSDATE instead
            } else {
                hasMaxDate = true
                
                if indexPath.section == 1 {
                    selectedTimelog = timelogs.first
                    self.nextTimelog = timelogs[1]
                } else {
                    selectedTimelog = timelogs[indexPath.row+1]
                    self.nextTimelog = timelogs[indexPath.row+2]
                }
            }
            
            let clockInStoryboard: UIStoryboard = UIStoryboard(name: "ClockInStoryboard", bundle: nil)
            let destinationVC: DetailsTableViewController = clockInStoryboard.instantiateViewControllerWithIdentifier("DetailsTableViewController")
                as! DetailsTableViewController
            
            destinationVC.hidesBottomBarWhenPushed = true;
            destinationVC.selectedTimelog = self.selectedTimelog
            destinationVC.previousTimelog = self.previousTimelog
            destinationVC.nextTimelog = self.nextTimelog
            destinationVC.hasMinDate = self.hasMinDate
            destinationVC.hasMaxDate = self.hasMaxDate
            destinationVC.selectedJob = self.selectedJob
            
            self.navigationController?.pushViewController(destinationVC, animated: true)
            
        }
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel.textColor = UIColor.blackColor()
        header.textLabel.frame = header.frame
        header.textLabel.textAlignment = NSTextAlignment.Justified
        if section == 0 {
            header.textLabel.text = "Job"
        } else if section == 1 {
            header.textLabel.text = "Entries"
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Job"
        } else if section == 1 {
            return "Entries"
        } else {
            return nil
        }
    }
}