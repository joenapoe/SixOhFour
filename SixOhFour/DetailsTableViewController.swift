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
    
    let dataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        entryLabel.text = selectedTimelog.type
        timestampLabel.text = "\(selectedTimelog.time)"
        minTimeLabel.hidden = true
        commentTextView.text = selectedTimelog.comment
        commentTextView.delegate = self
        
        doneButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "saveDetails")
        self.navigationItem.rightBarButtonItem = doneButton
        var cancelButton = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelDetails")
        self.navigationItem.leftBarButtonItem = cancelButton
        
        timestampPicker.date = selectedTimelog.time
        
        datePickerChanged(timestampLabel!, datePicker: timestampPicker!)
        
        var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        
        // TODO : Need to set restrictions of 24hrs when picking times for both min and max. Hurdle = how are you going to handle when the WS only has 1 entry CI.. what is the min?
        if !hasMinDate {
            //No Minimum Data
            minTimeLabel.text = ""
        } else {
            timestampPicker.minimumDate = previousTimelog.time
            minTimeLabel.text = "\(previousTimelog.type): \(dateFormatter(previousTimelog.time))"
        }
        
        // TODO : Need to set restrictions of 24hrs when picking times for both min and max
        if !hasMaxDate {
            //No NextTimeStamp for Maxium Data
            //And no MinDate to set 24hr restriction
            
            if selectedTimelog.type == "Clocked Out" {
                timestampPicker.maximumDate = NSDate().dateByAddingTimeInterval(8*60*60)
                maxTimeLabel.text = "Cannot exceed 8 hrs from now."
            } else {
                timestampPicker.maximumDate = NSDate()
                maxTimeLabel.text = "Cannot select a future time."
            }
        } else {
            timestampPicker.maximumDate = nextTimelog.time
            maxTimeLabel.text = "\(nextTimelog.type): \(dateFormatter(nextTimelog.time))"
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        jobLabel.text = selectedJob.company.name
        positionLabel.text = selectedJob.position
        jobColorDisplay.color = selectedJob.color.getColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func timestampChanged(sender: AnyObject) {
        
        datePickerChanged(timestampLabel!, datePicker: timestampPicker!)
        
        if !hasMinDate {
            //need to add code that prevents the user from selecting a date that exceeds theyre previous shift
        } else {
            if (timestampPicker.date.compare(timestampPicker.minimumDate!)) == NSComparisonResult.OrderedAscending || timestampPicker.date == timestampPicker.minimumDate {
                minTimeLabel.hidden = false
                timestampLabel.text = "\(dateFormatter(timestampPicker.minimumDate!))"
            }
        }
        
        if !hasMaxDate {
            if timestampPicker.date.timeIntervalSinceNow > -120 {
                maxTimeLabel.hidden = false
            }
        } else {
            if timestampPicker.date.timeIntervalSinceDate(timestampPicker.maximumDate!) > -60 {
                maxTimeLabel.hidden = false
            }
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
    
    
    func saveDetails() {
        
        selectedTimelog.type = entryLabel.text!
        selectedTimelog.time = timestampPicker.date
        selectedTimelog.comment = commentTextView.text
        selectedTimelog.lastUpdate = NSDate()
        if selectedTimelog.type == "Clocked In" {
            selectedTimelog.workedShift.startDate = timestampPicker.date
        }
        if hasMinDate && (timestampPicker.date.compare(timestampPicker.minimumDate!) == NSComparisonResult.OrderedAscending) {
            selectedTimelog.time = timestampPicker.minimumDate!
        } else {
            selectedTimelog.time = timestampPicker.date
        }
        
        dataManager.save()
        
        self.performSegueWithIdentifier("unwindSaveDetailsTVC", sender: self)
    }
    
    func cancelDetails() {
        self.performSegueWithIdentifier("unwindCancelDetailsTVC", sender: self)
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
        } else if indexPath.row == 2 && hideTimePicker {
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
        
        if hideTimePicker && indexPath.row == 3 {
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