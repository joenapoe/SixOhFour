//
//  EndRepeatTableViewController.swift
//  SixOhFour
//
//  Created by Jem on 7/22/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class EndRepeatTableViewController: UITableViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var neverCell: UITableViewCell!
    @IBOutlet weak var onDateCell: UITableViewCell!
    @IBOutlet weak var endDateLabel: UILabel!
    
    var startDate: NSDate!
    var endDate: NSDate!
    var doneButton: UIBarButtonItem!
    
    var backButtonTitle = ""
    var pickerHidden = true

    override func viewDidLoad() {
        super.viewDidLoad()

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        endDateLabel.text = dateFormatter.stringFromDate(endDate)
        
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let maxDate = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitMonth, value: 12, toDate: startDate, options: nil)
        
        datePicker.minimumDate = startDate
        datePicker.maximumDate = maxDate
        datePicker.date = endDate
        
        doneButton = UIBarButtonItem(title:"Done", style: .Plain, target: self, action: "setEndRepeat")
        self.navigationItem.rightBarButtonItem = self.doneButton

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - IB Actions

    @IBAction func datePickerChanged(sender: AnyObject) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        
        endDate = datePicker.date
        endDateLabel.text = dateFormatter.stringFromDate(endDate)
    }
    
    
    // MARK: - Class Functions
    
    func setEndRepeat() {
        self.performSegueWithIdentifier("unwindFromEndRepeatTableViewController", sender: self)
    }
    
    func togglePicker(picker: String) {
        if picker == "onDate" {
            pickerHidden = !pickerHidden
        } else {
            pickerHidden = true
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    // MARK: - Table view data source


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 1 {
            togglePicker("onDate")
            datePickerChanged(self)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        // Unlimited repeat disabled
        if indexPath.row == 0 {
            return 0
        }
    
        if pickerHidden && indexPath.row == 2 {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
}
