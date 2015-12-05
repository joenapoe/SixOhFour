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
    
    var startDatePickerHidden = true
    var endDatePickerHidden = true
    var startDate: NSDate!
    var endDate: NSDate!
    var startDateMidnight: NSDate!
    var endDateMidnightNextDay: NSDate!
    var dataManager = DataManager()
    var allWorkedShifts = [WorkedShift]()
    var selectedJob : Job!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
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
        calculatePayDaysAgo()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        calcWorkTime()
        calculatePayDaysAgo()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBActions
    
    @IBAction func startDatePickerValue(sender: AnyObject) {
        datePickerChanged(startDetailLabel, datePicker: startDatePicker)
    }
    
    @IBAction func endDatePickerValue(sender: AnyObject) {
        datePickerChanged(endDetailLabel, datePicker: endDatePicker)
    }
    
    @IBAction func individualButton(sender: AnyObject) {
        self.performSegueWithIdentifier("showIndividual", sender: self)
        
    }
    
    @IBAction func unwindShift (segue: UIStoryboardSegue) {
        tableView.reloadData()
    }
    
    // MARK: - Class Functions
    
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
        calculatePayDaysAgo()
    }
    
    func pullShiftsInTimeFrame() {
        allWorkedShifts = []
        let predicateRunning = NSPredicate(format: "status != 2 || status != 1")
        let predicateTypeJob = NSPredicate(format: "self.job == %@", selectedJob)
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .LongStyle
        formatter.timeZone = NSTimeZone()
        
        startDateMidnight = makeDateMidnight(startDate)
        endDateMidnightNextDay = makeDateMidnight(endDate).dateByAddingTimeInterval(60*60*24)
        
        let predicateTime = NSPredicate(format: "startTime >= %@ && startTime <= %@", startDateMidnight , endDateMidnightNextDay )
        let compoundPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([predicateTime, predicateTypeJob, predicateRunning])
        
        var sortNSDATE = NSSortDescriptor(key: "startTime", ascending: true)
        
        allWorkedShifts = dataManager.fetch("WorkedShift", predicate: compoundPredicate, sortDescriptors: [sortNSDATE] ) as! [WorkedShift]
    }
    
    func makeDateMidnight(date: NSDate) -> NSDate{
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let dateComponents = calendar.components(NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay, fromDate: date)
        dateComponents.setValue(0, forComponent: NSCalendarUnit.CalendarUnitHour)
        dateComponents.setValue(0, forComponent: NSCalendarUnit.CalendarUnitMinute)
        dateComponents.setValue(0, forComponent: NSCalendarUnit.CalendarUnitSecond)
        dateComponents.setValue(0, forComponent: NSCalendarUnit.CalendarUnitNanosecond)
        var date2 = calendar.dateFromComponents(dateComponents)
        return date2!
    }
    
    func calcWorkTime() {
        
        var totalTime = 0.0
        var regTotalTime = 0.0
        var oTTotalTime = 0.0
        
        pullShiftsInTimeFrame()
        
        for shift in allWorkedShifts {
            var partialTime = shift.hoursWorked()
            totalTime += partialTime
            
            var oTPartialTime = shift.hoursWorkedOT()
            oTTotalTime += oTPartialTime
            
            var regPartialTime = shift.hoursWorkedReg()
            regTotalTime += regPartialTime
        }
        
        regularHoursLabel.text = "\(regTotalTime)"
        overtimeHoursLabel.text = "\(oTTotalTime)"
        totalHoursLabel.text = "\(totalTime)"
    }
    
    func calculatePayDaysAgo() {
        
        var totalPay = 0.00
        pullShiftsInTimeFrame()
        
        for shift in allWorkedShifts {
            var partialPay = shift.moneyShiftOTx2()
            totalPay += partialPay
        }
        earningsLabel.text = "$\(totalPay)"
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
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if indexPath.section == 2 && indexPath.row == 0 {
            togglePicker("startDate")
        } else if indexPath.section == 2 && indexPath.row == 2 {
            togglePicker("endDate")
        } else {
            togglePicker("close")
        }
    }
    
    // MARK: - Tableview Headers
    
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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showIndividual" {
            let destinationVC = segue.destinationViewController as! DailyTimesheetTableViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            
            pullShiftsInTimeFrame()
            destinationVC.startDate = startDateMidnight
            destinationVC.endDate = endDateMidnightNextDay
            destinationVC.selectedJob = selectedJob
        }
    }
    
}
