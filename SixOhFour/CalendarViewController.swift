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
    @IBOutlet weak var menuView: CVCalendarMenuView! //why is this called "menuView"?
    @IBOutlet weak var calendarView: CVCalendarView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var todayButton: UIBarButtonItem!
    var selectedDate: NSDate!
    var monthSchedule: [ScheduledShift]!
    var daySchedule: [ScheduledShift]!
    var shift: ScheduledShift!
    
    var isMonthView = true
    var shouldShowDaysOut = true
    var isAnimationFinished = true
    var currentMonth = CVDate(date: NSDate()).currentMonth
    var deleteSchedule = [ScheduledShift]()
    
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
        
        selectedDate = CVDate(date: NSDate()).convertedDate()
        daySchedule = [ScheduledShift]()
        
        fetchMonthSchedule()
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
    
        
    @IBAction func unwindAfterSaveSchedule(segue: UIStoryboardSegue) {
        calendarView.toggleViewWithDate(selectedDate)
        
        fetchMonthSchedule()
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .NoStyle
        
        let selectedDay = formatter.stringFromDate(selectedDate)
        
        updateDaySchedule(selectedDay)
        
        tableView.reloadData()
    }
    
    
    // MARK: - Class Functions
    
    func toggleToCurrentDate() {
        calendarView.toggleCurrentDayView()
    }
    
    func toggleAddButton() {
        var today = NSDate()
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let comps = (NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay)
        
        let selectedDateComponents = calendar.components(comps, fromDate: selectedDate)
        let todayComponents = calendar.components(comps, fromDate: today)
        
        today = calendar.dateFromComponents(todayComponents)!
        let dateToCompare = calendar.dateFromComponents(selectedDateComponents)
        
        if dateToCompare!.compare(today) == NSComparisonResult.OrderedAscending {
            addButton.enabled = false
        } else {
            addButton.enabled = true
        }

    }
    
    func updateDaySchedule(selectedDay: String) {
        daySchedule = []
        
        for m in monthSchedule {
            if selectedDay == m.startDate {
                daySchedule.append(m)
            }
        }
    }
    
    func fetchMonthSchedule() {
        let predicate = NSPredicate(format: "startDate contains[c] %@", currentMonth)
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: true)
        let sortDescriptors = [sortDescriptor]
        
        monthSchedule = dataManager.fetch("ScheduledShift", predicate: predicate, sortDescriptors: sortDescriptors) as! [ScheduledShift]
    }
    
    func fetchRepeats(shift: ScheduledShift) {
        
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: false)
        let sortDescriptors = [sortDescriptor]
        let results = dataManager.fetch("ScheduledShift", sortDescriptors: sortDescriptors)
        
        let lastShift = results[0] as! ScheduledShift
        
        var startDate = shift.startTime
        var endDate = shift.endTime
        var shifts = [ScheduledShift]()
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        while startDate.compare(lastShift.startTime) == NSComparisonResult.OrderedAscending {
            
            let predicate = NSPredicate(format: "startTime == %@ && endTime == %@", startDate, endDate)
            let results = dataManager.fetch("ScheduledShift", predicate: predicate) as! [ScheduledShift]
            
            if results.count > 0 {
                deleteSchedule.append(results[0])
            }
            
            startDate = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: 7, toDate: startDate, options: nil)!
            endDate = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: 7, toDate: endDate, options: nil)!
        }
        
        if startDate.compare(lastShift.startTime) == NSComparisonResult.OrderedSame {
            deleteSchedule.append(lastShift)
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "addScheduleSegue" {
            let destinationVC = segue.destinationViewController as! AddScheduleTableViewController
            destinationVC.navigationItem.title = "Add Schedule"
            destinationVC.hidesBottomBarWhenPushed = true;
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
        }
        
        if segue.identifier == "editSchedule" {
            let destinationVC = segue.destinationViewController as! AddScheduleTableViewController
            destinationVC.navigationItem.title = "Edit Schedule"
            destinationVC.hidesBottomBarWhenPushed = true;
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target: nil, action: nil)
            
            destinationVC.shift = self.shift
            destinationVC.isNewSchedule = false
        }
    }
}


// MARK: - Table View Datasource & Delegate

extension CalendarViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if daySchedule != nil {
            return daySchedule.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TodayScheduleCell", forIndexPath: indexPath) as! TodayScheduleCell
        
        cell.shift = daySchedule[indexPath.row]
        
        var currentTime = NSDate()
        
        if cell.shift.startTime.compare(currentTime) == NSComparisonResult.OrderedAscending {
            cell.selectionStyle = .None
            cell.toggleLabels(false)
        } else {
            cell.selectionStyle = .Default
            cell.toggleLabels(true)
        }
        
        cell.jobColorView.setNeedsDisplay()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        shift = daySchedule[indexPath.row]
        
        var currentTime = NSDate()
        
        if shift.startTime.compare(currentTime) == NSComparisonResult.OrderedDescending {
            self.performSegueWithIdentifier("editSchedule", sender: self)
        }
            
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            
            tableView.beginUpdates()
            
            let app = UIApplication.sharedApplication()
            
            let shiftToDelete = daySchedule[indexPath.row]
            
            fetchRepeats(shiftToDelete)

            var alertTitle = "\(deleteSchedule.count) similar shift"
            var deleteTitle = "Confirm Delete"
            
            let formatter = NSDateFormatter()
            formatter.dateFormat = "EEEE"
            
            let day = formatter.stringFromDate(shiftToDelete.startTime)
            
            formatter.dateStyle = .NoStyle
            formatter.timeStyle = .ShortStyle
            formatter.timeZone = NSTimeZone()
            
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)

            if deleteSchedule.count > 1 {
                alertTitle += "s"
                
                let deleteAll = UIAlertAction(title: "Delete All (\(deleteSchedule.count))", style: .Destructive) { (action) in
                    for shift in self.deleteSchedule {
                        for event in app.scheduledLocalNotifications {
                            let notification = event as! UILocalNotification
                            let startTime = notification.fireDate
                            
                            if shift.startTime.compare(startTime!) == NSComparisonResult.OrderedSame {
                                app.cancelLocalNotification(notification)
                                break
                            }
                        }
                        
                        self.dataManager.delete(shift)
                    }
                    
                    self.deleteSchedule = []
                    self.daySchedule.removeAtIndex(indexPath.row)
                    self.fetchMonthSchedule()
                    tableView.deleteRowsAtIndexPaths([indexPath],  withRowAnimation: .Automatic)
                }
                
                let start = formatter.stringFromDate(shiftToDelete.startTime)
                let end = formatter.stringFromDate(shiftToDelete.endTime)
                let message = String(format: "\n%@\n%@ - %@\n", day, start, end)
                
                alertController.message = message
                alertController.title = alertTitle
                alertController.addAction(deleteAll)
                
                deleteTitle = "Delete this shift only"
            }
            
            
            let delete = UIAlertAction(title: deleteTitle, style: .Destructive) { (action) in
                for event in app.scheduledLocalNotifications {
                    let notification = event as! UILocalNotification
                    let startTime = notification.fireDate
                    
                    if shiftToDelete.startTime.compare(startTime!) == NSComparisonResult.OrderedSame {
                        app.cancelLocalNotification(notification)
                        break
                    }
                }
                
                self.dataManager.delete(shiftToDelete)
    
                self.deleteSchedule = []
                self.daySchedule.removeAtIndex(indexPath.row)
                self.fetchMonthSchedule()
                tableView.deleteRowsAtIndexPaths([indexPath],  withRowAnimation: .Automatic)
            }
        
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                self.deleteSchedule = []
            }
            
            alertController.addAction(delete)
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
        
        var selectedDay = dayView.date.monthDayYear
        
        updateDaySchedule(selectedDay)
        
        selectedDate = dayView.date.convertedDate()
        toggleAddButton()

        tableView.reloadData()
    }
    
    func presentedDateUpdated(date: CVDate) {
        if monthLabel.text != date.monthYear && self.isAnimationFinished {
            
            currentMonth = date.currentMonth
            fetchMonthSchedule()
            
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
                self.isAnimationFinished = false
                self.monthLabel.transform = CGAffineTransformMakeTranslation(0, -offset)
                self.monthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
                self.monthLabel.alpha = 0
                
                updatedMonthLabel.alpha = 1
                updatedMonthLabel.transform = CGAffineTransformIdentity
                
                }) { _ in
                    
                    self.isAnimationFinished = true
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
        
        let day = dayView.date.monthDayYear
        var shouldShowDot = false
        
        let predicate = NSPredicate(format: "startDate == %@", day)
        let results = dataManager.fetch("ScheduledShift", predicate: predicate) as! [ScheduledShift]
        
        if results.count > 0 {
            shouldShowDot = true
        }

        return shouldShowDot
    }
    
    func dotMarker(colorOnDayView dayView: CVCalendarDayView) -> [UIColor] {
        
        let day = dayView.date.monthDayYear
        let color = UIColor.lightGrayColor()

        let predicate = NSPredicate(format: "startDate == %@", day)
        let results = dataManager.fetch("ScheduledShift", predicate: predicate) as! [ScheduledShift]
        
        
        if results.count == 2 {
            return [color, color]
        } else if results.count >= 3 {
            return [color, color, color]
        } else {
            return [color]
        }
    }
    
    func dotMarker(shouldMoveOnHighlightingOnDayView dayView: CVCalendarDayView) -> Bool {
        return false
    }
}


// MARK: - CVCalendarMenuViewDelegate

extension CalendarViewController: CVCalendarMenuViewDelegate {
    // firstWeekday() has been already implemented.
}



