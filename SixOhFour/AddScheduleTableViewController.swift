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
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var jobColorView: JobColorView!
    @IBOutlet weak var repeatLabel: UILabel!
    @IBOutlet weak var endRepeatLabel: UILabel!
    @IBOutlet weak var hoursTextField: UITextField!
    @IBOutlet weak var minutesTextField: UITextField!
    @IBOutlet weak var maxDurationLabel: UILabel!
    
    var saveButton: UIBarButtonItem!
    var startTime: NSDate!
    var endTime: NSDate!
    var job: Job!
    var shift: ScheduledShift!
    
    var isNewSchedule = true
    var startDatePickerHidden = true
    var endDatePickerHidden = true
    var isJobListEmpty = true
    var isValidShift = false
    var repeatSettings: RepeatSettings!
    var conflicts = [ScheduledShift]()
    var schedule = [ScheduledShift]()
    var repeatingSchedule = [ScheduledShift]()
    var hours = 0
    var minutes = 0
 
    let dataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveButton = UIBarButtonItem(title:"Save", style: .Plain, target: self, action: "saveButtonPressed")
        saveButton.enabled = false
        
        self.navigationItem.rightBarButtonItem = saveButton
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelButtonPressed")
        
        hoursTextField.delegate = self
        minutesTextField.delegate = self
        
        var tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        
        if shift != nil {
            job = shift.job
            jobNameLabel.text = job.company
            positionLabel.text = job.position
            jobColorView.color = job.color.getColor
            isJobListEmpty = false
            
            startDatePicker.date = shift.startTime
            endDatePicker.date = shift.endTime
            
            let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
            let dateComponents = calendar.components(NSCalendarUnit.CalendarUnitMinute, fromDate: startDatePicker.date, toDate: endDatePicker.date, options: nil)
            let duration = dateComponents.minute
            
            hours = duration / 60
            minutes = duration % 60
            hoursTextField.text = String(hours)
            minutesTextField.text = String(minutes)
            isValidShift = true
            
            repeatingSchedule = dataManager.fetchRepeatingSchedule(shift)
        } else {
            
            let predicate = NSPredicate(format: "order == 0")
            let jobs = dataManager.fetch("Job", predicate: predicate) as! [Job]
            
            if jobs.count > 0 {
                job = jobs[0]
                jobNameLabel.text = job.company
                positionLabel.text = job.position
                jobColorView.color = job.color.getColor
                isJobListEmpty = false
            } 
            
            startDatePicker.date = startTime
            endDatePicker.date = endTime
        }
        
        repeatSettings = RepeatSettings(startDate: startDatePicker.date)
        repeatLabel.text = repeatSettings.type
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        endRepeatLabel.text = dateFormatter.stringFromDate(repeatSettings.endDate)

        let minDate = NSDate()
        
        startDatePicker.minimumDate = minDate
        endDatePicker.minimumDate = minDate

        datePickerChanged(startLabel, datePicker: startDatePicker)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        hoursTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        minutesTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IB Actions
        
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
            jobNameLabel.text = sourceVC.selectedJob.company
            positionLabel.text = sourceVC.selectedJob.position

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
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func validateDuration() {
        let max = 1440
        let duration = (hours * 60) + minutes
        
        if duration > max {
            maxDurationLabel.hidden = false
            hours = 24
            minutes = 0
        } else {
            maxDurationLabel.hidden = true
        }
        
        if duration <= 0 {
            isValidShift = false
        } else {
            isValidShift = true
        }
    }
    
    func cancelButtonPressed() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func saveButtonPressed() {
        conflicts = []
        
        if isNewSchedule {
            if repeatSettings.type == "Never" {
                addShift(startTime, shiftEndTime: endTime)
            } else {
                addWeeklySchedule()
            }
            resolveConflicts()
        } else {
            if repeatingSchedule.count == 0 {
                editShift(shift)
                resolveConflicts()
            } else {
                editSchedule()
            }
        }
    }
    
    func handleNotifications() {
        dataManager.save()
        
        let app = UIApplication.sharedApplication()
        app.cancelAllLocalNotifications()

        let limit = 25 // limit to 50 notifications (pair of 25)
        var index = 0
        
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: true)
        let schedule = dataManager.fetch("ScheduledShift", sortDescriptors: [sortDescriptor]) as! [ScheduledShift]
        
        for sched in schedule {
            if index == limit {
                break
            } else {
                let formatter = NSDateFormatter()
                formatter.dateStyle = .NoStyle
                formatter.timeStyle = .ShortStyle
                formatter.timeZone = NSTimeZone()

                let start = formatter.stringFromDate(sched.startTime)
                let end = formatter.stringFromDate(sched.endTime)

                var startNotification = UILocalNotification()
                startNotification.alertBody = "You are scheduled to clock in at \(start)"
                startNotification.alertAction = "clock in"
                startNotification.fireDate = sched.startTime
                startNotification.soundName = UILocalNotificationDefaultSoundName
                UIApplication.sharedApplication().scheduleLocalNotification(startNotification)

                var endNotification = UILocalNotification()
                endNotification.alertBody = "You are scheduled to clock out at \(end)"
                endNotification.alertAction = "clock out"
                endNotification.fireDate = sched.endTime
                endNotification.soundName = UILocalNotificationDefaultSoundName
                UIApplication.sharedApplication().scheduleLocalNotification(endNotification)
            }
            index++
        }
    }
    
    func togglePicker(picker: String) {
        if picker == "startDate" {
            startDatePickerHidden = !startDatePickerHidden
            endDatePickerHidden = true
        } else if picker == "endDate" {
            endDatePickerHidden = !endDatePickerHidden
            startDatePickerHidden = true
        } else {
            // Close datepickers
            startDatePickerHidden = true
            endDatePickerHidden = true
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func toggleSaveButton() {
        if isJobListEmpty || !isValidShift{
            saveButton.enabled = false
        } else {
            saveButton.enabled = true
        }
    }
    
    func addShift(shiftStartTime: NSDate, shiftEndTime: NSDate) {
        let newShift = dataManager.addItem("ScheduledShift") as! ScheduledShift
        
        newShift.startTime = shiftStartTime
        newShift.endTime = shiftEndTime
        newShift.job = self.job
        
        checkConflicts(newShift)
        schedule.append(newShift)
    }
    
    func editShift(shift: ScheduledShift) {
        if repeatSettings.type == "Weekly" { // Delete repeats enables creation on a new repeating schedule
            // Delete the existing shift
            dataManager.delete(shift)
            
            // Then create a new repeating schedule
            addWeeklySchedule()
        } else {
            // Delete the existing shift then create a new one
            // Edits are handled this way to also handle notifications automatically
            dataManager.delete(shift)
            addShift(startTime, shiftEndTime: endTime)
        }
    }
    
    func editSchedule() {
        
        var alertTitle = "Found \(repeatingSchedule.count) similar shifts"
        var editTitle = "Confirm changes"

        let formatter = NSDateFormatter()
        formatter.dateFormat = "EEEE"
        
        let day = formatter.stringFromDate(shift.startTime)
        
        formatter.dateStyle = .NoStyle
        formatter.timeStyle = .ShortStyle
        formatter.timeZone = NSTimeZone()
        
        let startDifference = startTime.timeIntervalSinceDate(shift.startTime)
        let endDifference = endTime.timeIntervalSinceDate(shift.endTime)
        
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        if repeatingSchedule.count > 0 {
            let editAll = UIAlertAction(title: "Edit All", style: .Destructive) { (action) in
                self.editShift(self.shift)

                for shift in self.repeatingSchedule {
                    self.startTime = shift.startTime.dateByAddingTimeInterval(startDifference)
                    self.endTime = shift.endTime.dateByAddingTimeInterval(endDifference)
            
                    self.editShift(shift)
                }
                
                self.resolveConflicts()
            }
            
            let start = formatter.stringFromDate(shift.startTime)
            let end = formatter.stringFromDate(shift.endTime)
            let message = String(format: "\n%@\n%@ - %@\n", day, start, end)
            
            alertController.message = message
            alertController.title = alertTitle
            alertController.addAction(editAll)
            
            editTitle = "Edit this shift only"
        }
        
        let edit = UIAlertAction(title: editTitle, style: .Destructive) { (action) in
            self.editShift(self.shift)
            self.resolveConflicts()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            
        }
        
        alertController.addAction(edit)
        alertController.addAction(cancel)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func addWeeklySchedule() {
        var shifts = [NSDate]()
        let startRepeat = startTime
        
        if let repeatSettings = self.repeatSettings as? RepeatWeekly  {
            var repeatArray = repeatSettings.getRepeat()
            
            var row = repeatSettings.repeatEvery - 1
            
            let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
            var difference = calendar.components(NSCalendarUnit.CalendarUnitDay, fromDate: startRepeat, toDate: repeatSettings.endDate, options: nil).day + 1
            
            var offset = 0 - repeatSettings.daySelectedIndex
            
            while offset <= difference {
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
        
        var shiftStartTime = startTime
        var shiftEndTime = endTime
        
        for shift in shifts {
            var difference = shiftEndTime.timeIntervalSinceDate(shiftStartTime)
            
            shiftStartTime = shift
            shiftEndTime = shiftStartTime.dateByAddingTimeInterval(difference)
            
            addShift(shiftStartTime, shiftEndTime: shiftEndTime)
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
        
        conflicts += dataManager.fetch("ScheduledShift", predicate: predicate, sortDescriptors: sortDescriptors) as! [ScheduledShift]
    }
    
    func resolveConflicts() {
        if conflicts.count == 0 {
            handleNotifications()
            navigationController?.popViewControllerAnimated(true)
        } else {
            var conflictsMessage = "\n"
            
            for conflict in conflicts {
                let date = NSDateFormatter.localizedStringFromDate(conflict.startTime, dateStyle: .MediumStyle, timeStyle: .NoStyle)
                let start = NSDateFormatter.localizedStringFromDate(conflict.startTime, dateStyle: .NoStyle, timeStyle: .ShortStyle)
                let end = NSDateFormatter.localizedStringFromDate(conflict.endTime, dateStyle: .NoStyle, timeStyle: .ShortStyle)

                conflictsMessage += String(format: "%@, %@ - %@\n", date, start, end)
            }
        
            let message = String(format: "\nReplace the following schedule: \n%@", conflictsMessage)
            
            var title = "\(conflicts.count) Schedule Conflict"
            var replaceTitle = "Replace"
            
            if conflicts.count > 1 {
                title += "s"
                replaceTitle += " All (\(conflicts.count))"
            }
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            let replace = UIAlertAction(title: replaceTitle, style: .Destructive) { (action) in
                for conflict in self.conflicts {
                    self.dataManager.delete(conflict)
                }
                
                self.handleNotifications()
                self.navigationController?.popViewControllerAnimated(true)
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
    
    func datePickerChanged(label: UILabel, datePicker: UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        label.text = dateFormatter.stringFromDate(datePicker.date)

        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        if datePicker == startDatePicker {
            endDatePicker.date = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitMinute, value: minutes, toDate: datePicker.date, options: nil)!
            endDatePicker.date = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitHour, value: hours, toDate: endDatePicker.date, options: nil)!
            endLabel.text = dateFormatter.stringFromDate(endDatePicker.date)
            
            startTime = datePicker.date
            endTime = endDatePicker.date
        
            let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
            let myComponents = cal!.components(NSCalendarUnit.CalendarUnitWeekday, fromDate: datePicker.date)
            repeatSettings.daySelectedIndex = myComponents.weekday - 1
            
            toggleLabelColor()
            
        } else if datePicker == endDatePicker {
            let dateComponents = calendar.components(NSCalendarUnit.CalendarUnitMinute, fromDate: startDatePicker.date, toDate: endDatePicker.date, options: nil)
            let duration = dateComponents.minute
            let maxDuration = 1440
            
            hours = duration / 60
            minutes = duration % 60
            
            validateDuration()
            hoursTextField.text = String(hours)
            minutesTextField.text = String(minutes)

            if duration >= maxDuration {
                datePicker.date = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitMinute, value: maxDuration, toDate: startDatePicker.date, options: nil)!
                label.text = dateFormatter.stringFromDate(datePicker.date)
            }
            
            endTime = datePicker.date
            startTime = startDatePicker.date
            
            toggleLabelColor()
        }
        
        repeatSettings.startDate = startTime
        
        toggleSaveButton()
    }
    
    func toggleLabelColor() {
        if endDatePicker.date.compare(startDatePicker.date) == NSComparisonResult.OrderedAscending {
            endLabel.textColor = UIColor.redColor()
        } else {
            endLabel.textColor = UIColor.darkGrayColor()
        }
    }
    
    func deleteRepeats() {
        let alertTitle = "Warning!\nThis will delete instances of the following shift EXCEPT this one.\nThis action cannot be undone."
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "EEEE"
        
        let day = formatter.stringFromDate(shift.startTime)
    
        formatter.dateStyle = .NoStyle
        formatter.timeStyle = .ShortStyle
        formatter.timeZone = NSTimeZone()
        
        let start = formatter.stringFromDate(shift.startTime)
        let end = formatter.stringFromDate(shift.endTime)
        let message = String(format: "\n%@\n%@ - %@\n", day, start, end)
        
        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)

        let app = UIApplication.sharedApplication()
        
        let deleteALL = UIAlertAction(title: "All Similar Shifts (\(repeatingSchedule.count))", style: .Destructive) { (action) in
            for shift in self.repeatingSchedule {
                self.dataManager.delete(shift)
            }
            
            self.repeatingSchedule = []
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
        
        alertController.addAction(deleteALL)
        
        var futureRepeatingSchedule = [ScheduledShift]()
        
        for repeatShift in repeatingSchedule {
            if shift.startTime.compare(repeatShift.startTime) == NSComparisonResult.OrderedAscending {
                futureRepeatingSchedule.append(repeatShift)
            }
        }
        
        if futureRepeatingSchedule.count > 0 && futureRepeatingSchedule.count != repeatingSchedule.count {
            let deleteFuture = UIAlertAction(title: "Future Similar Shifts (\(futureRepeatingSchedule.count))", style: .Destructive) { (action) in
                for shift in futureRepeatingSchedule {
                    self.dataManager.delete(shift)
                }
                
                self.repeatingSchedule = self.dataManager.fetchRepeatingSchedule(self.shift)
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
            
            alertController.addAction(deleteFuture)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            
        }
        
        alertController.addAction(cancel)
        
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    
    
    // MARK: - Tableview DataSource & Delegate
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 1 {
            return false
        }
        
        return true
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 2 && indexPath.row == 0 {
            togglePicker("startDate")
        } else if indexPath.section == 2 && indexPath.row == 2 {
            togglePicker("endDate")
        } else {
            togglePicker("Close")
        }
        
        if indexPath.section == 4 {
            deleteRepeats()
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 && isJobListEmpty {
            return ""
        }
        
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 && isJobListEmpty {
            return ""
        }
        
        return super.tableView(tableView, titleForFooterInSection: section)
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if isJobListEmpty {
            if indexPath.section == 0 {
                return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
            } else {
                return 0
            }
        } else {
            if startDatePickerHidden && indexPath.section == 2 && indexPath.row == 1 {
                return 0
            } else if endDatePickerHidden && indexPath.section == 2 && indexPath.row == 3 {
                return 0
            }
            
            if repeatLabel.text == "Never" && indexPath.section == 3 && indexPath.row == 1 {
                return 0
            }
            
            if isNewSchedule {
                if indexPath.section == 4 {
                    return 0
                }
            } else {
                if repeatingSchedule.count > 0 && indexPath.section == 3 {
                    return 0
                } else if repeatingSchedule.count == 0 && indexPath.section == 4 {
                    return 0
                }
            }
            
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "selectJob" {
            let destinationVC = segue.destinationViewController as! JobsListTableViewController
            destinationVC.previousSelection = job
            destinationVC.source = "addSchedule"
        } else if segue.identifier == "setRepeat" {
            let destinationVC = segue.destinationViewController as! SetRepeatTableViewController
            
            destinationVC.selectedDay = startTime
            destinationVC.repeatSettings = self.repeatSettings
            
        } else if segue.identifier == "setEndRepeat" {
            let destinationVC = segue.destinationViewController as! EndRepeatTableViewController
            
            destinationVC.startDate = repeatSettings.startDate
            destinationVC.endDate = repeatSettings.endDate
        }
    }
    
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == "selectJob" {
            if isJobListEmpty {
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


// MARK: - TextField Delegate

extension AddScheduleTableViewController: UITextFieldDelegate {
    
    func textFieldDidChange(textField: UITextField) {
        if textField == hoursTextField {
            if let input = hoursTextField.text.toInt() {
                hours = input
            } else {
                hours = 0
            }
        } else if textField == minutesTextField {
            if let input = minutesTextField.text.toInt() {
                if input >= 60 {
                    hours += input / 60
                    minutes = input % 60
                } else {
                    minutes = input
                }
            } else {
                minutes = 0
            }
        }
        
        validateDuration()
        hoursTextField.text = String(hours)
        minutesTextField.text = String(minutes)

        datePickerChanged(startLabel, datePicker: startDatePicker)
        
        toggleSaveButton()
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.becomeFirstResponder()
        textField.selectedTextRange = textField.textRangeFromPosition(textField.beginningOfDocument, toPosition: textField.endOfDocument)
    }
    

}