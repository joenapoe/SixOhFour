
//  ClockInViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 6/26/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//


import UIKit
import CoreData


class ClockInViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var saveOption: UILabel!
    @IBOutlet weak var workTitleLabel: UILabel!
    @IBOutlet weak var workTimeLabel: UILabel!
    @IBOutlet weak var breakTitleLabel: UILabel!
    @IBOutlet weak var breakTimeLabel: UILabel!
    @IBOutlet weak var editBreakInstruction: UILabel!
    
    @IBOutlet weak var jobColorDisplay: JobColorView!
    @IBOutlet weak var jobTitleDisplayButton: UIButton!
    @IBOutlet weak var jobTitleDisplayLabel: UILabel!
    @IBOutlet var positionLabel: UILabel!
    @IBOutlet weak var lapsTableView: UITableView!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var breakButton: UIButton!
    @IBOutlet weak var editBreakButton: UIButton!
    @IBOutlet var incompleteFolderButton: UIBarButtonItem!
    @IBOutlet var addShiftButton: UIBarButtonItem!
    
    var timer = NSTimer()
    
    var minutes: Int = 0
    var seconds: Int = 0
    var hours: Int = 0
        
    var breakTimer = NSTimer()
    var breakMinutes: Int = 0
    var breakSeconds: Int = 0
    var breakHours: Int = 0
    
    var breakMinutesSet: Int = 30
    var breakSecondsSet: Int = 0
    var breakHoursSet: Int = 0
    
    var breakMinutesChange: Int = 0
    var breakHoursChange: Int = 0
    
    var breakTimerOver = NSTimer()
    
    var workWatchString: String = ""
    var breakWatchString: String = ""
    
    var flow: String = "Idle"
    var breakCount: Int = 0
    
    var jobListEmpty = true

    //Variables for Segue: "showDetails"
    var nItemClockIn : Timelog!
    var nItemClockInPrevious : Timelog!
    var nItemClockInNext : Timelog!
    var selectedJob : Job!
    var noMinDate: Bool = false
    var noMaxDate: Bool = false
    
    var timelogList = [Timelog]()
    var timelogTimestamp: [NSDate] = []
    var timelogDescription: [String] = []
    
    var totalBreaktime : Double = 0.0
    
    var selectedRowIndex: Int = -1
    var elapsedTime : Int = 0
    var duration : Double = 0.0
    
    var currentWorkedShift : WorkedShift!
    
    var dataManager = DataManager()
    
    var openShiftsCIs = [Timelog]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.lapsTableView.rowHeight = 30.0
        workTitleLabel.text = " "
        workTimeLabel.text = "00:00:00"
        breakButton.enabled = false
        breakTitleLabel.hidden = true
        breakTimeLabel.hidden = true
        editBreakInstruction.hidden = true
        editBreakButton.enabled = false
        saveOption.hidden = true
        saveOption.textColor = UIColor.blueColor()

    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(true)
        
        if jobListEmpty {
            startStopButton.enabled = false
            workTimeLabel.textColor = UIColor.grayColor()
        }
        
        let jobsList = dataManager.fetch("Job") as! [Job]

        if selectedJob == nil { // NOTE: SELECTS THE FIRST JOB WHEN APP IS LOADED
            if jobsList.count > 0 {
                //Fetches the first jobs
                var firstJob = jobsList[0]
                jobTitleDisplayLabel.text = firstJob.company.name
                jobTitleDisplayLabel.textColor = UIColor.blackColor()
                positionLabel.text = firstJob.position
                jobColorDisplay.hidden = false
                jobColorDisplay.color = firstJob.color.getColor
                jobListEmpty = false
                if flow == "Idle" {
                    startStopButton.enabled = true
                }
                selectedJob = jobsList[0]
            } else if jobsList.count == 0 { // NOTE: No Jobs exist
                jobTitleDisplayLabel.text = "Add a Job"
                jobTitleDisplayLabel.textColor = UIColor.blueColor()
                positionLabel.text = ""
                jobColorDisplay.hidden = true
                addShiftButton.enabled = false
            }
        } else {
            jobTitleDisplayLabel.text = selectedJob.company.name
            jobColorDisplay.color = selectedJob.color.getColor
            positionLabel.text = selectedJob.position
        }
        
        if flow == "clockedOut" {
            breakButton.setTitle("Reset", forState: UIControlState.Normal)
            currentWorkedShift.sumUpDuration()
            
        } else if flow == "onBreak" {
            //while your on break you can see the duration adjustments
            currentWorkedShift.sumUpDuration()
        }
        updateTable()

        checkForIncomplete()
    
    }
    
    //MARK: IBActions:
    //2 buttons control clockin,clockout,start break, end break, reset
    
    @IBAction func startStop(sender: AnyObject) {
        
        //CLOCK IN -- Begin  the shift
        if flow == "Idle" {
            flow = "onTheClock"
            
            workTitleLabel.text = "Time you've worked"

            startStopButton.setTitle("Clock Out", forState: UIControlState.Normal)
            breakButton.setTitle("Start Break", forState: UIControlState.Normal)

            breakButton.enabled = true
            
            timelogDescription.append("Clocked In")
            appendToTimeTableView()
            saveToCoreData()
            
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runAndUpdateWorkTimer"), userInfo: nil, repeats: true)
            
        } else if flow == "onTheClock" {
            //CLOCK OUT
            flow = "clockedOut"
            
            workTitleLabel.text = "Total time you've worked"
            timelogDescription.append("Clocked Out")
            appendToTimeTableView()
            saveToCoreData()
            timer.invalidate()
            
            startStopButton.setTitle("", forState: UIControlState.Normal)
            startStopButton.enabled = false
            breakButton.setTitle("Reset", forState: UIControlState.Normal)
            saveOption.hidden = false
            
            currentWorkedShift.sumUpDuration()
            saveWorkedShiftToJob()
            
        }
        
    }

    @IBAction func lapReset(sender: AnyObject) {
        
        //STARTED BREAK
        if flow == "onTheClock" {
            flow = "onBreak"
            breakCount++
            
            breakTimeLabel.hidden = false
            breakTitleLabel.hidden = false
            editBreakInstruction.hidden = false
            editBreakButton.enabled = true
            
            breakReset ()
            displayBreaktime ()
            
            breakTitleLabel.textColor = UIColor.blueColor()
            breakTimeLabel.textColor = UIColor.blueColor()
            editBreakInstruction.textColor = UIColor.blueColor()
            
            
            breakTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runBreakTimer"), userInfo: nil, repeats: true)
            
            timer.invalidate()

            startStopButton.enabled = false
            breakButton.setTitle("End Break", forState: UIControlState.Normal)
            
            if breakCount < 2 {
                timelogDescription.append("Started Break")
            } else {
                timelogDescription.append("Started Break #\(breakCount)")
            }
            
            appendToTimeTableView()
            saveToCoreData()
            
            
        } else if flow == "onBreak" {  //ENDED BREAK

            flow = "onTheClock"
            
            breakTimerOver.invalidate()
            
            breakTimeLabel.hidden = true
            breakTitleLabel.hidden = true
            editBreakInstruction.hidden = true
            editBreakButton.enabled = false
            
            breakReset()
            
            breakTimer.invalidate()
            
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runAndUpdateWorkTimer"), userInfo: nil, repeats: true)

            startStopButton.enabled = true
            breakButton.setTitle("Start Break", forState: UIControlState.Normal)
            
            
            if breakCount == 1 {
                timelogDescription.append("Ended Break")
            } else {
                timelogDescription.append("Ended Break #\(breakCount)")
            }
            
            appendToTimeTableView()
            saveToCoreData()

            currentWorkedShift.sumUpDuration()

            
            breakTimeLabel.text = "0\(breakHours):\(breakMinutes):0\(breakSeconds)"
            
            //RESET and SAVE (WorkedShift to current JOB that is picked)
        } else if flow == "clockedOut" {
            
            startStopButton.setTitle("Clock In", forState: UIControlState.Normal)
            breakButton.setTitle("Start Break", forState: UIControlState.Normal)
            breakButton.enabled = false
            
            saveWorkedShiftToJob()
            
            //clears all the laps when clicked reset
            timelogTimestamp.removeAll(keepCapacity: false)
            timelogDescription.removeAll(keepCapacity: false)
            timelogList = []
            
            updateTable()
            
            breakCount = 0
            
            workTitleLabel.text = " "
            workTimeLabel.text = "00:00:00"
            breakTimeLabel.text = " "
            breakTitleLabel.text = " "
            
            duration = 0
            totalBreaktime = 0
            
            startStopButton.enabled = true
            
            saveOption.hidden = true
            
            //Wait to reset to idle - this is bc viewdidappear for duration calc.
            flow = "Idle"
        }
    }
    
    @IBAction func selectJobButton(sender: AnyObject) {
        if jobListEmpty {
            let addJobStoryboard: UIStoryboard = UIStoryboard(name: "AddJobStoryboard", bundle: nil)
            let addJobsVC: AddJobTableViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("AddJobTableViewController") as! AddJobTableViewController
            
            self.navigationController?.pushViewController(addJobsVC, animated: true)
            
            
        } else {
            let addJobStoryboard: UIStoryboard = UIStoryboard(name: "CalendarStoryboard", bundle: nil)
            let jobsListVC: JobsListTableViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("JobsListTableViewController")
                as! JobsListTableViewController
            
            jobsListVC.previousSelection = self.selectedJob.company.name
            jobsListVC.source = "clockin"
            
            self.navigationController?.pushViewController(jobsListVC, animated: true)
        }
    }
    
    //MARK: Functions
    
    func updateTable() {
        lapsTableView.reloadData()
        jobColorDisplay.setNeedsDisplay()
    }
    
    func saveToCoreData(){
    
        // NOTE: New time log
        let newTimelog = dataManager.addItem("Timelog") as! Timelog
        newTimelog.setValue("" + timelogDescription.last!, forKey: "type")
        newTimelog.time = NSDate()
        newTimelog.setValue("", forKey: "comment")

        // NOTE: New worked shift if Clocked In
        if timelogDescription.last == "Clocked In" {
            let newWorkedShift = dataManager.addItem("WorkedShift") as! WorkedShift
            currentWorkedShift = newWorkedShift
            currentWorkedShift.status = 2 // 2=running, 1=incomplete, 0=complete
            newTimelog.workedShift = currentWorkedShift
        } else {
            newTimelog.workedShift = currentWorkedShift
            if timelogDescription.last == "Clocked Out"{
                currentWorkedShift.status = 0 // 2=running, 1=incomplete, 0=complete
            }
        }
        timelogList.append(newTimelog)
        
        currentWorkedShift.sumUpDuration()
        saveWorkedShiftToJob()
    }
    
    func saveWorkedShiftToJob() {
        var predicateJob = NSPredicate(format: "company.name == %@ && position == %@" , selectedJob.company.name, selectedJob.position)
        let assignedJob = dataManager.fetch("Job", predicate: predicateJob) as! [Job]
        currentWorkedShift.job = assignedJob[0]
        println("assignedJob = \(assignedJob[0].objectID)")
        
        
        let allTimelogs = dataManager.fetch("Timelog") as! [Timelog]
        let allWorkedShifts = dataManager.fetch("WorkedShift") as! [WorkedShift]
        let allJobs = dataManager.fetch("Job") as! [Job]

        dataManager.save()

        // TEST
        println("Total \(allTimelogs.count) timeLogs")
        println("Total \(allWorkedShifts.count) workedShifts")
        println("Total \(allJobs.count) jobs")
        for i in 0...(allJobs.count-1) {
            var currentJob = allJobs[i]
            println("1 of the jobs has \(currentJob.workedShifts.count) workedShifts")
        }
        
    }
    
    func appendToTimeTableView() {
        
        timelogTimestamp.append(NSDate())
        updateTable()
        
        var indexPathScroll = NSIndexPath(forRow: timelogList.count, inSection: 0)
        self.lapsTableView.scrollToRowAtIndexPath(indexPathScroll, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        
    }
    
// DURATION FUNCTIONS
    
    func runAndUpdateWorkTimer() {
        runWorkTimer()
        updateWorkTimerLabel()
    }
    
    func runWorkTimer() {
        //currently calculated since clock in and subtracting the total breaktime duration
        let elapsedTimeInterval = NSDate().timeIntervalSinceDate(timelogTimestamp.last!)
        
        elapsedTime = Int(elapsedTimeInterval) + Int(currentWorkedShift.duration)

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
        
        workWatchString  = getWatchString(elapsedSecond, minutes: elapsedMinute, hours: elapsedHour)
        workTimeLabel.text = workWatchString
    }
    
    func runBreakTimer() {
        
        breakWatchString  = getWatchString(breakSeconds, minutes: breakMinutes, hours: breakHours)
        breakTimeLabel.text = breakWatchString
        
        if breakSeconds > 0 {
            breakSeconds--
        } else if breakSeconds == 0 && breakMinutes > 0 {
            breakMinutes--
            breakSeconds = 59
        } else if breakMinutes == 0 && breakHours > 0 {
            breakHours--
            breakMinutes = 59
        } else {
            
            notifyBreakOver ()
            breakTimer.invalidate()
            breakTimerOver = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runBreakTimerOver"), userInfo: nil, repeats: true)
        }
    }
    
    func runBreakTimerOver() {
        breakTitleLabel.textColor = UIColor.redColor()
        breakTitleLabel.text = "You are running over your breaktime"
        breakTimeLabel.textColor = UIColor.redColor()
        editBreakInstruction.textColor = UIColor.redColor()
        editBreakButton.enabled = false
        editBreakInstruction.hidden = true
        
        breakSeconds += 1
        
        if breakSeconds == 60 {
            breakMinutes += 1
            breakSeconds = 0
        }
        if breakMinutes == 60 {
            breakHours += 1
            breakMinutes = 0
        }
        breakWatchString  = getWatchString(breakSeconds, minutes: breakMinutes, hours: breakHours)
        breakTimeLabel.text = breakWatchString
    }
    
    func displayBreaktime () {
        //Display Break time instantly
        breakWatchString  = getWatchString(breakSeconds, minutes: breakMinutes, hours: breakHours)
        breakTimeLabel.text = breakWatchString
        
        if breakHoursSet > 0 {
            breakTitleLabel.text = "Your break is set to \(breakHoursSet) hr and \(breakMinutesSet) min"
        } else if breakHoursSet == 0 && breakMinutesSet > 0 {
            breakTitleLabel.text = "Your break is set to \(breakMinutesSet) min"
        } else if breakMinutesSet == 0 && breakSecondsSet > 0 {
            breakTitleLabel.text = "Your break is set to \(breakSecondsSet) sec"
        }
    }
    
    func breakReset () {
        breakMinutes = breakMinutesSet
        breakSeconds = breakSecondsSet
        breakHours = breakHoursSet
    }
    
    
    func notifyBreakOver() {
        //Notifications outside the App (Home screen and Lock Screen)
        var localNotification: UILocalNotification = UILocalNotification()
        localNotification.alertAction = "PUCHIE"
        localNotification.alertBody = "Your breaktime is over!"
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 1) //seconds from now
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        
        //Notifications insdie the App (Home screen and Lock Screen)
        let alert: UIAlertController = UIAlertController(title: "Breaktime is over!",
            message: "Please choose from the following:",
            preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Clock In", style: .Default, handler: {
            action in self.lapReset(true)
        }))
        alert.addAction(UIAlertAction(title: "Add 5 Minutes", style: .Default, handler: { action in
            
            self.breakTimerOver.invalidate()
            self.breakMinutes = 5
            self.breakSeconds = 0
            self.breakHours = 0
            self.breakTimeLabel.textColor = UIColor.blueColor()
            self.editBreakInstruction.hidden = true
            self.editBreakButton.enabled = false
            self.breakTitleLabel.textColor = UIColor.blueColor()
            self.breakTitleLabel.text = "You've extended your break by 5 minutes"
            self.breakTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runBreakTimer"), userInfo: nil, repeats: true)
            
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func getWatchString(seconds: Int, minutes: Int, hours: Int) -> String {
        let secondsString = String.secondsString(seconds)
        let minutesString = String.minutesString(minutes)
        let hoursString = String.hoursString(hours)
        
        return "\(hoursString):\(minutesString):\(secondsString)"
    }
    
    func checkForIncomplete() {
        let predicateOpenWS = NSPredicate(format: "workedShift.status == 1")
        let predicateCI = NSPredicate(format: "type == %@" , "Clocked In")
        let compoundPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([predicateCI, predicateOpenWS])
        
        var sortNSDATE = NSSortDescriptor(key: "time", ascending: true)
        
        openShiftsCIs = dataManager.fetch("Timelog", predicate: compoundPredicate, sortDescriptors: [sortNSDATE] ) as! [Timelog]
        
        println("openShiftsCIs.count \(openShiftsCIs.count)")
        if openShiftsCIs.count == 0 {
            incompleteFolderButton.enabled = false
        } else {
            incompleteFolderButton.enabled = true
        }
    }
    
// MARK: Table View functions
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("TimelogCell", forIndexPath: indexPath) as! TimelogCell


        cell.timelog = timelogList[indexPath.row]
        cell.jobColorView.color = selectedJob.color.getColor
        cell.jobColorView.setNeedsDisplay()
        
        return cell
        
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timelogTimestamp.count
    }
    

    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView

        header.textLabel.textColor = UIColor.blackColor()
//        header.textLabel.font = UIFont.boldSystemFontOfSize(18)
        header.textLabel.frame = header.frame
        header.textLabel.textAlignment = NSTextAlignment.Justified
        header.textLabel.text = "Entries for the shift"

        if timelogList.count == 0 {
            header.textLabel.hidden = true
        } else {
            header.textLabel.hidden = false
        }
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        nItemClockIn = timelogList[indexPath.row] // send up actual
        selectedRowIndex = indexPath.row
        
        if (indexPath.row) == 0 {
            noMinDate = true // user select CLOCKIN so noMinDate
        } else {
            noMinDate = false
            self.nItemClockInPrevious = timelogList[indexPath.row - 1]
        }
        
        if (timelogList.count - indexPath.row - 1) == 0 {
            noMaxDate = true //user select last TIMELOD so noMaxDat is sent, and will use NSDATE instead
        } else {
            noMaxDate = false
            self.nItemClockInNext = timelogList[indexPath.row + 1]
        }
        
        self.performSegueWithIdentifier("showDetails", sender: tableView.cellForRowAtIndexPath(indexPath))
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
// MARK: Segues (Show)
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {

        if segue.identifier == "editBreaktimeSegue" {
            
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.Plain, target: nil, action: nil)
            
            let destinationVC = segue.destinationViewController as! SetBreakTimeViewController
            destinationVC.navigationItem.title = "Set Breaktime"
            destinationVC.hidesBottomBarWhenPushed = true;
            
            //Passes 2 data variables
            destinationVC.breakMinutes = self.breakMinutesSet
            destinationVC.breakHours = self.breakHoursSet
            //Pass same 2 variable to get the delta
            destinationVC.breakMinutesSetIntial = self.breakMinutesSet
            destinationVC.breakHoursSetIntial = self.breakHoursSet
        }
        
        if segue.identifier == "showDetails" {
            
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Cancel", style:.Plain, target: nil, action: nil)

            let destinationVC = segue.destinationViewController as! DetailsTableViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            
            println(nItemClockIn)
            
            destinationVC.nItem = self.nItemClockIn
            destinationVC.nItemPrevious = self.nItemClockInPrevious
            destinationVC.nItemNext = self.nItemClockInNext
            destinationVC.noMinDate = self.noMinDate
            destinationVC.noMaxDate = self.noMaxDate
            destinationVC.selectedJob = self.selectedJob
        }
        
        if segue.identifier == "showIncompleteShifts" {
            let destinationVC = segue.destinationViewController as! IncompleteShiftsTableViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.Plain, target: nil, action: nil)

        }

        if segue.identifier == "showAddShift" {
            let destinationVC = segue.destinationViewController as! AddShiftViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Cancel", style:.Plain, target: nil, action: nil)
            destinationVC.selectedJob = selectedJob
        }
        
    }
    
// MARK: Segues (Unwind) = Getting data from sourceVC
    
    @IBAction func unwindFromJobsListTableViewControllerToClockIn (segue: UIStoryboardSegue) {

        let sourceVC = segue.sourceViewController as! JobsListTableViewController
        
        println("sourceVC.selectedJob = \(sourceVC.selectedJob)")
        println("selectedJob = \(selectedJob)")
        selectedJob = sourceVC.selectedJob

        if timelogList.count > 0 {
            currentWorkedShift.job = selectedJob
            println("currentWorkedShift.job.objectID = \(currentWorkedShift.job.objectID)")
        }
        updateTable()
    }
    
    // Same unwind func in 2 differect VCs, control each exit independently
    @IBAction func unwindSaveDetailsTVC (segue: UIStoryboardSegue) {
        //by hitting the SAVE button
        let sourceVC = segue.sourceViewController as! DetailsTableViewController
        timelogTimestamp[selectedRowIndex] = sourceVC.nItem.time

        currentWorkedShift.sumUpDuration()
        
        elapsedTime = Int(currentWorkedShift.duration)
        updateWorkTimerLabel()
        
        selectedJob = sourceVC.selectedJob
        
        if sourceVC.selectedJob != nil {
            selectedJob = sourceVC.selectedJob
            jobColorDisplay.color = selectedJob.color.getColor
        }
        
        if timelogList != [] {
            saveWorkedShiftToJob()
        }
        
        saveWorkedShiftToJob()
        updateTable()
    }
    
    @IBAction func unwindCancelDetailsTVC (segue: UIStoryboardSegue) {
        //by hitting the CANCEL button
        //Nothing saved!
    }
    
    @IBAction func unwindAddShift (segue: UIStoryboardSegue) {
        //by hitting the CANCEL button
        //Nothing saved!
    }
    
    @IBAction func unwindAddShiftSave (segue: UIStoryboardSegue) {
        //by hitting the CANCEL button
        //Nothing saved!
    }
    
    @IBAction func unwindFromSetBreakTimeViewController (segue: UIStoryboardSegue) {
        
        let sourceVC = segue.sourceViewController as! SetBreakTimeViewController
        
        if((sourceVC.breakHours) >= 0 ) {
            breakHoursSet = sourceVC.breakHours
            println("breakHoursSet from SetBreaktime = \(breakHours)")
            breakHoursChange = ( sourceVC.breakHours - sourceVC.breakHoursSetIntial )
            println("breakHoursChange = \(breakHoursChange)")
            
            breakHours =  (breakHours + breakHoursChange)
            
            if breakHours < 0 {
                breakHours = 0
                breakMinutes = breakMinutes - 59
            }
        }
        if((sourceVC.breakMinutes) >= 0 ) {
            breakMinutesSet = sourceVC.breakMinutes
            println("breakMinutesSet from SetBreaktime = \(breakMinutes)")
            breakMinutesChange = ( sourceVC.breakMinutes - sourceVC.breakMinutesSetIntial )
            println("breakMinutesChange = \(breakMinutesChange)")
            breakMinutes = (breakMinutes + breakMinutesChange)
            
            if breakMinutes < 0 {
                breakMinutes = 0
                breakSeconds = breakSeconds - 59
                
                if breakSeconds < 0 {
                    breakSeconds = 0
                }
            }
        }
        displayBreaktime ()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
