//
//  AddScheduleTableViewController.swift
//  SixOhFour
//
//  Created by jemsomniac on 7/8/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class AddScheduleTableViewController: UITableViewController {

    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var jobNameLabel: UILabel!
    @IBOutlet weak var jobColorView: JobColorView!
    @IBOutlet weak var repeatLabel: UILabel!
    @IBOutlet weak var reminderLabel: UILabel!
    @IBOutlet weak var reminderPicker: UIPickerView!
    @IBOutlet weak var endRepeatLabel: UILabel!
    
    var saveButton: UIBarButtonItem!
    var startTime: NSDate!
    var endTime: NSDate!
    var job: Job!
    var shift: ScheduledShift!

    
    var isNewSchedule = true
    var startDatePickerHidden = true
    var endDatePickerHidden = true
    var reminderPickerHidden = true
    var jobListEmpty = true;
    var reminderMinutes = 16 // Maximum reminder = 15 minutes
    var dataManager = DataManager()
    var repeatSettings: RepeatSettings!
    var conflicts = [ScheduledShift]()
    var schedule = [ScheduledShift]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveButton = UIBarButtonItem(title:"Save", style: .Plain, target: self, action: "saveSchedule")
        self.navigationItem.rightBarButtonItem = saveButton
        saveButton.enabled = false
        
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
    
        if shift != nil {
            job = shift.job
            jobNameLabel.text = job.company.name
            jobColorView.color = job.color.getColor
            jobListEmpty = false
            
            startDatePicker.date = shift.startTime
            endDatePicker.date = shift.endTime
            
        } else {
            
            var results = dataManager.fetch("Job")
            
            if results.count > 0 {
                job = results[0] as! Job
                jobNameLabel.text = job.company.name
                jobColorView.color = job.color.getColor
                jobListEmpty = false
            } else {
                jobNameLabel.text = "Add a Job"
                jobNameLabel.textColor = UIColor.lightGrayColor()
                jobColorView.color = UIColor.lightGrayColor()
            }
            
            startDatePicker.date = startTime
            endDatePicker.date = endTime
            
        }
        
        repeatSettings = RepeatSettings(startDate: startDatePicker.date)
        repeatLabel.text = repeatSettings.type
        
        endRepeatLabel.text = dateFormatter.stringFromDate(repeatSettings.endDate)

        startDatePicker.minimumDate = NSDate()
        endDatePicker.minimumDate = NSDate()

        datePickerChanged(startLabel, datePicker: startDatePicker)
        
        // Reminder Picker
        self.reminderPicker.dataSource = self
        self.reminderPicker.delegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - SetIB Actions
    
    @IBAction func startDatePickerValue(sender: AnyObject) {
        datePickerChanged(startLabel, datePicker: startDatePicker)
    }
    
    @IBAction func endDatePickerValue(sender: AnyObject) {
        datePickerChanged(endLabel, datePicker: endDatePicker)
    }
    
    @IBAction func unwindFromJobsListTableViewController(segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! JobsListTableViewController
        
        if sourceVC.selectedJob != nil {
            job = sourceVC.selectedJob
            jobNameLabel.text = sourceVC.selectedJob.company.name
            
            jobColorView.color = sourceVC.selectedJob.color.getColor
        }
    }
    
    @IBAction func unwindFromSetRepeatTableViewController(segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! SetRepeatTableViewController
        
        self.repeatSettings = sourceVC.repeatSettings
        repeatLabel.text = repeatSettings.type
        
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        endRepeatLabel.text = dateFormatter.stringFromDate(repeatSettings.endDate)

        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    @IBAction func unwindFromEndRepeatTableViewController(segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! EndRepeatTableViewController
        
        repeatSettings.endDate = sourceVC.endDate

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        endRepeatLabel.text = dateFormatter.stringFromDate(repeatSettings.endDate)
    }
    
    // MARK: - Class Functions
    
    func saveSchedule() {
        conflicts = []
        
        if isNewSchedule {
            if repeatSettings.type == "Never" {
                addShift()
            } else {
                addWeeklySchedule()
            }
        } else {
            editSchedule()
        }
        
        resolveConflicts()
    }
    
    func unwind() {
        self.performSegueWithIdentifier("unwindAfterSaveSchedule", sender: self)
    }
    

    // MARK: - Toggles
    
    func togglePicker(picker: String) {
        if picker == "startDate" {
            startDatePickerHidden = !startDatePickerHidden
            toggleLabelColor(startDatePickerHidden, label: startLabel)
            endDatePickerHidden = true
            reminderPickerHidden = true
            toggleLabelColor(endDatePickerHidden, label: endLabel)
        } else if picker == "endDate" {
            endDatePickerHidden = !endDatePickerHidden
            toggleLabelColor(endDatePickerHidden, label: endLabel)
            startDatePickerHidden = true
            reminderPickerHidden = true
            toggleLabelColor(startDatePickerHidden, label: startLabel)
        } else if picker == "reminder" {
            reminderPickerHidden = !reminderPickerHidden
            startDatePickerHidden = true
            endDatePickerHidden = true
            toggleLabelColor(endDatePickerHidden, label: endLabel)
            toggleLabelColor(startDatePickerHidden, label: startLabel)
        } else {
            // Close datepickers
            startDatePickerHidden = true
            endDatePickerHidden = true
            reminderPickerHidden = true
            toggleLabelColor(startDatePickerHidden, label: startLabel)
            toggleLabelColor(endDatePickerHidden, label: endLabel)
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
        
    }
    
    func toggleLabelColor(hidden: Bool, label: UILabel) {
        if hidden{
            label.textColor = UIColor.blackColor()
        } else {
            label.textColor = UIColor.redColor()
        }
    }
    
    func toggleSaveButton() {
        if jobListEmpty {
            saveButton.enabled = false
        } else if startDatePicker.date.compare(endDatePicker.date) == NSComparisonResult.OrderedAscending {
            saveButton.enabled = true
        } else {
            saveButton.enabled = false
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 1 && indexPath.row == 0 {
            togglePicker("startDate")
        } else if indexPath.section == 1 && indexPath.row == 2 {
            togglePicker("endDate")
        } else if indexPath.section == 2 && indexPath.row == 0 {
            togglePicker("reminder")
        } else {
            togglePicker("Close")
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if !jobListEmpty {
            if startDatePickerHidden && indexPath.section == 1 && indexPath.row == 1 {
                return 0
            } else if endDatePickerHidden && indexPath.section == 1 && indexPath.row == 3 {
                return 0
            }
            
            if repeatLabel.text == "Never" && indexPath.section == 1 && indexPath.row == 5 {
                return 0
            }
            
            if reminderPickerHidden && indexPath.section == 2 && indexPath.row == 1 {
                return 0
            }
            
            // TODO: Enable reminder for next version
            if indexPath.section == 2 {
                return 0
            }
            
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        } else {
            if indexPath.section == 0 {
                return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
            } else {
                return 0
            }
            
        }
    }
}


// MARK:  - Scheduler functions

extension AddScheduleTableViewController {
    
    func addShift() {
        
        let newShift = dataManager.addItem("ScheduledShift") as! ScheduledShift
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .NoStyle
        
        newShift.startDate = formatter.stringFromDate(self.startTime)
        newShift.startTime = self.startTime
        newShift.endTime = self.endTime
        newShift.job = self.job
        
        checkConflicts(newShift)
        schedule.append(newShift)
    }
    
    func editSchedule() {
        
        let editShift = dataManager.editItem(shift, entityName: "ScheduledShift") as! ScheduledShift
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .NoStyle
        
        editShift.startDate = formatter.stringFromDate(self.startTime)
        editShift.startTime = self.startTime
        editShift.endTime = self.endTime
        editShift.job = self.job

        checkConflicts(editShift)
        schedule.append(editShift)
    }
    
    func addWeeklySchedule() {
        var shifts = [NSDate]()
        var startRepeat = startTime
    
        if let repeatSettings = self.repeatSettings as? RepeatWeekly  {
            var repeatArray = repeatSettings.getRepeat()
            
            var row = repeatSettings.repeatEvery - 1
            
            let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
            var difference = calendar.components(NSCalendarUnit.CalendarUnitDay, fromDate: startRepeat, toDate: repeatSettings.endDate, options: nil).day
            
            var offset = 0 - repeatSettings.daySelectedIndex
            
            while offset < difference {
                for x in 0...row{
                    for y in 0...6 {
                        
                        if repeatArray[x][y] == true {
                            var date = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: offset, toDate: startRepeat, options: nil)
                            
                            if date!.compare(startRepeat) == NSComparisonResult.OrderedDescending || date!.compare(startRepeat) == NSComparisonResult.OrderedSame {
                                    
                                shifts.append(date!)
                            }
                        }
                        
                        offset++
                        
                        if offset > difference {
                            break
                        }
                    }
                }
            }
        }
        
        for shift in shifts {
            var difference = endTime.timeIntervalSinceDate(startTime)
            
            startTime = shift
            endTime = startTime.dateByAddingTimeInterval(difference)
            
            addShift()
        }
    }

    func checkConflicts(shift: ScheduledShift) {
        let startPredicate = NSPredicate(format: "startTime <= %@ AND %@ <= endTime", shift.startTime, shift.startTime)
        let endPredicate = NSPredicate(format: "startTime <= %@ AND %@ <= endTime", shift.endTime, shift.endTime)
        let startPredicate1 = NSPredicate(format: "%@ <= startTime AND startTime <= %@", shift.startTime, shift.endTime)
        let endPredicate2 = NSPredicate(format: "%@ <= endTime AND endTime <= %@", shift.startTime, shift.endTime)
        
        let shiftPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType,
            subpredicates: [startPredicate, endPredicate, startPredicate1, endPredicate2])
        
        let selfPredicate = NSPredicate(format: "SELF != %@", shift)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [shiftPredicate, selfPredicate])
        
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: true)
        let sortDescriptors = [sortDescriptor]
        
        let results = dataManager.fetch("ScheduledShift", predicate: predicate, sortDescriptors: sortDescriptors) as! [ScheduledShift]
        
        for result in results {
            conflicts.append(result)
        }
    }
    
    func resolveConflicts() {
        if conflicts.count == 0 {
            save(schedule)
            unwind()
        } else {
            
            var message = "\(conflicts.count) Schedule Conflict"
            var replaceTitle = "Replace"
            
            if conflicts.count > 1 {
                message += "s"
                replaceTitle += " All (\(conflicts.count))"
            }
            
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            let replace = UIAlertAction(title: replaceTitle, style: .Destructive) { (action) in
                for conflict in self.conflicts {
                    self.dataManager.delete(conflict)
                }
                
                self.save(self.schedule)
                self.unwind()
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                if self.isNewSchedule {
                    for shift in self.schedule {
                        self.dataManager.delete(shift)
                        self.schedule.removeAtIndex(0)
                    }
                } else {
                    self.dataManager.undo()
                }
            }
            
            alertController.addAction(replace)
            alertController.addAction(cancel)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func save(schedule: [ScheduledShift]) {
        
        for shift in schedule {
            let formatter = NSDateFormatter()
            formatter.dateStyle = .NoStyle
            formatter.timeStyle = .ShortStyle
            formatter.timeZone = NSTimeZone()
            
            let start = formatter.stringFromDate(shift.startTime)
            
            var notification = UILocalNotification()
            notification.alertBody = "REMINDER: You have a shift at \(start)"
            notification.alertAction = "clockin"
            notification.fireDate = shift.startTime
            notification.soundName = UILocalNotificationDefaultSoundName
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
        
        dataManager.save()
    }
}


// MARK: - Date Picker

extension AddScheduleTableViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func datePickerChanged(label: UILabel, datePicker: UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        label.text = dateFormatter.stringFromDate(datePicker.date)
        
        if datePicker == startDatePicker {
            if datePicker.date.compare(endDatePicker.date) == NSComparisonResult.OrderedDescending {
                endLabel.text = label.text
                endDatePicker.date = datePicker.date
            } else {
                let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
                
                let dateComponents = NSDateComponents()
                dateComponents.day = 1
                
                let maxDate = calendar.dateByAddingComponents(dateComponents, toDate: datePicker.date, options: nil)
                
                if maxDate!.compare(endDatePicker.date) == NSComparisonResult.OrderedAscending {
                    endDatePicker.date = maxDate!
                }
                
                endLabel.text = dateFormatter.stringFromDate(endDatePicker.date)
            }
            
            startTime = datePicker.date
            endTime = endDatePicker.date
            
            let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
            let myComponents = cal!.components(NSCalendarUnit.CalendarUnitWeekday, fromDate: datePicker.date)
            
            repeatSettings.daySelectedIndex = myComponents.weekday - 1
        }
        
        if datePicker == endDatePicker {
            if datePicker.date.compare(startDatePicker.date) == NSComparisonResult.OrderedAscending {
                startLabel.text = label.text
                startDatePicker.date = datePicker.date
            } else {
                let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
                
                let dateComponents = NSDateComponents()
                dateComponents.day = -1
                
                let minDate = calendar.dateByAddingComponents(dateComponents, toDate: datePicker.date, options: nil)
                
                if minDate!.compare(startDatePicker.date) == NSComparisonResult.OrderedDescending {
                    startDatePicker.date = minDate!
                }
                
                startLabel.text = dateFormatter.stringFromDate(startDatePicker.date)


            }
            endTime = datePicker.date
            startTime = startDatePicker.date
        }
        
        repeatSettings.startDate = startTime
        
        toggleSaveButton()
    }

    
    // MARK: - Reminder Picker
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return reminderMinutes
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return "\(row)"
        
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            reminderLabel.text = "None"
        } else {
            reminderLabel.text = "\(row) minutes before"
        }
    }
}


// MARK: - Navigation

extension AddScheduleTableViewController {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "selectJob" {
            let destinationVC = segue.destinationViewController as! JobsListTableViewController
            destinationVC.previousSelection = jobNameLabel.text
            destinationVC.source = "addSchedule"
        }
        
        if segue.identifier == "setRepeat" {
            let destinationVC = segue.destinationViewController as! SetRepeatTableViewController
            
            destinationVC.selectedDay = startTime
            destinationVC.repeatSettings = self.repeatSettings
            
        }
        
        if segue.identifier == "setEndRepeat" {
            let destinationVC = segue.destinationViewController as! EndRepeatTableViewController
            
            destinationVC.startDate = repeatSettings.startDate
            destinationVC.endDate = repeatSettings.endDate
            
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == "selectJob" {
            if jobListEmpty {
                let addJobStoryboard: UIStoryboard = UIStoryboard(name: "AddJobStoryboard", bundle: nil)
                let addJobsVC: AddJobTableViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("AddJobTableViewController")
                    as! AddJobTableViewController
                
                self.navigationController?.pushViewController(addJobsVC, animated: true)
                
                return false
            } else {
                return true
            }
        }
        
        return true
    }
}
