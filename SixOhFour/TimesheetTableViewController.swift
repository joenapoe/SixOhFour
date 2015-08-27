//
//  TimesheetTableViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 8/14/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class TimesheetTableViewController: UITableViewController {
    
    @IBOutlet var regularHoursLabel: UILabel!
    @IBOutlet var overtimeHoursLabel: UILabel!
    @IBOutlet var totalHoursLabel: UILabel!
    @IBOutlet var earningsLabel: UILabel!
    @IBOutlet var startDetailLabel: UILabel!
    @IBOutlet var endDetailLabel: UILabel!
    @IBOutlet var startDatePicker: UIDatePicker!
    @IBOutlet var endDatePicker: UIDatePicker!
    
    @IBAction func startDatePickerValue(sender: AnyObject) {
        datePickerChanged(startDetailLabel, datePicker: startDatePicker)
    }
    
    @IBAction func endDatePickerValue(sender: AnyObject) {
        datePickerChanged(endDetailLabel, datePicker: endDatePicker)
    }
    
    var startDatePickerHidden = true
    var endDatePickerHidden = true
    
    var startDate: NSDate!
    var endDate: NSDate!
    
    var dataManager = DataManager()
    var allWorkedShifts = [WorkedShift]()
    var selectedJob : Job!
    var totalTime = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Timesheet"
        
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        endDate = NSDate()
        endDatePicker.date = endDate
        startDate = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: -6, toDate: endDate, options: nil)
        startDatePicker.date = startDate
        
        startDatePicker.maximumDate = NSDate()
        endDatePicker.maximumDate = NSDate()

        
        datePickerChanged(startDetailLabel, datePicker: startDatePicker)

        tableView.dataSource = self
        tableView.delegate = self
        
        
        calcWorkTime()
        totalHoursLabel.text = "\(totalTime)"
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 50
        } else if indexPath.section == 2 && indexPath.row == 1 {
            if startDatePickerHidden {
                return 0
            } else {
                return 162
            }
        } else if indexPath.section == 2 && indexPath.row == 3 {
            if endDatePickerHidden {
                return 0
            } else {
                return 162
            }
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            togglePicker("startDate")
        } else if indexPath.section == 2 && indexPath.row == 2 {
            togglePicker("endDate")
        } else {
            togglePicker("close")
        }
    }
    
    
    // Tableview Headers
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel.textAlignment = NSTextAlignment.Justified
        
        if section == 0 {
            header.textLabel.text = "Hours"
        } else if section == 1 {
            header.textLabel.text = "Earnings"
        } else if section == 2 {
            header.textLabel.text = "Timesheet"
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 30
        } else {
            return 35
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    func datePickerChanged(label: UILabel, datePicker: UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        label.text = dateFormatter.stringFromDate(datePicker.date)
        
        if datePicker == startDatePicker {
            if datePicker.date.compare(endDatePicker.date) == NSComparisonResult.OrderedDescending {
                endDetailLabel.text = label.text
                endDatePicker.date = datePicker.date
            } else {
                endDetailLabel.text = dateFormatter.stringFromDate(endDatePicker.date)
            }
            
            startDate = datePicker.date
            endDate = endDatePicker.date
        }
        
        if datePicker == endDatePicker {
            if datePicker.date.compare(startDatePicker.date) == NSComparisonResult.OrderedAscending {
                startDetailLabel.text = label.text
                startDatePicker.date = datePicker.date
            } else {
                startDetailLabel.text = dateFormatter.stringFromDate(startDatePicker.date)
            }
            endDate = datePicker.date
            startDate = startDatePicker.date
        }
        
        calcWorkTime()
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
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    func calcWorkTime() {
        
        totalTime = 0.0
        allWorkedShifts = []
        
        let predicateOpenWS = NSPredicate(format: "workedShift.job == %@ && type == %@", selectedJob, "Clocked In")
 
        let predicateCI = NSPredicate(format: "time >= %@ && time <= %@", startDatePicker.date, endDatePicker.date )
        let compoundPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([predicateCI, predicateOpenWS])
        
        var sortNSDATE = NSSortDescriptor(key: "time", ascending: true)
        
        var openShiftsCIs = dataManager.fetch("Timelog", predicate: compoundPredicate, sortDescriptors: [sortNSDATE] ) as! [Timelog]
        
        for timelog in openShiftsCIs {
            allWorkedShifts.append(timelog.workedShift)
        }
        
        for shift in allWorkedShifts {
            var partialTime = shift.hoursWorked()
            totalTime += partialTime
        }
        
        totalHoursLabel.text = "\(totalTime)"
    }
    
}
