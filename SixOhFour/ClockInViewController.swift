
//  ClockInViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 6/26/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class ClockInViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var workTimeLabel: UILabel!
    @IBOutlet weak var breakTitleLabel: UILabel!
    @IBOutlet weak var jobTable: UITableView!
    @IBOutlet weak var shiftTableView: UITableView!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var breakButton: UIButton!
    @IBOutlet weak var editBreakButton: UIButton!
    @IBOutlet weak var saveForLaterButton: UIButton!
    @IBOutlet weak var incompleteFolderButton: UIButton!

    var timer = NSTimer()
    
    var minutes = 0
    var seconds = 0
    var hours = 0
    
    var breakTimer = NSTimer()
  
    var breaktimeSecondsSet: Double = 30*60 // Default = 30mins
    var breaktimeSecondsRemaining = 0.0
    var breakSeconds = 0 //whats is remaining and displayed
    var breakMinutes = 0 //whats is remaining and displayed
    var breakHours = 0 //whats is remaining and displayed

    var breakTimerOver = NSTimer()
    var workTimerString = ""
    var breakTimerString = ""
    var timeOfSnooze: NSDate!
    
    var state = ShiftState.Idle
    
    var jobsList = [Job]()
    var isJobListEmpty = true
    
    //Variables for Segue: "showDetails"
    var selectedTimelog : Timelog!
    var previousTimelog : Timelog!
    var nextTimelog : Timelog!
    var selectedJob : Job!
    var hasMinDate = false
    var hasMaxDate = false
    
    var timelogs = [Timelog]()
    var lastTimestamp : NSDate!
    
    var selectedRowIndex = -1
    var elapsedTime = 0
    var duration = 0.0
    var totalBreaktime = 0.0
    
    var currentWorkedShift : WorkedShift!
    var dataManager = DataManager()
    var conflicts = [WorkedShift]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shiftTableView.rowHeight = 30.0
        clearBreak()
        checkLastShift()
        UIView.performWithoutAnimation {
            self.editBreakButton.layer.removeAllAnimations()
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "StopTimerNotification:", name:"StopTimerNotification", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        reloadTable()
        checkForIncomplete()
        checkAndRunStates()
        
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        let sortDescriptors = [sortDescriptor]
        jobsList = dataManager.fetch("Job", sortDescriptors: sortDescriptors ) as! [Job]
        
        if jobsList.count == 0 {
            isJobListEmpty = true
            startStopButton.enabled = false
            workTimeLabel.textColor = UIColor.grayColor()
            
        } else {
            isJobListEmpty = false
            if selectedJob == nil || !contains(jobsList, selectedJob) { // NOTE: SELECTS THE FIRST JOB WHEN APP IS LOADED
                selectedJob = jobsList[0]

                let predicate = NSPredicate(format: "order == 0")
                let jobs = dataManager.fetch("Job", predicate: predicate) as! [Job]
                selectedJob = jobs[0]
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: IBActions:

    @IBAction func startStop(sender: AnyObject) {
        if state == .Idle { //CLOCK IN
            saveTimelog("Clocked In")
            checkAndRunStates()
        } else if state == .OnTheClock { //CLOCK OUT
            checkConflicts(currentWorkedShift)
        }
    }
    
    @IBAction func lapReset(sender: AnyObject) {

        if state == .OnTheClock { //STARTED BREAK
            breaktimeSecondsRemaining = breaktimeSecondsSet
            createNotifyBreakOver(breaktimeSecondsSet)
            
            if timelogs.count == 1 {
                saveTimelog("Started Break")
            } else {
                saveTimelog("Started Break #\( (timelogs.count + 1 ) / 2 )")
            }
        } else if state == .OnBreak {  //ENDED BREAK
            if timelogs.count == 2 {
                saveTimelog("Ended Break")
            } else {
                saveTimelog("Ended Break #\(timelogs.count/2)")
            }
        } else if state == .ClockedOut {
            clearShift() //also changes state to .Idle
        }
        checkAndRunStates()
    }
    
    
    @IBAction func saveForLaterButtonPressed(sender: AnyObject) {
        //Note: Notifications insdie the App (Home screen and Lock Screen)
        let alert: UIAlertController = UIAlertController(title: "Save this shift for later",
            message: "This shift can be edited later in the incomplete folder.",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            self.stopShift()
            self.checkAndRunStates() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: Segues (Unwind) = Getting data from sourceVC
    
    @IBAction func unwindFromJobsListTableViewControllerToClockIn (segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! JobsListTableViewController
        selectedJob = sourceVC.selectedJob
        
        if timelogs.count > 0 {
            currentWorkedShift.job = selectedJob
        }
        reloadTable()
    }
    
    // Same unwind func in 2 differect VCs, control each exit independently
    @IBAction func unwindSaveDetailsTVC (segue: UIStoryboardSegue) {
        //by hitting the SAVE button
        let sourceVC = segue.sourceViewController as! DetailsTableViewController
        timelogs[selectedRowIndex].time = sourceVC.selectedTimelog.time

        currentWorkedShift.sumUpDuration()
        
        elapsedTime = Int(currentWorkedShift.duration)
        updateWorkTimerLabel()
        
        selectedJob = sourceVC.selectedJob
        
        if sourceVC.selectedJob != nil {
            selectedJob = sourceVC.selectedJob
        }
        
        if timelogs != [] {
            saveWorkedShiftToJob()
        }
        saveWorkedShiftToJob()
        reloadTable()
    }
    
    @IBAction func unwindCancelDetailsTVC (segue: UIStoryboardSegue) {
        //by hitting the CANCEL button
        //Nothing saved!
    }
    
    @IBAction func unwindFromSetBreakTimeViewController (segue: UIStoryboardSegue) {
        
        let sourceVC = segue.sourceViewController as! SetBreakTimeViewController
  
        breaktimeSecondsRemaining += (sourceVC.breaktimeSecondsSet - breaktimeSecondsSet)
        breaktimeSecondsSet = sourceVC.breaktimeSecondsSet
        createNotifyBreakOver(breaktimeSecondsSet)
    }
    
    @IBAction func unwindFromShiftToClockIn (segue: UIStoryboardSegue) {
        
        let sourceVC = segue.sourceViewController as! ShiftViewController
        
        if timelogs.count > 0 {
            stopShift()
        }
        
        sourceVC.selectedWorkedShift.status = 2
        currentWorkedShift = sourceVC.selectedWorkedShift
        
        checkForIncomplete()
        timelogs = sourceVC.timelogs
        reloadTable()
    }
    
    //MARK: Functions
    
    func checkAndRunStates() {
    
        if timelogs.count == 0 {
            state = .Idle
        } else {
            if timelogs.last!.type == "Clocked Out" {
                state = .ClockedOut
            } else {
                if timelogs.count % 2 == 1 {
                    state = .OnTheClock
                } else {
                    state = .OnBreak
                }
            }
        }
        
        if state == .Idle {
            workTimeLabel.text = "00:00:00"
            startStopButton.enabled = true
            breakButton.enabled = false
            saveForLaterButton.hidden = true
            startStopButton.setTitle("Clock In", forState: UIControlState.Normal)
            breakButton.setTitle("Start Break", forState: UIControlState.Normal)
        } else if state == .OnTheClock {
            saveForLaterButton.hidden = false
            startStopButton.setTitle("Clock Out", forState: UIControlState.Normal)
            breakButton.setTitle("Start Break", forState: UIControlState.Normal)
            breakButton.enabled = true
            if !timer.valid {
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runAndUpdateWorkTimer"), userInfo: nil, repeats: true)
            }
            startStopButton.enabled = true
            clearBreak()
        } else if state == .OnBreak {
            displayBreaktime()
            saveForLaterButton.hidden = false
            runAndUpdateWorkTimer()
            if !breakTimer.valid {
            breakTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runBreakTimer"), userInfo: nil, repeats: true)
            }
            createNotifyBreakOver(breaktimeSecondsRemaining)
            timer.invalidate()
            breakTitleLabel.hidden = false
            editBreakButton.hidden = false
            editBreakButton.enabled = true
            startStopButton.enabled = false
            breakButton.setTitle("End Break", forState: UIControlState.Normal)
            breakButton.enabled = true
            currentWorkedShift.sumUpDuration()
        } else if state == .ClockedOut {
            clearBreak()
            saveForLaterButton.hidden = true
            timer.invalidate()
            startStopButton.setTitle("", forState: UIControlState.Normal)
            startStopButton.enabled = false
            breakButton.setTitle("New Shift", forState: UIControlState.Normal)
            currentWorkedShift.sumUpDuration()
            saveWorkedShiftToJob()
        }
    }
    
    func reloadTable() {
        jobTable.reloadData()
        shiftTableView.reloadData()
    }
    
    func saveTimelog(type : String){
        // NOTE: New time log
        let newTimelog = dataManager.addItem("Timelog") as! Timelog
        newTimelog.setValue(type, forKey: "type")
        newTimelog.time = NSDate()
        newTimelog.setValue("", forKey: "comment")
        newTimelog.id = Int16(timelogs.count)
        
        // NOTE: Assigning proper WorkedShift
        if type == "Clocked In" {
            let newWorkedShift = dataManager.addItem("WorkedShift") as! WorkedShift
            currentWorkedShift = newWorkedShift
            currentWorkedShift.startTime = newTimelog.time
            currentWorkedShift.status = 2 // 2=running, 1=incomplete, 0=complete, 3=added manually
            newTimelog.workedShift = currentWorkedShift
        } else {
            newTimelog.workedShift = currentWorkedShift
            if type == "Clocked Out"{
                currentWorkedShift.endTime = newTimelog.time
                currentWorkedShift.status = 0
            }
        }
        timelogs.append(newTimelog)
        currentWorkedShift.sumUpDuration()
        saveWorkedShiftToJob()
        reloadTable()
        var indexPathScroll = NSIndexPath(forRow: (timelogs.count-1), inSection: 0) //Scroll to the bottom
        self.shiftTableView.scrollToRowAtIndexPath(indexPathScroll, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
    
    func saveWorkedShiftToJob() {
        var predicateJob = NSPredicate(format: "company == %@ && position == %@" , selectedJob.company, selectedJob.position)
        let assignedJob = dataManager.fetch("Job", predicate: predicateJob) as! [Job]
        currentWorkedShift.job = assignedJob[0]
        dataManager.save()
    }
    
    func StopTimerNotification(notification: NSNotification!){
        if state != .Idle {
            timer.invalidate()
            breakTimer.invalidate()
            breakTimerOver.invalidate()
            clearShift()
        }
    }

    
    func checkConflicts(shift: WorkedShift) {
        
        var startOfShift = currentWorkedShift.startTime
        var endOfShift = NSDate()
        
        var startPredicate = NSPredicate(format: "startTime < %@ AND %@ < endTime", startOfShift, startOfShift)
        var selfPredicate = NSPredicate(format: "SELF != %@", shift)
        var predicate: NSCompoundPredicate
        
        let endPredicate = NSPredicate(format: "startTime < %@ AND %@ < endTime", endOfShift, endOfShift)
        let startPredicate1 = NSPredicate(format: "%@ < startTime AND startTime < %@", startOfShift, endOfShift)
        let endPredicate2 = NSPredicate(format: "%@ < endTime AND endTime < %@", startOfShift, endOfShift)
        let shiftPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType,
            subpredicates: [startPredicate, endPredicate, startPredicate1, endPredicate2])
        predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [shiftPredicate, selfPredicate])
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: true)
        let sortDescriptors = [sortDescriptor]
        
        conflicts = []
        conflicts = dataManager.fetch("WorkedShift", predicate: predicate, sortDescriptors: sortDescriptors) as! [WorkedShift]
    
        if conflicts.count == 0 {
            saveTimelog("Clocked Out")
            checkAndRunStates()
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
            
            var conflictsMessage = "\n"
            
            for conflict in conflicts {
                let date = NSDateFormatter.localizedStringFromDate(conflict.startTime, dateStyle: .MediumStyle, timeStyle: .NoStyle)
                let start = NSDateFormatter.localizedStringFromDate(conflict.startTime, dateStyle: .NoStyle, timeStyle: .ShortStyle)
                let end = NSDateFormatter.localizedStringFromDate(conflict.endTime, dateStyle: .NoStyle, timeStyle: .ShortStyle)
                
                conflictsMessage += String(format: "%@, %@ - %@\n", date, start, end)
            }
            
            var title = "\(conflicts.count) Shift Conflict"
            var replaceTitle = "Replace"
            
            if conflicts.count > 1 {
                title += "s"
                replaceTitle += " All (\(conflicts.count))"
            }
            
            let alertController = UIAlertController(title: title, message: conflictsMessage, preferredStyle: UIAlertControllerStyle.ActionSheet)
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
                self.saveTimelog("Clocked Out")
                self.checkAndRunStates()
            }
            alertController.addAction(replace)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }

    
    }

    
    // DURATION FUNCTIONS
    
    func runAndUpdateWorkTimer() {
        //currently calculated since clock in and subtracting the total breaktime duration
        let elapsedTimeInterval = NSDate().timeIntervalSinceDate(timelogs.last!.time)
        elapsedTime = Int(elapsedTimeInterval) + Int(currentWorkedShift.duration)
        updateWorkTimerLabel()
    }
    
    func updateWorkTimerLabel() {
        
        var elapsedSecond :Int = 0
        var elapsedMinute :Int = 0
        var elapsedHour :Int = 0
        
        if elapsedTime >= 3600 {
            elapsedSecond = (elapsedTime % 60 ) % 60
            elapsedMinute = (elapsedTime % 3600 ) / 60
            elapsedHour = elapsedTime / 60 / 60
        } else if elapsedTime >= 60 {
            elapsedSecond = elapsedTime % 60
            elapsedMinute = elapsedTime / 60
            elapsedHour = 0
        } else {
            elapsedSecond = elapsedTime
            elapsedMinute = 0
            elapsedHour = 0
        }
        workTimerString  = getTimerString(elapsedSecond, minutes: elapsedMinute, hours: elapsedHour)
        workTimeLabel.text = workTimerString
    }
    
    func runBreakTimer() {
        
    
        if  breakTitleLabel.text == "You've extended your break by 5 minutes" { //To handle the snooze
            var differenceInTime = NSDate().timeIntervalSinceDate(timeOfSnooze)
            breaktimeSecondsRemaining = 60 * 5 - differenceInTime
        } else {
            var differenceInTime = NSDate().timeIntervalSinceDate(timelogs.last!.time)
            breaktimeSecondsRemaining = breaktimeSecondsSet - differenceInTime
        }
        
        if breaktimeSecondsRemaining >= 3600 {
            breakSeconds = (Int(breaktimeSecondsRemaining) % 60 ) % 60
            breakMinutes = (Int(breaktimeSecondsRemaining) % 3600 ) / 60
            breakHours = Int(breaktimeSecondsRemaining) / 60 / 60
        } else if breaktimeSecondsRemaining >= 60 {
            breakSeconds = Int(breaktimeSecondsRemaining) % 60
            breakMinutes = Int(breaktimeSecondsRemaining) / 60
            breakHours = 0
        } else if breaktimeSecondsRemaining >= 0 {
            breakSeconds = Int(breaktimeSecondsRemaining)
            breakMinutes = 0
            breakHours = 0
        } else {
            breakTimer.invalidate()
            alertBreakOver()
            if !breakTimerOver.valid{
                breakTimerOver = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runBreakTimerOver"), userInfo: nil, repeats: true)
            }
        }
        breakTimerString  = getTimerString(breakSeconds, minutes: breakMinutes, hours: breakHours)
        editBreakButton.setTitle(breakTimerString, forState: UIControlState.Normal)
    }
    
    func runBreakTimerOver() {
        breakTitleLabel.text = "You are running over your breaktime"
        editBreakButton.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
        
        editBreakButton.enabled = false
        
        breakSeconds += 1
        
        if breakSeconds == 60 {
            breakMinutes += 1
            breakSeconds = 0
        }
        if breakMinutes == 60 {
            breakHours += 1
            breakMinutes = 0
        }
        breakTimerString  = getTimerString(breakSeconds, minutes: breakMinutes, hours: breakHours)
        editBreakButton.setTitle(breakTimerString, forState: UIControlState.Normal)
    }
    
    func displayBreaktime() {
        
        editBreakButton.setTitleColor(self.view.tintColor, forState: UIControlState.Normal)
        
        var breakHoursSet = Int(breaktimeSecondsSet) / 60 / 60
        var breakMinutesSet = (Int(breaktimeSecondsSet) % 3600 ) / 60

        if !breakTimer.valid { // This function displays Break time instantly
            breakTimerString  = getTimerString(0, minutes: breakMinutesSet, hours: breakHoursSet)
            editBreakButton.setTitle(breakTimerString, forState: UIControlState.Normal)
        }

        
        if breaktimeSecondsSet >= 3600 {
            breakTitleLabel.text = "Your break is set to \(breakHoursSet) hr and \(breakMinutesSet) min"
        } else if breaktimeSecondsSet >= 60 {
            breakTitleLabel.text = "Your break is set to \(breakMinutesSet) min"
        }
    }
    
    func createNotifyBreakOver(seconds : Double) {
        //Notifications outside the App (Home screen and Lock Screen)
        cancelNotifyBreakOver()
        var localNotification: UILocalNotification = UILocalNotification()
        localNotification.alertAction = "Breaktime Over"
        localNotification.alertBody = "Your breaktime is over!"
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.fireDate = NSDate(timeIntervalSinceNow: seconds) //seconds from now
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func alertBreakOver() {
        //Notifications insdie the App (Home screen and Lock Screen)
        let alert: UIAlertController = UIAlertController(title: "Breaktime is over!",
            message: "Please choose from the following:",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Clock In", style: .Default, handler: {action in self.lapReset(true)}))
        alert.addAction(UIAlertAction(title: "Add 5 Minutes", style: .Default, handler: { action in
            self.breakTimerOver.invalidate()
            self.timeOfSnooze = NSDate()
            self.editBreakButton.enabled = false
            self.editBreakButton.setTitleColor(self.view.tintColor, forState: UIControlState.Normal)
            self.breakTitleLabel.text = "You've extended your break by 5 minutes"
            self.breakTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runBreakTimer"), userInfo: nil, repeats: true)
            self.createNotifyBreakOver(300)
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func cancelNotifyBreakOver () {
        let app = UIApplication.sharedApplication()
        for event in app.scheduledLocalNotifications {
            let notification = event as! UILocalNotification
            if notification.alertBody == "Your breaktime is over!" {
                app.cancelLocalNotification(notification)
            }
        }
    }
    
    func getTimerString(seconds: Int, minutes: Int, hours: Int) -> String {
        let secondsString = String.secondsString(seconds)
        let minutesString = String.minutesString(minutes)
        let hoursString = String.hoursString(hours)
        return "\(hoursString):\(minutesString):\(secondsString)"
    }
    
    func checkForIncomplete() {
        let predicateIncomplete = NSPredicate(format: "status == 1")
        var incompleteShifts = dataManager.fetch("WorkedShift", predicate: predicateIncomplete) as! [WorkedShift]

        if incompleteShifts.count == 0 {
            incompleteFolderButton.enabled = false
            incompleteFolderButton.setTitle("", forState: UIControlState.Normal)
        } else {
            incompleteFolderButton.enabled = true
            incompleteFolderButton.setTitle(" \(incompleteShifts.count)", forState: UIControlState.Normal)
        }
    }
    
    func clearShift() {
        timelogs = []
        reloadTable()
        timer.invalidate()
        clearBreak()
        saveWorkedShiftToJob()
        workTimeLabel.text = "00:00:00"
        editBreakButton.setTitle(" ", forState: UIControlState.Normal)
        breakTitleLabel.text = " "
        totalBreaktime = 0
    }
    
    func clearBreak() {
        breakTitleLabel.hidden = true
        editBreakButton.enabled = false
        editBreakButton.hidden = true
        cancelNotifyBreakOver()
        breakTimerOver.invalidate()
        breakTimer.invalidate()
    }
    
    func stopShift() {
        currentWorkedShift.status = 1
        incompleteFolderButton.enabled = true
        clearShift()
        checkForIncomplete()
    }
    
    func checkLastShift() {
        
        // Check to see if last running shift (status = 2) needs to continue or convert to incomplete (status = 1)
        let predicateRunning = NSPredicate(format: "status == 2")
        var runningShifts = [WorkedShift]()
        runningShifts = dataManager.fetch("WorkedShift", predicate: predicateRunning) as! [WorkedShift]
        
        if runningShifts.count > 0 {
        
            if runningShifts[0].startTime.timeIntervalSinceNow > (-20*60*60) { //Continue Last Shift!
                if timelogs.count > 0 {
                    stopShift()
                }
                currentWorkedShift = runningShifts[0]
                selectedJob = currentWorkedShift.job
            
                var predicate = NSPredicate(format: "SELF.workedShift == %@", currentWorkedShift)
                var sortByTime2 = NSSortDescriptor(key: "time", ascending: true)
                timelogs = dataManager.fetch("Timelog", predicate: predicate, sortDescriptors: [sortByTime2] ) as! [Timelog]
                
                reloadTable()
                checkAndRunStates()
                
            } else { //convert all status = 1 that began past 20hrs ago
                for workedShift in runningShifts {
                    workedShift.status = 1
                }
                dataManager.save()
            }
        }
    }
    
    // MARK: Segues (Show)
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editBreaktimeSegue" {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.Plain, target: nil, action: nil)
            let destinationVC = segue.destinationViewController as! SetBreakTimeViewController
            destinationVC.navigationItem.title = "Set Breaktime"
            destinationVC.hidesBottomBarWhenPushed = true;
            destinationVC.breaktimeSecondsSet = self.breaktimeSecondsSet
        } else if segue.identifier == "showDetails" {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Cancel", style:.Plain, target: nil, action: nil)
            let destinationVC = segue.destinationViewController as! DetailsTableViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            destinationVC.selectedTimelog = self.selectedTimelog
            destinationVC.previousTimelog = self.previousTimelog
            destinationVC.nextTimelog = self.nextTimelog
            destinationVC.hasMinDate = self.hasMinDate
            destinationVC.hasMaxDate = self.hasMaxDate
            destinationVC.selectedJob = self.selectedJob
        } else if segue.identifier == "showIncompleteShifts" {
            let destinationVC = segue.destinationViewController as! IncompleteShiftsTableViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.Plain, target: nil, action: nil)
        }
    }
}

extension ClockInViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: Table View functions
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if tableView == shiftTableView {
            let cell = tableView.dequeueReusableCellWithIdentifier("TimelogCell", forIndexPath: indexPath) as! TimelogCell
            cell.timelog = timelogs[indexPath.row]
            cell.jobColorView.color = selectedJob.color.getColor
            cell.jobColorView.setNeedsDisplay()
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("JobsListCell", forIndexPath: indexPath) as! JobsListCell
        
            if jobsList.count == 0 {
                isJobListEmpty == true
                cell.jobNameLabel.text = "Add a job"
                cell.jobNameLabel.textColor = UIColor.blueColor()
                cell.jobPositionLabel.text = ""
                cell.jobColorView.hidden = true
            } else {
                cell.jobNameLabel.textColor = UIColor.blackColor()
                cell.job = selectedJob
                cell.jobColorView.hidden = false
                cell.jobColorView.setNeedsDisplay()
            }
            return cell
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == shiftTableView {
            return timelogs.count
        } else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel.textColor = UIColor.blackColor()
        header.textLabel.frame = header.frame
        header.textLabel.textAlignment = NSTextAlignment.Justified
        
        if tableView == shiftTableView {
            header.textLabel.text = "Entries for the shift"
            if timelogs.count == 0 {
                header.textLabel.hidden = true
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == shiftTableView {
            return 35
        } else {
            return 10
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if tableView == shiftTableView {
            selectedTimelog = timelogs[indexPath.row] // send up actual
            selectedRowIndex = indexPath.row
            
            if (indexPath.row) == 0 {
                hasMinDate = false // user select CLOCKIN so noMinDate
            } else {
                hasMinDate = true
                self.previousTimelog = timelogs[indexPath.row - 1]
            }
            
            if (timelogs.count - indexPath.row - 1) == 0 {
                hasMaxDate = false //user select last TIMELOD so noMaxDat is sent, and will use NSDATE instead
            } else {
                hasMaxDate = true
                self.nextTimelog = timelogs[indexPath.row + 1]
            }
            
            self.performSegueWithIdentifier("showDetails", sender: tableView.cellForRowAtIndexPath(indexPath))
        } else {
            if isJobListEmpty {
                let addJobStoryboard: UIStoryboard = UIStoryboard(name: "AddJobStoryboard", bundle: nil)
                let addJobsVC: AddJobTableViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("AddJobTableViewController") as! AddJobTableViewController
                self.navigationController?.pushViewController(addJobsVC, animated: true)
            } else {
                let addJobStoryboard: UIStoryboard = UIStoryboard(name: "CalendarStoryboard", bundle: nil)
                let jobsListVC: JobsListTableViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("JobsListTableViewController")
                    as! JobsListTableViewController
                jobsListVC.previousSelection = self.selectedJob
                jobsListVC.source = "clockin"
                self.navigationController?.pushViewController(jobsListVC, animated: true)
            }
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if tableView == shiftTableView {
            return true
        } else {
            return false
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            if indexPath.row == 0 {
                let alert: UIAlertController = UIAlertController(title: "Warning!",
                    message: "This will delete the entire shift.",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
                    
                    self.clearShift()
                    self.dataManager.delete(self.currentWorkedShift)
                    self.checkAndRunStates()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            } else if indexPath.row == (timelogs.count-1) {
                dataManager.delete(timelogs[indexPath.row])
                timelogs.removeAtIndex(indexPath.row)
                shiftTableView.deleteRowsAtIndexPaths([indexPath],  withRowAnimation: .Fade)
                self.checkAndRunStates()
                // TODO: better show animation of delete. tableView.reloadData() is needed to udate header
            } else {
                let alert: UIAlertController = UIAlertController(title: "Warning!",
                    message: "This will also delete all following entries.",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
                    for timelogNumber in (indexPath.row)...(self.timelogs.count-1) {
                        self.dataManager.delete(self.timelogs[indexPath.row])
                        self.timelogs.removeAtIndex(indexPath.row)
                        self.shiftTableView.deleteRowsAtIndexPaths([indexPath],  withRowAnimation: .Fade)
                    }
                    self.checkAndRunStates()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
}
