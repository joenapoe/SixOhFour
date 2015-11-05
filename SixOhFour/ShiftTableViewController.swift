//
//  ShiftTableViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/13/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class ShiftTableViewController: UITableViewController {
    
    //PASSED IN VARIABLES:
    var selectedWorkedShift : WorkedShift!
    
    //Fetched Info from passed in var.
    var dataManager = DataManager()
    var timelogs = [Timelog]()
    var jobs = [Job]()
    
    // NOTE Variables passed to Details
    var selectedTimelog : Timelog!
    var previousTimelog : Timelog!
    var nextTimelog : Timelog!
    var selectedJob : Job!
    var hasMinDate = false
    var hasMaxDate = false
    var selectedRowIndex = Int()
    
    // Created to handle Incomplete
    var incompleteCell: TimelogCell!
    
    var newTimelogsCreated = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Shift"
        self.tableView.rowHeight = 30.0
        println(selectedWorkedShift)
        fetchTimelogs()
    }
    
    // TODO: Need to write reason for having both viewwillappear and viewDidAppear
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        fetchTimelogs()
        tableView.reloadData()
        println("selectedWorkedShift.status=\(selectedWorkedShift.status)")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        tableView.reloadData()
        dataManager.save()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBActions
    
    @IBAction func unwindShift (segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! ShiftTableViewController
        let destVC = segue.destinationViewController as! IncompleteShiftsTableViewController
        destVC.selectedWorkedShift = self.selectedWorkedShift
        dataManager.save()
    }
    
    @IBAction func unwindSaveDetailsTVC (segue: UIStoryboardSegue) {
        //by hitting the Save button
        let sourceVC = segue.sourceViewController as! DetailsTableViewController
        timelogs[selectedRowIndex] = sourceVC.selectedTimelog
        
        selectedWorkedShift.sumUpDuration()
        selectedWorkedShift.hoursWorked()
        selectedWorkedShift.moneyShiftOTx2()
        tableView.reloadData()
        
        selectedJob = sourceVC.selectedJob
        selectedWorkedShift.job = selectedJob
        
        if newTimelogsCreated == 1 {
            sourceVC.selectedTimelog.workedShift = selectedWorkedShift
            timelogs.append(sourceVC.selectedTimelog)
        } else if newTimelogsCreated == 2 {
            // TODO: write code to hanle 2 new TLs
            let endBreakTimeLog = dataManager.addItem("Timelog") as! Timelog
            endBreakTimeLog.time = timelogs.last!.time
            endBreakTimeLog.comment = ""
            if timelogs.count < 3 {
                endBreakTimeLog.type = "Ended Break"
            } else {
                endBreakTimeLog.type = "Ended Break #\((timelogs.count)/2)"
            }
            endBreakTimeLog.workedShift = selectedWorkedShift
            timelogs.append(endBreakTimeLog)
            
            sourceVC.selectedTimelog.workedShift = selectedWorkedShift
            timelogs.append(sourceVC.selectedTimelog)
        }
    }
    
    @IBAction func unwindCancelDetailsTVC (segue: UIStoryboardSegue) {
        //by hitting the Cancel button
        let sourceVC = segue.sourceViewController as! DetailsTableViewController
        if newTimelogsCreated > 0 {
            dataManager.delete(sourceVC.selectedTimelog)
        }
        selectedWorkedShift.status = 1

    }
 
    
    // MARK: - Class Functions
    
    func fetchTimelogs() {
        var predicate = NSPredicate(format: "SELF.workedShift == %@", selectedWorkedShift)
        var sortByTime = NSSortDescriptor(key: "time", ascending: true)
        timelogs = dataManager.fetch("Timelog", predicate: predicate, sortDescriptors: [sortByTime] ) as! [Timelog]
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if selectedWorkedShift.status == 1 {
            return 4
        } else {
            return 3
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return timelogs.count
        } else if section == 2 {
            if timelogs.last!.type == "Clocked Out" {
                return 0
            } else if timelogs.count % 2 == 1 {
                return 1
            } else {
                return 2
            }
        } else if section == 0 {
            return 0
        } else {
            return 1 //section 3
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("TimelogCell", forIndexPath: indexPath) as! TimelogCell
            cell.timelog = timelogs[indexPath.row]
            cell.jobColorView.setNeedsDisplay()
            return cell
        } else if indexPath.section == 3 {
            let cell = tableView.dequeueReusableCellWithIdentifier("ContinueShiftCell", forIndexPath: indexPath) as! UITableViewCell
            return cell
        } else {
            incompleteCell = tableView.dequeueReusableCellWithIdentifier("TimelogCell") as! TimelogCell
            incompleteCell.time.text = "Missing Time"
            incompleteCell.jobColorView.color = timelogs[indexPath.row].workedShift.job.color.getColor
            
            if indexPath.row == 0 && (timelogs.count % 2 == 0) {
                var breakNumber : Int = (timelogs.count / 2)
                if breakNumber == 1 {
                    incompleteCell.type.text = "Ended Break"
                } else {
                    incompleteCell.type.text = "Ended Break #\(breakNumber)"
                }
            } else {
                incompleteCell.type.text = "Clocked Out"
            }
            incompleteCell.jobColorView.setNeedsDisplay()
            return incompleteCell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var predicateJob = NSPredicate(format: "company == %@", (timelogs[indexPath.row].workedShift.job.company) )
        jobs = dataManager.fetch("Job", predicate: predicateJob) as! [Job]
        
        selectedJob = jobs[0]
        
        if indexPath.section == 1 {
            newTimelogsCreated = 0
            selectedTimelog = timelogs[indexPath.row]
            selectedRowIndex = (indexPath.row)
            
            if (indexPath.row) == 0 {
                hasMinDate = false // user select CLOCKIN so noMinDate
            } else {
                hasMinDate = true
                self.previousTimelog = timelogs[indexPath.row - 1]
            }
            if (timelogs.count - indexPath.row - 1) == 0 {
                hasMaxDate = false //user select last TIMELOG so noMaxDate is sent, and will use NSDATE instead
            } else {
                hasMaxDate = true
                self.nextTimelog = timelogs[indexPath.row + 1]
            }
            self.performSegueWithIdentifier("showDetails", sender: tableView.cellForRowAtIndexPath(indexPath))
        } else if indexPath.section == 2 {
            
            newTimelogsCreated = 1
            
            if indexPath.row == 1 { //clock out is sitting 2nd position so you need to add end break
                newTimelogsCreated = 2
            }
            
            let newTimelog = dataManager.addItem("Timelog") as! Timelog
            newTimelog.comment = ""
            newTimelog.time = (timelogs.last!.time).dateByAddingTimeInterval(1)
            
            if (indexPath.row) == 0 && timelogs.count % 2 == 0 { //you selected endbreak
                if timelogs.count < 3 {
                    newTimelog.type = "Ended Break"
                } else {
                    newTimelog.type = "Ended Break #\((timelogs.count)/2)"
                }
            } else { // you selected clock out
                newTimelog.type = "Clocked Out"
                selectedWorkedShift.status = 0
            }
            
            selectedTimelog = newTimelog
            
            hasMinDate = true
            self.previousTimelog = timelogs.last
            
            hasMaxDate = false
            
            // TODO : need to send up a restriction of 24hrs
            self.performSegueWithIdentifier("showDetails", sender: tableView.cellForRowAtIndexPath(indexPath))
        } else if indexPath.section == 3 {
            
            let predicateStatus = NSPredicate(format: "workedShift.status == 2")
            var runningShift = [WorkedShift]()
            runningShift = dataManager.fetch("Timelog", predicate: predicateStatus) as! [WorkedShift]
            
            if runningShift.count == 0 {
                self.performSegueWithIdentifier("unwindFromShiftToClockIn", sender: tableView.cellForRowAtIndexPath(indexPath))
            } else {
                let alert: UIAlertController = UIAlertController(title: "Warning! There is a shift in progress",
                    message: "The current shift in progress will be saved for later and this shift will continue.",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
                    self.performSegueWithIdentifier("unwindFromShiftToClockIn", sender: tableView.cellForRowAtIndexPath(indexPath)) }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    // Tableview Headers
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel.textAlignment = NSTextAlignment.Left
        
        if section == 0 {
            header.textLabel.text = "Work time = \( selectedWorkedShift.hoursWorked() ) hrs"
            header.textLabel.textColor = UIColor.blackColor()
            header.textLabel.font = UIFont.systemFontOfSize(16)
            header.textLabel.numberOfLines = 2;
        } else if section == 1 {
            header.textLabel.text = "Saved Entries:"
            header.textLabel.textColor = UIColor.blackColor()
            header.textLabel.font = UIFont.systemFontOfSize(12)
        } else if section == 2 && timelogs.last!.type != "Clocked Out" {
            header.textLabel.text = "Incomplete Entries:"
            header.textLabel.textColor = UIColor.redColor()
            header.textLabel.font = UIFont.boldSystemFontOfSize(12)
        }
    }
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 40
        } else if section == 1{
            return 35
        } else {
            return 35
        }
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let footer:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        footer.textLabel.textAlignment = NSTextAlignment.Left
        if section == 0 {
            footer.textLabel.text = "You earned $\( selectedWorkedShift.moneyShiftOTx2()) for this shift"
            footer.textLabel.textColor = UIColor.blackColor()
            footer.textLabel.font = UIFont.systemFontOfSize(12)
        }
    }
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return ""
    }
    
    
    // MARK: Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showDetails" {
            
            let destinationVC = segue.destinationViewController as! DetailsTableViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            destinationVC.selectedTimelog = self.selectedTimelog
            destinationVC.previousTimelog = self.previousTimelog
            destinationVC.nextTimelog = self.nextTimelog
            destinationVC.hasMinDate = self.hasMinDate
            destinationVC.hasMaxDate = self.hasMaxDate
            destinationVC.selectedJob = self.selectedJob
        }
    }
}
