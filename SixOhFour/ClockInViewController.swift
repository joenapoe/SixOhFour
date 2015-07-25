
//  ClockInViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 6/26/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class ClockInViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var workTitleLabel: UILabel!
    @IBOutlet weak var workTimeLabel: UILabel!
    @IBOutlet weak var breakTitleLabel: UILabel!
    @IBOutlet weak var breakTimeLabel: UILabel!
    @IBOutlet weak var editBreakInstruction: UILabel!
    
    @IBOutlet weak var jobColorDisplay: JobColorView!
    @IBOutlet weak var jobTitleDisplayButton: UIButton!
    @IBOutlet weak var jobTitleDisplayLabel: UILabel!
    @IBOutlet weak var lapsTableView: UITableView!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var breakButton: UIButton!
    @IBOutlet weak var editBreakButton: UIButton!
    
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
    
    var stopWatchString: String = ""
    var breakWatchString: String = ""
    
    var timelogTimestamp: [String] = []
    var timelogDescription: [String] = []
    
    var timelogFlow: Int = 0
    var breakCount: Int = 0
    
    var jobListEmpty = true
    var selectedJobIndex: Int = -1
    var noMinDate: Bool = false
    var noMaxDate: Bool = false

    var nItemClockIn : TimeLogs!
    var nItemClockInPrevious : TimeLogs!
    var nItemClockInNext : TimeLogs!

    
    var timelogsList = [TimeLogs]()
    
    var frc : NSFetchedResultsController = NSFetchedResultsController()
    
    let context : NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.lapsTableView.rowHeight = 30.0
        workTitleLabel.text = " "
        workTimeLabel.text = "00:00:00"
        breakButton.enabled = false
        breakTitleLabel.hidden = true
        breakTimeLabel.text = " "
        editBreakInstruction.hidden = true
        editBreakButton.enabled = false
    
        
        frc = getFetchedResultsController()
        frc.delegate = self
        frc.performFetch(nil)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        if jobListEmpty {
            startStopButton.enabled = false
            workTimeLabel.textColor = UIColor.grayColor()
        }
        
        displayBreaktime ()
        
        //SELECTS THE FIRST JOB WHEN APP IS LOADED
        if selectedJobIndex == -1 {
            // Fetch jobs list to keep refreshing changes
            var appDel:AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
            var context:NSManagedObjectContext = appDel.managedObjectContext!
            
            var request = NSFetchRequest(entityName: "Jobs")
            request.returnsObjectsAsFaults = false ;
            
            var results:NSArray = context.executeFetchRequest(request, error: nil)!
            
            if results.count > 0 {
                //Fetches the first jobs
                var firstJob = results[0] as! Jobs
                jobTitleDisplayLabel.text = firstJob.jobName
                jobColorDisplay.color = firstJob.getJobColor()
                jobTitleDisplayLabel.textColor = UIColor.blackColor()
                jobColorDisplay.hidden = false
                
                jobListEmpty = false
                jobTitleDisplayLabel.textColor = UIColor.blackColor()
                
                if timelogFlow == 0 {
                    startStopButton.enabled = true
                }
                
            } else {
                jobTitleDisplayLabel.text = "Add a Job"
                jobTitleDisplayLabel.textColor = UIColor.blueColor()
                jobColorDisplay.hidden = true
            }
            
        } else {
            var appDel:AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
            var context:NSManagedObjectContext = appDel.managedObjectContext!
            
            var request = NSFetchRequest(entityName: "Jobs")
            request.returnsObjectsAsFaults = false ;
            
            var results:NSArray = context.executeFetchRequest(request, error: nil)!
        
            var arrayOfJobs = [Jobs]()
            arrayOfJobs = results as! [Jobs]
            jobTitleDisplayLabel.text = arrayOfJobs[selectedJobIndex].jobName
            jobColorDisplay.color = arrayOfJobs[selectedJobIndex].getJobColor()
        }
        
        if timelogFlow == 2 {
            breakButton.setTitle("Save shift for \(jobTitleDisplayLabel.text!)", forState: UIControlState.Normal)
        }

        lapsTableView.reloadData()
    
    }
    
//MARK: IBActions:
//2 buttons control clockin,clockout,start break, end break, reset

    @IBAction func startStop(sender: AnyObject) {
        
        //CLOCK IN
        
        //Begin Shift
        if timelogFlow == 0 {
            workTitleLabel.text = "Time you've worked"
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runWorkTimer"), userInfo: nil, repeats: true)
            
            startStopButton.setTitle("Clock Out", forState: UIControlState.Normal)
            breakButton.setTitle("Start Break", forState: UIControlState.Normal)
            
            breakButton.enabled = true
            
            timelogDescription.append("Clocked In")
            appendToTimeTableView()
            saveToCoreDate()
  
            timelogFlow = 1
        } else {
            
        //CLOCK OUT
            workTitleLabel.text = "Total time you've worked"
            timelogDescription.append("Clocked Out")
            appendToTimeTableView()
            saveToCoreDate()
            
            timer.invalidate()
            
            startStopButton.setTitle("", forState: UIControlState.Normal)
            startStopButton.enabled = false
            breakButton.setTitle("Save shift for \(jobTitleDisplayLabel.text!)", forState: UIControlState.Normal)
            
            timelogFlow = 2

        }
        
    }
    
    

    
    @IBAction func lapReset(sender: AnyObject) {
    
        //STARTED BREAK
        if timelogFlow == 1 {
            
            breakTimeLabel.hidden = false
            breakTitleLabel.hidden = false
            editBreakInstruction.hidden = false
            editBreakButton.enabled = true

            breakReset ()

            //Display Break time instantly
            let secondsStringBreak = breakSeconds > 9 ? "\(breakSeconds)" : "0\(breakSeconds)"
            let minutesStringBreak = breakMinutes > 9 ? "\(breakMinutes)" : "0\(breakMinutes)"
            let hoursStringBreak = breakHours > 9 ? "\(breakHours)" : "0\(breakHours)"
            breakWatchString  = "\(hoursStringBreak):\(minutesStringBreak):\(secondsStringBreak)"
            breakTimeLabel.text = breakWatchString
            
            breakCount++
            
            displayBreaktime ()

            
            breakTitleLabel.textColor = UIColor.blueColor()
            breakTimeLabel.textColor = UIColor.blueColor()
            editBreakInstruction.textColor = UIColor.blueColor()
            
            timer.invalidate()
            
            breakTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runBreakTimer"), userInfo: nil, repeats: true)
            
            startStopButton.enabled = false
            breakButton.setTitle("End Break", forState: UIControlState.Normal)
            
            if breakCount == 1 {
            timelogDescription.append("Started Break")
            } else {
            timelogDescription.append("Started Break #\(breakCount)")
            }
            
            appendToTimeTableView()
            saveToCoreDate()

            timelogFlow = 3

            
        //ENDED BREAK
        } else if timelogFlow == 3 {
            
            breakTimerOver.invalidate()
            
            breakTimeLabel.hidden = true
            breakTitleLabel.hidden = true
            editBreakInstruction.hidden = true
            editBreakButton.enabled = false

            breakReset()
            
            breakTimer.invalidate()
            
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runWorkTimer"), userInfo: nil, repeats: true)

            
            startStopButton.enabled = true
            breakButton.setTitle("Start Break", forState: UIControlState.Normal)
            
            if breakCount == 1 {
                timelogDescription.append("Ended Break")
            } else {
                timelogDescription.append("Ended Break #\(breakCount)")
            }
    
            appendToTimeTableView()
            saveToCoreDate()
            
            timelogFlow = 1
            
            breakTimeLabel.text = "0\(breakHours):\(breakMinutes):0\(breakSeconds)"
            
        //RESET and SAVE (TIMELOGS UNDER 1 JOB NAME)
        } else {
            
            startStopButton.setTitle("Clock In", forState: UIControlState.Normal)
            breakButton.setTitle("Start Break", forState: UIControlState.Normal)
            breakButton.enabled = false
            
            
            
            
            
            
            
//            //NEED TO FIND A WAY TO SAVE THE TIMESLOGS TO ONE SHIFT!
//            let shiftEnt = NSEntityDescription.entityForName("Shifts", inManagedObjectContext: context)
//            var newShift = Shifts(entity: shiftEnt!, insertIntoManagedObjectContext: context)
//
//            // Add multiple TIMELOGS to SHIFT
//            newShift.setValue(NSSet setWithObject:TimeLogs, forKey: "Shifts")
//            
//            // Save Managed Object Context
//            NSError *error = nil;
//            if (![newPerson.managedObjectContext save:&error]) {
//                NSLog(@"Unable to save managed object context.");
//                NSLog(@"%@, %@", error, error.localizedDescription);
//            }
            

            
            
            
            
            
            
//            newShift.setValue("" + timelogDescription.last!, forKey: "timelogTitle")
            
            
            
            
            
            
            //clears all the laps when clicked reset
            timelogTimestamp.removeAll(keepCapacity: false)
            timelogDescription.removeAll(keepCapacity: false)
            timelogsList = []
            
            lapsTableView.reloadData()
            
            minutes = 0
            seconds = 0
            hours = 0
            
            breakCount = 0

            workTitleLabel.text = " "
            workTimeLabel.text = "00:00:00"
            breakTimeLabel.text = " "
            breakTitleLabel.text = " "

            startStopButton.enabled = true
            
            timelogFlow = 0
        }
        
        
    }
    
    @IBAction func selectJobButton(sender: AnyObject) {
        if jobListEmpty {
            let addJobStoryboard: UIStoryboard = UIStoryboard(name: "AddJobStoryboard", bundle: nil)
            let addJobsVC: AddJobTableViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("AddJobTableViewController") as! AddJobTableViewController
                    
            self.navigationController?.pushViewController(addJobsVC, animated: true)
            
        } else {
            self.performSegueWithIdentifier("displayJobList", sender: self)
        }
    }
    
//MARK: Functions
    
//    func allTimeLogsFetchRequest() -> NSFetchRequest {
//        
//        var fetchRequest = NSFetchRequest(entityName: "TimeLogs")
//        //let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
//        
//        fetchRequest.predicate = nil
//        //fetchRequest.sortDescriptors = [sortDescriptor]
//        //fetchRequest.fetchBatchSize = 20
//        
//        return fetchRequest
//    }
    
    func TimeLogsFetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: "TimeLogs")
        let sortDescriptor = NSSortDescriptor(key: "timelogTitle", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return fetchRequest
    }
    
    func getFetchedResultsController() -> NSFetchedResultsController {
        frc = NSFetchedResultsController(fetchRequest: TimeLogsFetchRequest(), managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }
    
    func saveToCoreDate(){
        
        var appDel:AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
        var context:NSManagedObjectContext = appDel.managedObjectContext!
        
        let ent = NSEntityDescription.entityForName("TimeLogs", inManagedObjectContext: context)
        var newTimeLogs = TimeLogs(entity: ent!, insertIntoManagedObjectContext: context)
        
        newTimeLogs.setValue("" + timelogDescription.last!, forKey: "timelogTitle")
        newTimeLogs.setValue("" + timelogTimestamp.last!, forKey: "timelogTimestamp")
        newTimeLogs.setValue("placeholderShifts", forKey: "timelogJob")
        newTimeLogs.setValue("", forKey: "timelogComment")
        
        timelogsList.append(newTimeLogs)
        
        context.save(nil)

        println(newTimeLogs)
        
        println(timelogDescription)
    }
    
    func appendToTimeTableView() {
        var timeStampAll = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .MediumStyle)
        timelogTimestamp.append(timeStampAll)
        lapsTableView.reloadData()
        
        var indexPathScroll = NSIndexPath(forRow: timelogsList.count, inSection: 0)
        self.lapsTableView.scrollToRowAtIndexPath(indexPathScroll, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        
    }

    
    func runBreakTimer() {

        let secondsStringBreak = breakSeconds > 9 ? "\(breakSeconds)" : "0\(breakSeconds)"
        let minutesStringBreak = breakMinutes > 9 ? "\(breakMinutes)" : "0\(breakMinutes)"
        let hoursStringBreak = breakHours > 9 ? "\(breakHours)" : "0\(breakHours)"
    
        breakWatchString  = "\(hoursStringBreak):\(minutesStringBreak):\(secondsStringBreak)"
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
            
            //Notifications outside the App (Home screen and Lock Screen)
            var localNotification: UILocalNotification = UILocalNotification()
            localNotification.alertAction = "PUCHIE"
            localNotification.alertBody = "Your breaktime is over!"
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.fireDate = NSDate(timeIntervalSinceNow: 1) //seconds from now
            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
            
            //Notifications insdie the App (Home screen and Lock Screen)
            let alert = UIAlertController(title: "Breaktime is over!",
                message: "Please choose from the following:",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.addAction(UIAlertAction(title: "View", style: .Default, handler: nil))
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
            
//??????????????? I dont know what this code was used for.
//          presentViewController(alert, animated: true, completion:nil)
//????????????????
            
            breakTimer.invalidate()
            
            breakTimerOver = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runBreakTimerOver"), userInfo: nil, repeats: true)
            
        }
    }
    
    //redundant code - need to combine both timers
    func runWorkTimer() {
        
        seconds += 1
        
        if seconds == 60 {
            minutes += 1
            seconds = 0
        }
        
        if minutes == 60 {
            hours += 1
            minutes = 0
        }
        
        let secondsString = seconds > 9 ? "\(seconds)" : "0\(seconds)"
        let minutesString = minutes > 9 ? "\(minutes)" : "0\(minutes)"
        let hoursString = hours > 9 ? "\(hours)" : "0\(hours)"
        
        stopWatchString  = "\(hoursString):\(minutesString):\(secondsString)"
        workTimeLabel.text = stopWatchString
        
    }

    //redundant code - need to combine both timers
    func runBreakTimerOver() {
        
        //Show time over break
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
        
        let breakSecondsString = breakSeconds > 9 ? "\(breakSeconds)" : "0\(breakSeconds)"
        let breakMinutesString = breakMinutes > 9 ? "\(breakMinutes)" : "0\(breakMinutes)"
        let breakHoursString = breakHours > 9 ? "\(breakHours)" : "0\(breakHours)"
        
        breakWatchString  = "\(breakHoursString):\(breakMinutesString):\(breakSecondsString)"
        breakTimeLabel.text = breakWatchString

    }
    
    func displayBreaktime () {
        if breakHoursSet > 0 {
            breakTitleLabel.text = "Your break is set to \(breakHoursSet) hr and \(breakMinutesSet) min"
        } else if breakHoursSet == 0 && breakMinutesSet > 0 {
            breakTitleLabel.text = "Your break is set to \(breakMinutesSet) min"
        } else if breakMinutesSet == 0 && breakSecondsSet > 0 {
            breakTitleLabel.text = "Your break is set to \(breakSecondsSet) sec"
        } else { //if breakMinutesSet == 0 && breakHoursSet == 0 {
            breakTitleLabel.text = "Minimum breaktime is 1 min"
            breakMinutesSet = 1
        }
    }
    
    func breakReset () {
        breakMinutes = breakMinutesSet
        breakSeconds = breakSecondsSet
        breakHours = breakHoursSet
    }
    
// MARK: Table View functions
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "Cell")
        
        cell.backgroundColor = self.view.backgroundColor
        
        cell.textLabel!.font = UIFont.systemFontOfSize(12.0)
        cell.detailTextLabel!.font = UIFont.systemFontOfSize(12.0)

        cell.textLabel!.text = timelogsList[indexPath.row].timelogTitle //
        cell.detailTextLabel?.text = timelogsList[indexPath.row].timelogTimestamp //if you want decesending order [timelogsList.count - indexPath.row - 1]
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timelogTimestamp.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        self.nItemClockIn = timelogsList[indexPath.row] // send up actual
        
        if (indexPath.row) == 0 {
            noMinDate = true // user select CLOCKIN so noMinDate
        } else {
            noMinDate = false
            self.nItemClockInPrevious = timelogsList[indexPath.row - 1]
        }
        
        if (timelogsList.count - indexPath.row - 1) == 0 {
            noMaxDate = true //user select last TIMELOD so noMaxDat is sent, and will use NSDATE instead
        } else {
            noMaxDate = false
            self.nItemClockInNext = timelogsList[indexPath.row + 1]
        }
        
////////////////////////////////////////////////////////////
//      DESCENDING ORDER
//        self.nItemClockIn = timelogsList[timelogsList.count - indexPath.row - 1] // send up actual
//
//        if (timelogsList.count - indexPath.row - 1) == 0 {
//            noMinDate = true // user select CLOCKIN so noMinDate
//        } else {
//            noMinDate = false
//            self.nItemClockInPrevious = timelogsList[timelogsList.count - indexPath.row - 2]
//        }
//        
//        if indexPath.row == 0 {
//            noMaxDate = true //user select last TIMELOD so noMaxDat is sent, and will use NSDATE instead
//        } else {
//            noMaxDate = false
//            self.nItemClockInNext = timelogsList[timelogsList.count - indexPath.row]
//        }
        
        println("!!!!!!!!!IN CLOCKIN timelogsList.count = \(timelogsList.count) and indexPath.row = \((indexPath.row))!!!!!!!!!!")

        self.performSegueWithIdentifier("showDetails", sender: tableView.cellForRowAtIndexPath(indexPath))
        
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
//    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        
//        if (editingStyle == UITableViewCellEditingStyle.Delete) {
//            // handle delete (by removing the data from your array and updating the tableview)
////            timelogsList.removeAtIndex(timelogsList.count - indexPath.row - 1)
////            lapsTableView.reloadData()
////            lapsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
//        }
//        
//        
//    }
    

// MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {

        //Select a Job
        if segue.identifier == "displayJobsList" {
            let destinationVC = segue.destinationViewController as! ClockInJobsPopoverViewController
            destinationVC.navigationItem.title = ""
            destinationVC.hidesBottomBarWhenPushed = true;
            //self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target: nil, action: nil)
        }
        
        //Editbreaktime
        if segue.identifier == "editBreaktimeSegue" {
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
        
        //Send Core Data to Timelog Details //place holder for JobName //waiting for shifts
        if segue.identifier == "showDetails" {
            
            let destinationVC = segue.destinationViewController as! detailsTimelogViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            
            destinationVC.nItem = self.nItemClockIn
            destinationVC.nItemPrevious = self.nItemClockInPrevious
            destinationVC.nItemNext = self.nItemClockInNext
            destinationVC.jobLabelDisplay = jobTitleDisplayLabel.text!
            destinationVC.jobColorDisplayPassed = jobColorDisplay.color
            destinationVC.noMinDate = self.noMinDate
            destinationVC.noMaxDate = self.noMaxDate

        }

    }

// MARK: Segues.Unwind = Getting data from sourceVC
    
    @IBAction func unwindFromClockInPopoverViewControllerAction (segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! ClockInJobsPopoverViewController
        
        if((sourceVC.selectedJobIndex) != nil ) {
            selectedJobIndex = sourceVC.selectedJobIndex
        }
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
    }
    
    
    @IBAction func unwindFromDetailsTimelogViewController (segue: UIStoryboardSegue) {
        
        let sourceVC = segue.sourceViewController as! detailsTimelogViewController
        
    }

// Extra: 
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

