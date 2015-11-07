//
//  ShiftViewController.swift
//  Punchie
//
//  Created by Joseph Pelina on 10/30/15.
//  Copyright (c) 2015 redgarage. All rights reserved.
//

import UIKit
import CoreData

class ShiftViewController: UIViewController {

    @IBOutlet weak var shiftTable: UITableView!
    @IBOutlet weak var addBreakButton: UIButton!
    @IBOutlet weak var worktimeLabel: UILabel!
    @IBOutlet weak var earnedLabel: UILabel!
    
    //PASSED IN VARIABLES:
    var selectedWorkedShift : WorkedShift!
    
    //Fetched Info from passed in var.
    var dataManager = DataManager()
    var timelogs = [Timelog]()
    var jobs = [Job]()
    var selectedDate: NSDate!
    var isNewShift = false
    
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
    var conflicts: [WorkedShift] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isNewShift {
            self.title = "Add Shift"
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "saveWorkedShift")
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelWorkedShift")
            selectedWorkedShift = dataManager.addItem("WorkedShift") as! WorkedShift
            selectedWorkedShift.setValue(3, forKey: "status")
            selectedWorkedShift.job = selectedJob
            timelogs = []
            createTimelog("Clocked In")
            createTimelog("Clocked Out")
        } else {
            self.title = "Shift"
            fetchTimelogs()
            selectedJob = selectedWorkedShift.job
        }
    }
    
    // TODO: Need to write reason for having both viewwillappear and viewDidAppear
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        fetchTimelogs()
        worktimeLabel.text = "\(selectedWorkedShift.hoursWorked()) hours worked"
        earnedLabel.text = "You earned $\(selectedWorkedShift.moneyShiftOTx2()) for this shift"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        shiftTable.reloadData()
        selectedJob.color.getColor
        selectedWorkedShift.sumUpDuration()
        dataManager.save()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - IBActions
    
    @IBAction func addBreakButtonPressed(sender: AnyObject) {

        if selectedWorkedShift.status == 1 && timelogs.count % 2 == 0 { // no clock out and last time log was a start break

            if timelogs.count < 3 {
                insertTimelog("Ended Break",id: Int16(timelogs.count))
            } else {
                insertTimelog( ("Ended Break #\(timelogs.count/2)") ,id: Int16(timelogs.count) )
            }
            insertTimelog( ("Started Break #\(timelogs.count/2 + 1)") ,id: Int16(timelogs.count) )
            
        } else if selectedWorkedShift.status != 1 { // the last time log clock out
            
            timelogs.last?.id += 2 //fetch clockout and increment ID by 2

            if timelogs.count < 3 {
                insertTimelog("Started Break",id: Int16(timelogs.count-1))
                insertTimelog("Ended Break",id: Int16(timelogs.count-1))
            } else {
                insertTimelog( ("Started Break #\( (timelogs.count+1) / 2)") ,id: Int16(timelogs.count-1) )
                insertTimelog( ("Ended Break #\(timelogs.count/2)") ,id: Int16(timelogs.count-1) )
            }
        } else { // the last time log was clockin or endbreak

            if timelogs.count < 3 {
                insertTimelog("Started Break",id: 1)
                insertTimelog("Ended Break",id: 2)
            } else {
                insertTimelog( ("Started Break #\( (timelogs.count+1) / 2)") ,id: Int16(timelogs.count) )
                insertTimelog( ("Ended Break #\(timelogs.count/2)") ,id: Int16(timelogs.count) )
            }
        }
        var indexPathScroll = NSIndexPath(forRow: 0, inSection: 3)
        self.shiftTable.scrollToRowAtIndexPath(indexPathScroll, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        shiftTable.reloadData()
    }
    
    @IBAction func unwindShift (segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! ShiftViewController
        let destVC = segue.destinationViewController as! IncompleteShiftsTableViewController
        destVC.selectedWorkedShift = self.selectedWorkedShift
        dataManager.save()
    }
    
    @IBAction func unwindSaveDetailsTVC (segue: UIStoryboardSegue) { //by hitting the Save button
        let sourceVC = segue.sourceViewController as! DetailsTableViewController
        timelogs[selectedRowIndex] = sourceVC.selectedTimelog
        
        selectedJob = sourceVC.selectedJob
        selectedWorkedShift.job = selectedJob
        
        if newTimelogsCreated == 1 {
            timelogs.append(sourceVC.selectedTimelog)
        } else if newTimelogsCreated == 2 {
            let endBreakTimeLog = dataManager.addItem("Timelog") as! Timelog
            endBreakTimeLog.time = timelogs.last!.time
            endBreakTimeLog.comment = ""
            if timelogs.count < 3 {
                endBreakTimeLog.type = "Ended Break"
            } else {
                endBreakTimeLog.type = "Ended Break #\((timelogs.count)/2)"
            }
            endBreakTimeLog.id = Int16(timelogs.count)
            endBreakTimeLog.workedShift = selectedWorkedShift
            timelogs.append(endBreakTimeLog)
            sourceVC.selectedTimelog.workedShift = selectedWorkedShift
            timelogs.append(sourceVC.selectedTimelog)
        }
        
        if isNewShift { //To handle changing the subsequent timelogs
            for id in Int(selectedTimelog.id)...(timelogs.count-1) {
                if selectedTimelog.time.timeIntervalSince1970 > timelogs[id].time.timeIntervalSince1970 {
                    timelogs[id].time = selectedTimelog.time
                }
                if timelogs[id].type == "Clocked Out" { // Change the endtime, for the check i changed ahead of time (in details checkForConflicts)
                    selectedWorkedShift.endTime = timelogs[id].time
                }
            }
        }
        selectedWorkedShift.sumUpDuration()
        selectedWorkedShift.hoursWorked()
        selectedWorkedShift.moneyShiftOTx2()
        shiftTable.reloadData()
    }
    
    @IBAction func unwindCancelDetailsTVC (segue: UIStoryboardSegue) {
        //by hitting the Cancel button
        let sourceVC = segue.sourceViewController as! DetailsTableViewController
        if newTimelogsCreated > 0 { //Note only if these time logs were created
            dataManager.delete(sourceVC.selectedTimelog)
            selectedWorkedShift.status = 1
        }
    }
    
    // MARK: - Class Functions
    
    func fetchTimelogs() {
        var predicate = NSPredicate(format: "SELF.workedShift == %@", selectedWorkedShift)
        var sortByID = NSSortDescriptor(key: "id", ascending: true)
        timelogs = dataManager.fetch("Timelog", predicate: predicate, sortDescriptors: [sortByID] ) as! [Timelog]
        shiftTable.reloadData()
    }

    func insertTimelog(type: String,  id: Int16){
        let newTimelog = dataManager.addItem("Timelog") as! Timelog
        newTimelog.workedShift = selectedWorkedShift
        newTimelog.comment = ""
        newTimelog.type = type
        newTimelog.id = id
        timelogs.sort({ $0.id < $1.id })
        newTimelog.time = timelogs.last!.time
        timelogs.append(newTimelog)
        timelogs.sort({ $0.id < $1.id })
    }

    func checkConflicts(shift: WorkedShift) {
        var completedShift = NSPredicate(format: "status != 1 AND status != 2")
        var startPredicateBefore = NSPredicate(format: "startTime >= %@" , shift.startTime)
        var selfPredicate = NSPredicate(format: "SELF != %@", shift)
        var predicate: NSCompoundPredicate
        predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [completedShift, startPredicateBefore, selfPredicate])
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: true)
        let sortDescriptors = [sortDescriptor]
        conflicts = []
        conflicts = dataManager.fetch("WorkedShift", predicate: predicate, sortDescriptors: sortDescriptors) as! [WorkedShift]
    }
    
    func checkRunningShifts() {
        // Check for running shifts
        
        let predicateStatus = NSPredicate(format: "status == 2")
        var runningShift = [WorkedShift]()
        runningShift = dataManager.fetch("WorkedShift", predicate: predicateStatus) as! [WorkedShift]
        
        if runningShift.count == 0 {
            self.performSegueWithIdentifier("unwindFromShiftToClockIn", sender: nil )
        } else {
            let alert: UIAlertController = UIAlertController(title: "Warning! There is a shift in progress",
                message: "The current shift in progress will be saved for later and this shift will continue.",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
                self.performSegueWithIdentifier("unwindFromShiftToClockIn", sender: nil )
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //AddShift SAVE and CANCEL; CREATE
    func saveWorkedShift() {
        selectedWorkedShift.startTime = timelogs.first!.time

        dataManager.save()
        navigationController?.popViewControllerAnimated(true)
    }
    
    func cancelWorkedShift() {
        if isNewShift {
            dataManager.delete(selectedWorkedShift)
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
    func createTimelog(type: String){
        let newTimelog = dataManager.addItem("Timelog") as! Timelog
        newTimelog.workedShift = selectedWorkedShift
        newTimelog.comment = ""
        newTimelog.type = type
        newTimelog.time = selectedDate
        newTimelog.id = Int16(timelogs.count)
        timelogs.append(newTimelog)
        if type == "Clocked In" {
            selectedWorkedShift.startTime = newTimelog.time
        } else if type == "Clocked Out" {
            selectedWorkedShift.endTime = newTimelog.time
        }
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
    
    @IBAction func unwindFromJobsListTableViewControllerToShift (segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! JobsListTableViewController
        selectedJob = sourceVC.selectedJob
        
        if sourceVC.selectedJob != nil {
            selectedJob = sourceVC.selectedJob
            selectedWorkedShift.job = selectedJob
            shiftTable.reloadData()
        }
    }
}

extension ShiftViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 4
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { //Jobs
          return 1
        } else if section == 1 { //Complete Timelogs
            return timelogs.count
        } else if section == 2 {
            if selectedWorkedShift.status == 1 { // 2=running, 1=incomplete, 0=complete, 3=added manually
                if timelogs.count % 2 == 1 {
                    return 1
                } else {
                    return 2
                }
            } else {
                return 0
            }
        } else { //SectionIndex3 = continue shift and delete shift
            
            if selectedWorkedShift.status == 1 {
                return 2 // incomplete = need continue shift button
            } else {
                return 1
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("JobsListCell", forIndexPath: indexPath) as! JobsListCell
            cell.job = selectedWorkedShift.job
            cell.jobColorView.setNeedsDisplay()
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("TimelogCell", forIndexPath: indexPath) as! TimelogCell
            cell.timelog = timelogs[indexPath.row]
            cell.jobColorView.setNeedsDisplay()
            return cell
        } else if indexPath.section == 3 {
            if selectedWorkedShift.status == 1 && indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("ContinueShiftCell", forIndexPath: indexPath) as! UITableViewCell
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("DeleteShiftCell", forIndexPath: indexPath) as! UITableViewCell
                return cell
            }
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

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            let addJobStoryboard: UIStoryboard = UIStoryboard(name: "CalendarStoryboard", bundle: nil)
            let jobsListVC: JobsListTableViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("JobsListTableViewController")
                as! JobsListTableViewController
            jobsListVC.source = "shift"
            jobsListVC.previousSelection = selectedJob
            
            self.navigationController?.pushViewController(jobsListVC, animated: true)
        
        } else if indexPath.section == 1 {
            newTimelogsCreated = 0
            selectedTimelog = timelogs[indexPath.row]
            selectedRowIndex = (indexPath.row)
            
            if (indexPath.row) == 0 { // user select CLOCKIN so noMinDate
                hasMinDate = false
            } else {
                hasMinDate = true
                self.previousTimelog = timelogs[indexPath.row - 1]
            }
            
            if (timelogs.count - indexPath.row - 1) == 0 {
                hasMaxDate = false //user select last TIMELOG so noMaxDate is sent, and will use NSDATE instead
            } else if isNewShift {
                hasMaxDate = false //user started a Newshift with all times at 12:00am
            } else {
                hasMaxDate = true
                self.nextTimelog = timelogs[indexPath.row + 1]
            }
            self.performSegueWithIdentifier("showDetails", sender: tableView.cellForRowAtIndexPath(indexPath))
        } else if indexPath.section == 2 {

            let predicateStatus = NSPredicate(format: "status == 2")
            var runningShift = [WorkedShift]()
            runningShift = dataManager.fetch("WorkedShift", predicate: predicateStatus) as! [WorkedShift]

            if (runningShift.count > 0) && (timelogs.last!.time.timeIntervalSince1970 > runningShift[0].startTime.timeIntervalSince1970) {
                let alert: UIAlertController = UIAlertController(title: "Can not create entry",
                    message: "The current running shift conflicts with this shift.",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                if indexPath.row == 1 { //clock out is sitting 2nd position so you need to add end break
                    newTimelogsCreated = 2
                } else {
                    newTimelogsCreated = 1
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
                    newTimelog.id = Int16(timelogs.count)
                } else { // you selected clock out
                    newTimelog.type = "Clocked Out"
                    newTimelog.id = Int16(timelogs.count)
                    selectedWorkedShift.status = 0
                }
                newTimelog.workedShift = selectedWorkedShift
                selectedTimelog = newTimelog
                hasMinDate = true
                self.previousTimelog = timelogs.last
                hasMaxDate = false
                self.performSegueWithIdentifier("showDetails", sender: tableView.cellForRowAtIndexPath(indexPath))
            }
        } else if indexPath.section == 3 {
            
            if selectedWorkedShift.status == 1 && indexPath.row == 0 {
                
                checkConflicts(selectedWorkedShift)
                
                if conflicts.count == 0 {
                    checkRunningShifts()
                } else {
                    let formatter = NSDateFormatter()
                    formatter.dateStyle = .ShortStyle
                    let startDay = formatter.stringFromDate(conflicts[0].startTime)
                    let endDay = formatter.stringFromDate(conflicts[0].endTime)
                    formatter.dateStyle = .NoStyle
                    formatter.timeStyle = .ShortStyle
                    formatter.timeZone = NSTimeZone()
                    let startTime = formatter.stringFromDate(conflicts[0].startTime)
                    let endTime = formatter.stringFromDate(conflicts[0].endTime)
                    
                    let job = "\(conflicts[0].job.company) - \(conflicts[0].job.position)"
                    
                    var message: String!
                    
                    if startDay == endDay {
                        message = String(format: "\nReplace the following shift: \n%@ \n%@ %@ - %@", job, startDay, startTime, endTime)
                    } else {
                        message = String(format: "\nReplace the following shift: \n%@ \n%@ %@ - %@ %@", job, startDay, startTime, endDay, endTime)
                    } //TODO: change message to have all conflicts
                    
                    var title = "\(conflicts.count) Shift Conflict"
                    var replaceTitle = "Replace"
                    
                    if conflicts.count > 1 {
                        title += "s"
                        replaceTitle += " All (\(conflicts.count))"
                    }
                    
                    let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
                    
                    let replace = UIAlertAction(title: replaceTitle, style: .Destructive) { (action) in
                        for conflict in self.conflicts {
                            let app = UIApplication.sharedApplication()
                            
                            for event in app.scheduledLocalNotifications {
                                let notification = event as! UILocalNotification
                                let startTime = notification.fireDate
                                
                                if conflict.startTime.compare(startTime!) == NSComparisonResult.OrderedSame {
                                    app.cancelLocalNotification(notification)
                                    break
                                }
                            }
                            self.dataManager.delete(conflict)
                        }
                        self.checkRunningShifts()
                    }
                    alertController.addAction(replace)
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            } else { //To handle if user clicked delete
                dataManager.delete(selectedWorkedShift)
                navigationController?.popViewControllerAnimated(true)
            }
        }
    }
    
    // Tableview Headers
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel.textAlignment = NSTextAlignment.Left
        
        if section == 0 {
            header.textLabel.text = "Job"
            header.textLabel.textColor = UIColor.blackColor()
            header.textLabel.font = UIFont.systemFontOfSize(12)
            header.textLabel.numberOfLines = 2;
        } else if section == 1 {
            header.textLabel.text = "Entries"
            header.textLabel.textColor = UIColor.blackColor()
            header.textLabel.font = UIFont.systemFontOfSize(12)
        } else if section == 2 && timelogs.last!.type != "Clocked Out" {
            header.textLabel.text = "Incomplete Entries"
            header.textLabel.textColor = UIColor.redColor()
            header.textLabel.font = UIFont.boldSystemFontOfSize(12)
        }
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section >= 3 || indexPath.section == 0  { // Note = ContinueShift/DeletShift
            return 44
        } else {
            return 30
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //Swipe to delete (BREAKS are grouped together, CI deletes entire shift. CO makes incomplete)
        if indexPath.section == 1 {
            return true
        } else {
            return false
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            if indexPath.row == 0 {
                let alert: UIAlertController = UIAlertController(title: "Clock In",
                    message: "Cannot delete this entry.",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            } else if indexPath.row == (timelogs.count-1) && selectedWorkedShift.status != 1 {
                let alert: UIAlertController = UIAlertController(title: "Clock out",
                    message: "Cannot delete this entry.",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                self.dataManager.delete(self.timelogs[indexPath.row])
                self.timelogs.removeAtIndex(indexPath.row)
                var factor = 0
                
                if indexPath.row % 2 == 0 { //endbreak being deleted. so need to delete previous "start break"
                    self.dataManager.delete(self.timelogs[indexPath.row - 1 ])
                    self.timelogs.removeAtIndex(indexPath.row - 1 )
                    factor = 1
                } else if indexPath.row % 2 == 1 && indexPath.row != (self.timelogs.count) { //startbreak deleted and not the last timelog then delete the next entry also. which is a "end break"
                    self.dataManager.delete(self.timelogs[indexPath.row])
                    self.timelogs.removeAtIndex(indexPath.row)
                }
                if timelogs.count > 3 {
                    for timelogNumber in (indexPath.row - factor)...(self.timelogs.count-1) { // changes all remaining names... including if clocked out existed
                        self.timelogs[timelogNumber].id += -2

                        if self.timelogs[timelogNumber].id % 2 == 0 { //end break
                            
                            if self.timelogs[timelogNumber].id == 2 {
                                self.timelogs[timelogNumber].type = "Ended Break"
                            } else {
                                self.timelogs[timelogNumber].type = "Ended Break #\((timelogNumber+1)/2)"
                            }
                        } else {
                            if self.timelogs[timelogNumber].id == 1 {
                                self.timelogs[timelogNumber].type = "Started Break"
                            } else {
                                self.timelogs[timelogNumber].type = "Started Break #\((timelogNumber+1)/2)"
                            }
                        }
                    }
                    if selectedWorkedShift.status != 1 { // need to handle the clock out specially (outside of for loop) for now
                        timelogs.last?.type = "Clcoked Out"
                    }
                }
                self.timelogs.sort({ $0.id < $1.id })
                self.shiftTable.reloadData()
                dataManager.save()
            }
        }
    }
}
