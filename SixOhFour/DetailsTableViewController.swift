//
//  DetailsTableViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/13/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class DetailsTableViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var jobColorDisplay: JobColorView!
    @IBOutlet weak var jobLabel: UILabel!
    @IBOutlet weak var entryLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var timestampPicker: UIDatePicker!
    @IBOutlet weak var minTimeLabel: UILabel!
    @IBOutlet weak var maxTimeLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    
    var doneButton : UIBarButtonItem!
    
    //PUSHED IN DATA when segued
    var selectedJob : Job!
    var hasMinDate = false
    var hasMaxDate = false
    var selectedTimelog : Timelog!
    var previousTimelog : Timelog!
    var nextTimelog : Timelog!

    var hideTimePicker = true
    var conflicts : [WorkedShift] = []
    
    let dataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        entryLabel.text = selectedTimelog.type
        timestampLabel.text = "\(selectedTimelog.time)"
        minTimeLabel.hidden = true
        commentTextView.text = selectedTimelog.comment
        commentTextView.delegate = self
        
        doneButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "checkAndSave")
        self.navigationItem.rightBarButtonItem = doneButton
        var cancelButton = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelDetails")
        self.navigationItem.leftBarButtonItem = cancelButton
        
        timestampPicker.date = selectedTimelog.time
        
        datePickerChanged(timestampLabel!, datePicker: timestampPicker!)
        
        var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        
        if hasMinDate { //Previous timelog aka Minimum Data
            timestampPicker.minimumDate = previousTimelog.time
            minTimeLabel.text = "\(previousTimelog.type): \(dateFormatter(previousTimelog.time))"
        } else {
            timestampPicker.minimumDate = selectedTimelog.time.dateByAddingTimeInterval(-24*60*60)
            minTimeLabel.text = "Can not exceed 24hrs" //TODO: User can go back 24hr, then repeat and repeat. 1 at a time.
        }
        
        if hasMaxDate {
            timestampPicker.maximumDate = nextTimelog.time
            maxTimeLabel.text = "\(nextTimelog.type): \(dateFormatter(nextTimelog.time))"
        } else { //No NextTimeStamp for Max Data
            
            let predicateStatus = NSPredicate(format: "status == 2")
            var runningShift = [WorkedShift]()
            runningShift = dataManager.fetch("WorkedShift", predicate: predicateStatus) as! [WorkedShift]
            
            if runningShift.count == 0 || selectedTimelog.workedShift.status == 2 { //If there are no running shifts, or if you've selected the current running shift
                timestampPicker.maximumDate = NSDate()
                maxTimeLabel.text = "Cannot select a future time."
            } else {
                timestampPicker.maximumDate = runningShift[0].startTime //TODO - THIS IS NOT RESTRICITING MAX DATE!
                maxTimeLabel.text = "Cannot pass the current running shift."
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        jobLabel.text = selectedJob.company
        positionLabel.text = selectedJob.position
        jobColorDisplay.color = selectedJob.color.getColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func timestampChanged(sender: AnyObject) {
        datePickerChanged(timestampLabel!, datePicker: timestampPicker!)
        
        if (timestampPicker.date.compare(timestampPicker.minimumDate!)) == NSComparisonResult.OrderedAscending || timestampPicker.date == timestampPicker.minimumDate {
            minTimeLabel.hidden = false
            timestampLabel.text = "\(dateFormatter(timestampPicker.minimumDate!))"
        }
        
        if timestampPicker.date.timeIntervalSinceNow > -120 || timestampPicker.date.timeIntervalSinceDate(timestampPicker.maximumDate!) > -60 {
            maxTimeLabel.hidden = false
        }
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        commentTextView.resignFirstResponder()
        return true
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        commentTextView.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    func dismissKeyboard(){
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.view.endEditing(true)
    }
    
    func saveAndUnwindDetails() {
        selectedTimelog.type = entryLabel.text!
        selectedTimelog.time = timestampPicker.date
        selectedTimelog.comment = commentTextView.text
        selectedTimelog.lastUpdate = NSDate()
        if selectedTimelog.type == "Clocked In" {
            selectedTimelog.workedShift.startTime = timestampPicker.date
        } else if selectedTimelog.type == "Clocked Out" {
            selectedTimelog.workedShift.endTime = timestampPicker.date
        }
        if hasMinDate && (timestampPicker.date.compare(timestampPicker.minimumDate!) == NSComparisonResult.OrderedAscending) {
            selectedTimelog.time = timestampPicker.minimumDate!
        } else {
            selectedTimelog.time = timestampPicker.date
        }
        dataManager.save()
        self.performSegueWithIdentifier("unwindSaveDetailsTVC", sender: self)
    }
    
    func checkAndSave() {
        if selectedTimelog.type == "Clocked In" || selectedTimelog.type == "Clocked Out" {
                checkConflicts(selectedTimelog.workedShift)
        }

        if conflicts.count == 0 {
            saveAndUnwindDetails()
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
                self.saveAndUnwindDetails()
            }
            alertController.addAction(replace)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func cancelDetails() {
        self.performSegueWithIdentifier("unwindCancelDetailsTVC", sender: self)
    }
    
    func checkConflicts(shift: WorkedShift) {
        
        var startOfShift = NSDate()
        var endOfShift = NSDate()
        
        if selectedTimelog.type == "Clocked In" {
            startOfShift = timestampPicker.date

            if shift.endTime.timeIntervalSinceReferenceDate < startOfShift.timeIntervalSinceReferenceDate {
                endOfShift = timestampPicker.date
            } else {
                endOfShift = shift.endTime
            }
        } else if selectedTimelog.type == "Clocked Out" {
            startOfShift = shift.startTime
            endOfShift = timestampPicker.date
        }
        
        var startPredicate = NSPredicate(format: "startTime < %@ AND %@ < endTime", startOfShift, startOfShift)
        var selfPredicate = NSPredicate(format: "SELF != %@", shift)
        var predicate: NSCompoundPredicate
        
        if selectedTimelog.workedShift.status == 1 || selectedTimelog.workedShift.status == 2 {
            predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [startPredicate, selfPredicate])
        } else {
            let endPredicate = NSPredicate(format: "startTime < %@ AND %@ < endTime", endOfShift, endOfShift)
            let startPredicate1 = NSPredicate(format: "%@ < startTime AND startTime < %@", startOfShift, endOfShift)
            let endPredicate2 = NSPredicate(format: "%@ < endTime AND endTime < %@", startOfShift, endOfShift)
            let shiftPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType,
                subpredicates: [startPredicate, endPredicate, startPredicate1, endPredicate2])
            predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [shiftPredicate, selfPredicate])
        }
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: true)
        let sortDescriptors = [sortDescriptor]
        
        conflicts = []
        conflicts = dataManager.fetch("WorkedShift", predicate: predicate, sortDescriptors: sortDescriptors) as! [WorkedShift]
    }
    
    // MARK: - Date Picker
    
    func datePickerChanged(label: UILabel, datePicker: UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
        label.text = dateFormatter.stringFromDate(datePicker.date)
    }
    
    func hideTimePicker(status: Bool) {
        if status {
            timestampPicker.hidden = true
            minTimeLabel.hidden = true
            maxTimeLabel.hidden = true
            hideTimePicker = true
        } else {
            timestampPicker.hidden = false
            hideTimePicker = false
        }
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func dateFormatter (timestamp: NSDate) -> String {
        // NOTE: Convert from NSDate to regualer
        let dateString = NSDateFormatter.localizedStringFromDate( timestamp , dateStyle: .MediumStyle, timeStyle: .MediumStyle)
        return dateString
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        commentTextView.resignFirstResponder()
        
        if hideTimePicker == false {
            hideTimePicker(true)
            hideTimePicker = true
        } else if indexPath.row == 1 && hideTimePicker {
            hideTimePicker(false)
            hideTimePicker = false
        } else if indexPath.row == 0 {
            let addJobStoryboard: UIStoryboard = UIStoryboard(name: "CalendarStoryboard", bundle: nil)
            let jobsListVC: JobsListTableViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("JobsListTableViewController")
                as! JobsListTableViewController
            jobsListVC.source = "details"
            jobsListVC.previousSelection = self.selectedJob
            
            self.navigationController?.pushViewController(jobsListVC, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if hideTimePicker && indexPath.row == 2 {
            hideTimePicker(true)
            return 0
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    //MARK: Segues
    @IBAction func unwindFromJobsListTableViewControllerToDetails (segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! JobsListTableViewController
        selectedJob = sourceVC.selectedJob
        if sourceVC.selectedJob != nil {
            selectedJob = sourceVC.selectedJob
            jobColorDisplay.color = selectedJob.color.getColor
        }
    }
}