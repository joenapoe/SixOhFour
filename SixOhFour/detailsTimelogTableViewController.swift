//
//  detailsTimelogTableViewController.swift
//  SixOhFour
//
//  Created by joenapoe
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class detailsTimelogViewController: UITableViewController {

    @IBOutlet weak var jobColorDisplay: JobColorView!
    @IBOutlet weak var jobLabel: UILabel!
    @IBOutlet weak var entryLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var timestampPicker: UIDatePicker!
    @IBOutlet weak var minTimeLabel: UILabel!
    @IBOutlet weak var maxTimeLabel: UILabel!
    
    var entrySelectedIndex : Int = -1

    var jobLabelDisplay = ""
    var jobColorDisplayPassed : UIColor!
    var doneButton : UIBarButtonItem!
    var noMinDate : Bool = false
    var noMaxDate : Bool = false
    var hideTimePicker : Bool = true

    
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var nItem : TimeLogs! // will change from pushed data Segue
    
    var nItemPrevious : TimeLogs! // will change from pushed data Segue

    var nItemNext : TimeLogs! // will change from pushed data Segue

    override func viewDidLoad() {
        super.viewDidLoad()
        
        jobColorDisplay.color = jobColorDisplayPassed
        jobLabel.text = jobLabelDisplay
        entryLabel.text = nItem!.timelogTitle
        timestampLabel.text = nItem!.timelogTimestamp
        commentTextField.text = nItem!.timelogComment

        
        doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: "doneSettingDetails")
        self.navigationItem.rightBarButtonItem = doneButton

        
        //Calculate Minimum date (convert String to NSDate)
        let entryDateString = nItem.timelogTimestamp
        let dateFormatterEntry = NSDateFormatter()
        dateFormatterEntry.dateFormat = "MMM dd, yyyy, hh:mm:ss aa"
        let entryDate = dateFormatterEntry.dateFromString(entryDateString)
        timestampPicker.date = entryDate!

        datePickerChanged(timestampLabel!, datePicker: timestampPicker!)
        
        if noMinDate == true {
            //No Minimum Data
            println("FIRST ENTRY CHOOSEN = no min date")

        } else {
            //Calculate Minimum date (convert String to NSDate)
            let minDateString = nItemPrevious.timelogTimestamp
            let dateFormatterMin = NSDateFormatter()
            dateFormatterMin.dateFormat = "MMM dd, yyyy, hh:mm:ss aa"
            let minDate = dateFormatterMin.dateFromString(minDateString)
            print("minDate = \(minDate)")
            timestampPicker.minimumDate = minDate
            println("timestampPicker.minimumDate \(timestampPicker.minimumDate!)")
        }

        if noMaxDate == true {
            //No NextTimeStamp for Maxium Data
            timestampPicker.maximumDate = NSDate()
            println("LAST ENTRY CHOOSEN = NSDATE used")
        } else {
            //Calculate Maximum date (convert String to NSDate)

                println(nItemNext)
            let maxDateString = nItemNext.timelogTimestamp
            let dateFormatterMin = NSDateFormatter()
            dateFormatterMin.dateFormat = "MMM dd, yyyy, hh:mm:ss aa"
            let maxDate = dateFormatterMin.dateFromString(maxDateString)
            print("maxDate = \(maxDate)")
            timestampPicker.maximumDate = maxDate
            println("timestampPicker.maximumDate \(timestampPicker.maximumDate!)")
        }
        
        
    }
    
    override func viewDidAppear(animated: Bool) {

    }
    
    @IBAction func timestampChanged(sender: AnyObject) {
        datePickerChanged(timestampLabel!, datePicker: timestampPicker!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func editItem() {
        nItem!.timelogJob = jobLabel.text!
        nItem!.timelogTitle = entryLabel.text!
        nItem!.timelogTimestamp = timestampLabel.text!
        nItem!.timelogComment = commentTextField.text
        println(nItem)
        context!.save(nil)
    }
    
    func doneSettingDetails () {
        editItem()
        println(nItem)
        self.performSegueWithIdentifier("unwindFromDetailsTimelogViewController", sender: self)
    }

// MARK: - Date Picker

func datePickerChanged(label: UILabel, datePicker: UIDatePicker) {
    
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
    dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
    
    label.text = dateFormatter.stringFromDate(datePicker.date)

    

}


override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    if indexPath.row == 2 {
        if hideTimePicker == true {
            hideTimePicker(false)
            hideTimePicker = false
        } else {
            hideTimePicker(true)
            hideTimePicker = true
        }
        
    } else {
        println(indexPath.row)
        hideTimePicker(true)
        hideTimePicker = true
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
            minTimeLabel.hidden = false
            maxTimeLabel.hidden = false
            hideTimePicker = false
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
}


    