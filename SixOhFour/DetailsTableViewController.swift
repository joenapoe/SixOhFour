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

class DetailsTableViewController: UITableViewController {
    
    @IBOutlet weak var jobColorDisplay: JobColorView!
    @IBOutlet weak var jobLabel: UILabel!
    @IBOutlet weak var entryLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var timestampPicker: UIDatePicker!
    @IBOutlet weak var minTimeLabel: UILabel!
    @IBOutlet weak var maxTimeLabel: UILabel!
    
    //PUSHED IN DATA
    var selectedJob : Job!
    var noMinDate : Bool = false
    var noMaxDate : Bool = false
    var nItem : Timelog! // will change from pushed data Segue
    var nItemPrevious : Timelog! // will change from pushed data Segue
    var nItemNext : Timelog! // will change from pushed data Segue
    
    var doneButton : UIBarButtonItem!
    var hideTimePicker : Bool = true
    var jobLabelDisplay = String() // will change from pushed data Segue
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        println(nItem)
        
        entryLabel.text = nItem.type
        timestampLabel.text = "\(nItem.time)"
        minTimeLabel.hidden = true
        commentTextField.text = nItem.comment
        
        
        doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: "doneSettingDetails")
        self.navigationItem.rightBarButtonItem = doneButton
        
        timestampPicker.date = nItem.time
        
        datePickerChanged(timestampLabel!, datePicker: timestampPicker!)

        
        // TODO : Need to set restrictions of 24hrs when picking times for both min and max
        //Hurdle = how are you going to handle when the WS only has 1 entry CI.. what is the min?
        if noMinDate == true {
            //No Minimum Data
            println("FIRST ENTRY CHOOSEN = no min date")
            minTimeLabel.text = ""
            
        } else {
            
            timestampPicker.minimumDate = nItemPrevious.time
            minTimeLabel.text = "\(nItemPrevious.type): \(dateFormatter(nItemPrevious.time))"
            println("timestampPicker.minimumDate \(timestampPicker.minimumDate!)")
        }
        
        // TODO : Need to set restrictions of 24hrs when picking times for both min and max
//        if noMaxDate == true && noMinDate == true {
        if noMaxDate == true {
            //No NextTimeStamp for Maxium Data
            //And no MinDate to set 24hr restriction
            timestampPicker.maximumDate = NSDate()
            maxTimeLabel.text = "Cannot select a future time."
            
//        } else if noMaxDate == true && nItemPrevious.time > 24hours ago {
//
//            timestampPicker.maximumDate = nItemPrevious.time + 24hours
//            maxTimeLabel.text = "Must be within 24hrs of last entry"
//        
//        } else if noMaxDate == false {

        } else {
            timestampPicker.maximumDate = nItemNext.time
            println("timestampPicker.maximumDate \(timestampPicker.maximumDate!)")
            maxTimeLabel.text = "\(nItemNext.type): \(dateFormatter(nItemNext.time))"
        }
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        jobLabel.text = selectedJob.company.name
        jobColorDisplay.color = selectedJob.color.getColor
    }
    
    @IBAction func timestampChanged(sender: AnyObject) {
        
        datePickerChanged(timestampLabel!, datePicker: timestampPicker!)
        
        if noMinDate == true {
            //need to add code that prevents the user from selecting a date that exceeds theyre previous shift
        } else {
            if (timestampPicker.date.compare(timestampPicker.minimumDate!)) == NSComparisonResult.OrderedAscending || timestampPicker.date == timestampPicker.minimumDate {
                minTimeLabel.hidden = false
                timestampLabel.text = "\(dateFormatter(timestampPicker.minimumDate!))"
            }
        }
        
        
        if noMaxDate == true {
            if timestampPicker.date.timeIntervalSinceNow > -120 {
                maxTimeLabel.hidden = false
            }
        } else {
            if timestampPicker.date.timeIntervalSinceDate(timestampPicker.maximumDate!) > -60 {
                maxTimeLabel.hidden = false
            }
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func editItem() {
        
        nItem.type = entryLabel.text!
        nItem.time = timestampPicker.date
        nItem.comment = commentTextField.text
        nItem.lastUpdate = NSDate()
        println(nItem)
        //        context!.save(nil)
        
        if noMinDate == false && (timestampPicker.date.compare(timestampPicker.minimumDate!)) == NSComparisonResult.OrderedAscending {
            nItem.time = timestampPicker.minimumDate!
        } else {
            nItem.time = timestampPicker.date
        }
        
    }
    
    func doneSettingDetails () {
        editItem()
        println(nItem)
        self.performSegueWithIdentifier("unwindFromDetailsTableViewController", sender: self)
    }
    
    // MARK: - Date Picker
    
    func datePickerChanged(label: UILabel, datePicker: UIDatePicker) {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
        
        label.text = dateFormatter.stringFromDate(datePicker.date)
        
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
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
    
    @IBAction func unwindFromJobsListTableViewController (segue: UIStoryboardSegue) {
        
        let sourceVC = segue.sourceViewController as! JobsListTableViewController
        
        selectedJob = sourceVC.selectedJob
        
        
        // TODO : Need to fix selectedjob in display, label, and core data
        
        if sourceVC.selectedJob != nil {
            selectedJob = sourceVC.selectedJob
            jobColorDisplay.color = selectedJob.color.getColor
        }
        
//        if timelogList != [] {
//            saveWorkedShiftToJob()
//        }
//        
//        updateTable()
//        
    }
    
}

