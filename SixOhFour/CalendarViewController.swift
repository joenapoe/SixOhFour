//
//  CalendarViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 6/26/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class CalendarViewController: UIViewController {
    
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var todayLabel: UILabel!
    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var calendarView: CVCalendarView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var todayButton: UIBarButtonItem!
    var selectedDate: NSDate!
    var currentDate: NSDate!
    var monthWorkedShifts: [WorkedShift]!
    var monthSchedule: [ScheduledShift]!
    var selectedSchedule: ScheduledShift!
    var selectedWorkedShift: WorkedShift!
    
    var isMonthView = true
    var showInCalendar = ShowInCalendar.Both
    var shouldShowDaysOut = true
    var animationFinished = true
    var repeatingSchedule = [ScheduledShift]()
    var dayArray = [AnyObject]()
    
    let dataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        todayButton = UIBarButtonItem(title: "Today", style: .Plain, target: self, action: "toggleToCurrentDate")
        self.navigationItem.leftBarButtonItem = todayButton
        
        monthLabel.text = CVDate(date: NSDate()).monthYear
        
        let today = NSDate()
        var formatter = NSDateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        
        todayLabel.text = formatter.stringFromDate(today)
        
        tableView.delegate = self
        tableView.dataSource = self
    
        currentDate = today
        selectedDate = today
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        let results = dataManager.fetch("Job")
        
        if results.count > 0 {
            addButton.enabled = true
        } else {
            addButton.enabled = false
        }

        fetchWorkedShifts()
        fetchMonthSchedule()
        
        updateDayArray(selectedDate)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

        calendarView.reloadMonthView(selectedDate)
        tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        calendarView.commitCalendarViewUpdate()
        menuView.commitMenuViewUpdate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - IB Actions
    
    @IBAction func toggleListView(sender: AnyObject) {
        if isMonthView {
            calendarView.changeMode(.WeekView)
        } else {
            calendarView.changeMode(.MonthView)
        }
        
        isMonthView = !isMonthView
    }
    
    @IBAction func addButtonPressed(sender: AnyObject) {
        var today = NSDate()
        
        if NSDate.isSameDay(selectedDate, dateToCompare: today) || selectedDate.compare(today) == NSComparisonResult.OrderedDescending {
            self.performSegueWithIdentifier("addSchedule", sender: self)
        } else {
            let clockInStoryboard: UIStoryboard = UIStoryboard(name: "ClockInStoryboard", bundle: nil)
            let destinationVC: ShiftViewController = clockInStoryboard.instantiateViewControllerWithIdentifier("ShiftViewController") as! ShiftViewController
            destinationVC.hidesBottomBarWhenPushed = true
            let predicate = NSPredicate(format: "order == 0")
            let jobs = dataManager.fetch("Job", predicate: predicate) as! [Job]
            destinationVC.selectedJob = jobs[0]
            destinationVC.selectedDate = self.selectedDate
            destinationVC.isNewShift = true
            self.navigationController?.pushViewController(destinationVC, animated: true)
        }
    }
            
    // MARK: - Class Functions
    
    func toggleToCurrentDate() {
        calendarView.toggleCurrentDayView()
    }

    func updateDayArray(selectedDate: NSDate) {
        dayArray = []
        
        if showInCalendar == .Shift {
            for shift in monthWorkedShifts {
                if NSDate.isSameDay(selectedDate, dateToCompare: shift.startTime) {
                    dayArray.append(shift)
                }
            }
        } else if showInCalendar == .Schedule {
            for sched in monthSchedule {
                if NSDate.isSameDay(selectedDate, dateToCompare: sched.startTime) {
                    dayArray.append(sched)
                }
            }
        } else {
            for shift in monthWorkedShifts {
                if NSDate.isSameDay(selectedDate, dateToCompare: shift.startTime) {
                    dayArray.append(shift)
                }
            }
            
            for sched in monthSchedule {
                if NSDate.isSameDay(selectedDate, dateToCompare: sched.startTime) {
                    dayArray.append(sched)
                }
            }
        }
    }
    
    func fetchMonthSchedule() {
        monthSchedule = []
        
        let startOfMonth = NSDate.firstDayOfMonth(currentDate)
        let endOfMonth = NSDate.lastDayOfMonth(currentDate)
        
        let predicate = NSPredicate(format: "%@ <= startTime AND startTime <= %@", startOfMonth, endOfMonth)
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: true)
        let sortDescriptors = [sortDescriptor]
        
        monthSchedule = dataManager.fetch("ScheduledShift", predicate: predicate, sortDescriptors: sortDescriptors) as! [ScheduledShift]
        
        var index = 0
        
        for sched in monthSchedule {
            if sched.endTime.compare(NSDate()) == NSComparisonResult.OrderedAscending {
                let runningPredicate = NSPredicate(format: "status == 2") // Running
                let runningShift = dataManager.fetch("WorkedShift", predicate: runningPredicate) as! [WorkedShift]
                
                if runningShift.count == 0 {
                    let statusPredicate = NSPredicate(format: "status != 1") // 1 = Incomplete
                    let startPredicate = NSPredicate(format: "startTime <= %@ AND %@ <= endTime", sched.startTime, sched.startTime)
                    let endPredicate = NSPredicate(format: "startTime <= %@ AND %@ <= endTime", sched.endTime, sched.endTime)
                    let startPredicate1 = NSPredicate(format: "%@ <= startTime AND startTime <= %@", sched.startTime, sched.endTime)
                    let endPredicate2 = NSPredicate(format: "%@ <= endTime AND endTime <= %@", sched.startTime, sched.endTime)
                    let shiftPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType,
                        subpredicates: [startPredicate, endPredicate, startPredicate1, endPredicate2])
                    let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [statusPredicate, shiftPredicate])
                    let completeShifts = dataManager.fetch("WorkedShift", predicate: predicate) as! [WorkedShift]
                    
                    if completeShifts.count == 0 {
                        let shift = dataManager.addItem("WorkedShift") as! WorkedShift
                        shift.setValue(4, forKey: "status") // Auto
                        shift.job = sched.job
                        shift.startTime = sched.startTime
                        shift.endTime = sched.endTime
                        
                        let clockInTimelog = dataManager.addItem("Timelog") as! Timelog
                        clockInTimelog.workedShift = shift
                        clockInTimelog.comment = ""
                        clockInTimelog.type = "Clocked In"
                        clockInTimelog.id = 0
                        clockInTimelog.time = sched.startTime
                        
                        let clockOutTimelog = dataManager.addItem("Timelog") as! Timelog
                        clockOutTimelog.workedShift = shift
                        clockOutTimelog.comment = ""
                        clockOutTimelog.type = "Clocked Out"
                        clockOutTimelog.id = 1
                        clockOutTimelog.time = shift.endTime
                        
                        dataManager.save()
                    }
                }
                
                dataManager.delete(sched)
                monthSchedule.removeAtIndex(index)
            }
            
            index++
        }
    }
    
    func fetchWorkedShifts() {
        monthWorkedShifts = []
        
        let startOfMonth = NSDate.firstDayOfMonth(currentDate)
        let endOfMonth = NSDate.lastDayOfMonth(currentDate)
        
        let statusPredicate = NSPredicate(format: "status != 1 AND status != 2") // 1 = Incomplete, 2 = Running
        let timePredicate = NSPredicate(format: "%@ <= startTime AND startTime <= %@", startOfMonth, endOfMonth)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [statusPredicate, timePredicate])

        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: true)
        let sortDescriptors = [sortDescriptor]
        
        monthWorkedShifts = dataManager.fetch("WorkedShift", predicate: predicate, sortDescriptors: sortDescriptors) as! [WorkedShift]
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addSchedule" {
            let destinationVC = segue.destinationViewController as! AddScheduleTableViewController
            destinationVC.navigationItem.title = "Add Schedule"
            destinationVC.hidesBottomBarWhenPushed = true
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target: nil, action: nil)
            
            let today = NSDate()
            let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
            let dateComponents = calendar.components(NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay, fromDate: selectedDate)
            let timeComponents = calendar.components(NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitMinute, fromDate: today)
            
            dateComponents.setValue(timeComponents.hour, forComponent: NSCalendarUnit.CalendarUnitHour)
            dateComponents.setValue(timeComponents.minute, forComponent: NSCalendarUnit.CalendarUnitMinute)
            
            selectedDate = calendar.dateFromComponents(dateComponents)
            
            // Set start and end date to date selected on calendar
            destinationVC.startTime = self.selectedDate
            destinationVC.endTime = self.selectedDate
            destinationVC.isNewSchedule = true
        } else if segue.identifier == "editSchedule" {
            let destinationVC = segue.destinationViewController as! AddScheduleTableViewController
            destinationVC.navigationItem.title = "Edit Schedule"
            destinationVC.hidesBottomBarWhenPushed = true
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target: nil, action: nil)
            
            destinationVC.shift = self.selectedSchedule
            destinationVC.isNewSchedule = false
        }
    }
}

// MARK: - Table View Datasource & Delegate

extension CalendarViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TodayScheduleCell", forIndexPath: indexPath) as! TodayScheduleCell
        
        if let schedule = dayArray[indexPath.row] as? ScheduledShift {
            cell.schedule = schedule
        } else if let shift = dayArray[indexPath.row] as? WorkedShift {
            cell.shift = shift
        }
        
        cell.jobColorView.setNeedsDisplay()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let schedule = dayArray[indexPath.row] as? ScheduledShift {
            selectedSchedule = schedule
            self.performSegueWithIdentifier("editSchedule", sender: self)
        } else if let shift = dayArray[indexPath.row] as? WorkedShift {
            selectedWorkedShift = shift
            
            let clockInStoryboard: UIStoryboard = UIStoryboard(name: "ClockInStoryboard", bundle: nil)
            let destinationVC: ShiftViewController = clockInStoryboard.instantiateViewControllerWithIdentifier("ShiftViewController") as! ShiftViewController
            destinationVC.hidesBottomBarWhenPushed = true
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.Plain, target: nil, action: nil)
            destinationVC.selectedWorkedShift = self.selectedWorkedShift
            destinationVC.isNewShift = false
            self.navigationController?.pushViewController(destinationVC, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            tableView.beginUpdates()
            
            let app = UIApplication.sharedApplication()
            var deleteTitle = "Confirm Delete"
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            if let schedule = dayArray[indexPath.row] as? ScheduledShift {
                let shiftToDelete = schedule
                repeatingSchedule = dataManager.fetchRepeatingSchedule(shiftToDelete)
                
                let formatter = NSDateFormatter()
                formatter.dateFormat = "EEEE"
                
                let day = formatter.stringFromDate(shiftToDelete.startTime)
                
                formatter.dateStyle = .NoStyle
                formatter.timeStyle = .ShortStyle
                formatter.timeZone = NSTimeZone()
                
                if repeatingSchedule.count > 0 {
                    
                    let deleteAll = UIAlertAction(title: "Delete All (\(repeatingSchedule.count+1))", style: .Destructive) { (action) in
                        for shift in self.repeatingSchedule {
                            self.dataManager.delete(shift)
                        }
                        
                        self.dataManager.delete(shiftToDelete)
                        
                        self.repeatingSchedule = []
                        self.dayArray.removeAtIndex(indexPath.row)
                        self.fetchMonthSchedule()
                        tableView.deleteRowsAtIndexPaths([indexPath],  withRowAnimation: .Automatic)
                        self.calendarView.reloadMonthView(self.selectedDate)
                    }
                    
                    let start = formatter.stringFromDate(shiftToDelete.startTime)
                    let end = formatter.stringFromDate(shiftToDelete.endTime)
                    let message = String(format: "\n%@\n%@ - %@\n", day, start, end)
                    
                    alertController.message = message
                    alertController.title = "This shift is part of a repeating schedule"
                    alertController.addAction(deleteAll)
                    
                    var futureRepeatingSchedule = [ScheduledShift]()
                    
                    for repeatShift in repeatingSchedule {
                        if shiftToDelete.startTime.compare(repeatShift.startTime) == NSComparisonResult.OrderedAscending {
                            futureRepeatingSchedule.append(repeatShift)
                        }
                    }
                    
                    if futureRepeatingSchedule.count > 0 && futureRepeatingSchedule.count != repeatingSchedule.count {
                        let deleteFuture = UIAlertAction(title: "Delete This and All Future (\(futureRepeatingSchedule.count+1))", style: .Destructive) { (action) in
                            for shift in futureRepeatingSchedule {
                                self.dataManager.delete(shift)
                            }
                            
                            self.dataManager.delete(shiftToDelete)
                            
                            self.repeatingSchedule = []
                            self.dayArray.removeAtIndex(indexPath.row)
                            self.fetchMonthSchedule()
                            tableView.deleteRowsAtIndexPaths([indexPath],  withRowAnimation: .Automatic)
                            self.calendarView.reloadMonthView(self.selectedDate)
                        }
                    
                        alertController.addAction(deleteFuture)
                    }
                    
                    deleteTitle = "Delete this shift only"
                }
                
                let delete = UIAlertAction(title: deleteTitle, style: .Destructive) { (action) in
                    self.dataManager.delete(shiftToDelete)
                    
                    self.repeatingSchedule = []
                    self.dayArray.removeAtIndex(indexPath.row)
                    self.fetchMonthSchedule()
                    tableView.deleteRowsAtIndexPaths([indexPath],  withRowAnimation: .Automatic)
                    self.calendarView.reloadMonthView(self.selectedDate)
                }
                
                alertController.addAction(delete)
            } else if let shift = dayArray[indexPath.row] as? WorkedShift {
                let shiftToDelete = shift
                
                let delete = UIAlertAction(title: deleteTitle, style: .Destructive) { (action) in
                    self.dataManager.delete(shiftToDelete)
                    
                    self.dayArray.removeAtIndex(indexPath.row)
                    self.fetchWorkedShifts()
                    tableView.deleteRowsAtIndexPaths([indexPath],  withRowAnimation: .Automatic)
                    self.calendarView.reloadMonthView(self.selectedDate)
                }
                
                alertController.addAction(delete)
            }
        
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                self.repeatingSchedule = []
            }
            
            alertController.addAction(cancel)
            self.presentViewController(alertController, animated: true, completion: nil)
            tableView.endUpdates()
        }
    }
}


// MARK: - CVCalendarViewDelegate

extension CalendarViewController: CVCalendarViewDelegate {
    func presentationMode() -> CalendarMode {
        return .MonthView
    }
    
    func firstWeekday() -> Weekday {
        return .Sunday
    }
    
    func shouldShowWeekdaysOut() -> Bool {
        return shouldShowDaysOut
    }
    
    func didSelectDayView(dayView: CVCalendarDayView) {
        
        if let currentDay = dayView.date.convertedDate() {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            
            todayLabel.text = formatter.stringFromDate(currentDay)
        }
        
        selectedDate = dayView.date.convertedDate()
        
        if NSDate.isSameDay(selectedDate, dateToCompare: NSDate()) {
            showInCalendar = .Both
        } else if selectedDate.compare(NSDate()) == NSComparisonResult.OrderedDescending {
            showInCalendar = .Schedule
        } else {
            showInCalendar = .Shift
        }
    
        updateDayArray(selectedDate)
        
        dayView.circleView?.setNeedsDisplay()
        tableView.reloadData()
    }
    
    func presentedDateUpdated(date: CVDate) {
        if monthLabel.text != date.monthYear && self.animationFinished {
            
            currentDate = date.convertedDate()
            
            fetchMonthSchedule()
            fetchWorkedShifts()
            
            let updatedMonthLabel = UILabel()
            updatedMonthLabel.textColor = monthLabel.textColor
            updatedMonthLabel.font = monthLabel.font
            updatedMonthLabel.textAlignment = .Center
            updatedMonthLabel.text = date.monthYear
            updatedMonthLabel.sizeToFit()
            updatedMonthLabel.alpha = 0
            updatedMonthLabel.center = self.monthLabel.center
            
            let offset = CGFloat(48)
            updatedMonthLabel.transform = CGAffineTransformMakeTranslation(0, offset)
            updatedMonthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
            
            UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.animationFinished = false
                self.monthLabel.transform = CGAffineTransformMakeTranslation(0, -offset)
                self.monthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
                self.monthLabel.alpha = 0
                
                updatedMonthLabel.alpha = 1
                updatedMonthLabel.transform = CGAffineTransformIdentity
                
                }) { _ in
                    
                    self.animationFinished = true
                    self.monthLabel.frame = updatedMonthLabel.frame
                    self.monthLabel.text = updatedMonthLabel.text
                    self.monthLabel.transform = CGAffineTransformIdentity
                    self.monthLabel.alpha = 1
                    updatedMonthLabel.removeFromSuperview()
            }
            
            self.view.insertSubview(updatedMonthLabel, aboveSubview: self.monthLabel)
        }
    }
    
    func topMarker(shouldDisplayOnDayView dayView: CVCalendarDayView) -> Bool {
        return true // line separators
    }
    
    func dotMarker(shouldShowOnDayView dayView: CVCalendarDayView) -> Bool {
        let day = dayView.date.convertedDate()!
        var shouldShowDot = false
        
        let statusPredicate = NSPredicate(format: "status != 1 AND status != 2") // 1 = Incomplete, 2 = Running
        let timePredicate = NSPredicate(format: "%@ <= startTime AND startTime <= %@", day.startOfDay, day.endOfDay!)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [statusPredicate, timePredicate])
        
        let schedule = dataManager.fetch("ScheduledShift", predicate: timePredicate) as! [ScheduledShift]
        let workedShifts = dataManager.fetch("WorkedShift", predicate: predicate) as! [WorkedShift]
        
        if schedule.count > 0 || workedShifts.count > 0 {
            shouldShowDot = true
        }
                
        return shouldShowDot
    }
    
    func dotMarker(colorOnDayView dayView: CVCalendarDayView) -> [UIColor] {
        let day = dayView.date.convertedDate()!
        
        var results = [AnyObject]()
        var colors = [UIColor]()
        var count = 0
        
        let statusPredicate = NSPredicate(format: "status != 1 AND status != 2") // 1 = Incomplete, 2 = Running
        let timePredicate = NSPredicate(format: "%@ <= startTime AND startTime <= %@", day.startOfDay, day.endOfDay!)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [statusPredicate, timePredicate])
        
        results = dataManager.fetch("ScheduledShift", predicate: timePredicate) as [(AnyObject)]
        results += dataManager.fetch("WorkedShift", predicate: predicate)
        
        for result in results {
            colors.append(UIColor.grayColor())
        
            count++
            if count == 3 {
                break
            }
        }
        
        return colors
    }
    
    func dotMarker(shouldMoveOnHighlightingOnDayView dayView: CVCalendarDayView) -> Bool {
        return false
    }
}


// MARK: - CVCalendarMenuViewDelegate

extension CalendarViewController: CVCalendarMenuViewDelegate {
    // firstWeekday() has been already implemented.
}



