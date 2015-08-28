//
//  JobOverviewViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/16/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class JobOverviewViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var calendarView: CVCalendarView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var payLabel: UILabel!
    @IBOutlet weak var regularHoursLabel: UILabel!
    @IBOutlet weak var overtimeLabel: UILabel!
    @IBOutlet weak var totalHoursLabel: UILabel!
    @IBOutlet weak var weekEarningLabel: UILabel!
    @IBOutlet weak var lastThirtyDaysLabel: UILabel!
    @IBOutlet weak var yearToDateLabel: UILabel!
    
    var editButton: UIBarButtonItem!
    var jobs = [Job]()
    var job: Job!
    var company: Company!
    var timelog: Timelog!
    var workedshift: WorkedShift!
    var allWorkedShifts = [WorkedShift]()
//    var totalTime: Double = 0.0
    
    var selectedDate: NSDate!
    var monthSchedule: [ScheduledShift]!
    var daySchedule: [ScheduledShift]!
    var shift: ScheduledShift!
    
    var shouldShowDaysOut = true
    var animationFinished = true
    var currentMonth = CVDate(date: NSDate()).currentMonth
    var dataManager = DataManager()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        editButton = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "editJob")
        self.navigationItem.rightBarButtonItem = editButton
        
        self.title = job.company.name
        
        let unitedStatesLocale = NSLocale(localeIdentifier: "en_US")
        let pay = job.payRate
        var numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        numberFormatter.locale = unitedStatesLocale
        
        monthLabel.text = CVDate(date: NSDate()).monthYear
        nameLabel.text = job.company.name
        positionLabel.text = job.position
        payLabel.text = "\(numberFormatter.stringFromNumber(pay)!)/hr"
        fetchData()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.hidesBottomBarWhenPushed = true
        fetchData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        calendarView.commitCalendarViewUpdate()
        menuView.commitMenuViewUpdate()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5

    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            if indexPath.section == 0 && indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("tsCell", forIndexPath: indexPath) as! UITableViewCell
                return cell
                
            } else if indexPath.section == 0 && indexPath.row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier("startCell", forIndexPath: indexPath) as! UITableViewCell
                return cell
        
            } else if indexPath.section == 0 && indexPath.row == 2 {
                let cell = tableView.dequeueReusableCellWithIdentifier("startDateCell", forIndexPath: indexPath) as! UITableViewCell
                return cell
        
            } else if indexPath.section == 0 && indexPath.row == 3 {
                let cell = tableView.dequeueReusableCellWithIdentifier("endCell", forIndexPath: indexPath) as! UITableViewCell
                return cell
        
            } else if indexPath.section == 0 && indexPath.row == 4 {
                let cell = tableView.dequeueReusableCellWithIdentifier("endDateCell", forIndexPath: indexPath) as! UITableViewCell
                return cell
            
        }
        return UITableViewCell()
    }
    

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

    }
    
    func fetchData() {
        jobs = dataManager.fetch("Job") as! [Job]
        calcWorkTime7Days()
        calculatePayDaysAgo(7, labelName: weekEarningLabel)
        calculatePayDaysAgo(30, labelName: lastThirtyDaysLabel)
        calculatePayYearToDate(yearToDateLabel)
    }

    func calcWorkTime7Days() {
        
        var totalTime = 0.0
        var regTotalTime = 0.0
        var oTTotalTime = 0.0
        allWorkedShifts = []
        
        let predicateCurrent = NSPredicate(format: "workedShift.status != 2")
        let predicateTypeJob = NSPredicate(format: "workedShift.job == %@ && type == %@", job, "Clocked In")
        let predicateTime = NSPredicate(format: " time > %@", NSDate().dateByAddingTimeInterval(-7*24*60*60) )
        let compoundPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([predicateTime, predicateTypeJob, predicateCurrent])
        var sortNSDATE = NSSortDescriptor(key: "time", ascending: true)
        var openShiftsCIs = dataManager.fetch("Timelog", predicate: compoundPredicate, sortDescriptors: [sortNSDATE] ) as! [Timelog]
        for timelog in openShiftsCIs {
            allWorkedShifts.append(timelog.workedShift)
        }
        
        
        for shift in allWorkedShifts {
            var partialTime = shift.hoursWorked()
            totalTime += partialTime
            
            var oTPartialTime = shift.hoursWorkedOT()
            oTTotalTime += oTPartialTime
            
            var regPartialTime = shift.hoursWorkedReg()
            regTotalTime += regPartialTime
        }
        
        regularHoursLabel.text = "\(regTotalTime)"
        overtimeLabel.text = "\(oTTotalTime)"
        totalHoursLabel.text = "\(totalTime)"
        
    }
    
    func calculatePayDaysAgo(daysAgo: Double, labelName: UILabel) {

        var totalPay = 0.00
        allWorkedShifts = []
        
        let predicateCurrent = NSPredicate(format: "workedShift.status != 2")
        let predicateTypeJob = NSPredicate(format: "workedShift.job == %@ && type == %@", job, "Clocked In")
        let predicateTime = NSPredicate(format: "time > %@", NSDate().dateByAddingTimeInterval(-daysAgo*24*60*60) )
        let compoundPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([predicateTime, predicateTypeJob, predicateCurrent])
        var sortNSDATE = NSSortDescriptor(key: "time", ascending: true)
        var openShiftsCIs = dataManager.fetch("Timelog", predicate: compoundPredicate, sortDescriptors: [sortNSDATE] ) as! [Timelog]
        for timelog in openShiftsCIs {
            allWorkedShifts.append(timelog.workedShift)
        }
        for shift in allWorkedShifts {
            var partialPay = shift.moneyShiftOTx2()
            totalPay += partialPay
        }
        labelName.text = "$\(totalPay)"
    }
    
    func calculatePayYearToDate(labelName: UILabel) {
        
        
        let today = NSDate()
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let dateComponents = calendar.components(NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay, fromDate: today)
        
        dateComponents.setValue(1, forComponent: NSCalendarUnit.CalendarUnitMonth)
        dateComponents.setValue(1, forComponent: NSCalendarUnit.CalendarUnitDay)
 
        var date = calendar.dateFromComponents(dateComponents)
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .NoStyle
        formatter.timeZone = NSTimeZone()
        
        var totalPay = 0.00
        allWorkedShifts = []
        
        let predicateCurrent = NSPredicate(format: "workedShift.status != 2")
        let predicateTypeJob = NSPredicate(format: "workedShift.job == %@ && type == %@", job, "Clocked In")
        let predicateTime = NSPredicate(format: "time > %@", date!)
        let compoundPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([predicateTime, predicateTypeJob, predicateCurrent])
        var sortNSDATE = NSSortDescriptor(key: "time", ascending: true)
        var openShiftsCIs = dataManager.fetch("Timelog", predicate: compoundPredicate, sortDescriptors: [sortNSDATE] ) as! [Timelog]
        for timelog in openShiftsCIs {
            allWorkedShifts.append(timelog.workedShift)
        }
        for shift in allWorkedShifts {
            var partialPay = shift.moneyShiftOTx2()
            totalPay += partialPay
        }
        labelName.text = "$\(totalPay)"
    }
    
    
    func calculateRegHours() {
        regularHoursLabel.text = "\(workedshift.duration)"
    }
    
    func editJob() {
        self.performSegueWithIdentifier("editJob", sender: self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editJob" {
            let destinationVC = segue.destinationViewController as! AddJobTableViewController
            destinationVC.navigationItem.title = "Edit Job"
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: nil, action: nil)
            destinationVC.hidesBottomBarWhenPushed = true
            destinationVC.job = self.job
        }
        
        if segue.identifier == "showTimesheet" {
            let destinationVC = segue.destinationViewController as! TimesheetTableViewController
            
//            destinationVC.navigationItem.title = "Edit Job"
//            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: nil, action: nil)
            destinationVC.hidesBottomBarWhenPushed = true
            destinationVC.selectedJob = self.job
        }
    }
    
}


// MARK: - CVCalendarViewDelegate

extension JobOverviewViewController: CVCalendarViewDelegate {
    func presentationMode() -> CalendarMode {
        return .WeekView
    }
    
    func firstWeekday() -> Weekday {
        return .Sunday
    }
    
    func shouldShowWeekdaysOut() -> Bool {
        return true
    }
    
    func didSelectDayView(dayView: CVCalendarDayView) {
  
    }
    
    func presentedDateUpdated(date: CVDate) {
        if monthLabel.text != date.monthYear && self.animationFinished {
            
            currentMonth = date.currentMonth
            let predicate = NSPredicate(format: "startDate contains[c] %@", currentMonth)
            monthSchedule = dataManager.fetch("ScheduledShift", predicate: predicate) as! [ScheduledShift]
            
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
                self.animationFinished = false
                self.monthLabel.transform = CGAffineTransformMakeTranslation(0, -offset)
                self.monthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
                self.monthLabel.alpha = 0
                
                updatedMonthLabel.alpha = 1
                updatedMonthLabel.transform = CGAffineTransformIdentity
                
                }) { _ in
                    
                    self.animationFinished = true
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
        
        var currentMonth = dayView.date.currentMonth
        let monthPredicate = NSPredicate(format: "startDate contains[c] %@", currentMonth)
        let jobPredicate = NSPredicate(format: "job == %@", job)
        
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [monthPredicate, jobPredicate])
        
        var monthSchedule = dataManager.fetch("ScheduledShift", predicate: predicate) as! [ScheduledShift]
        
        //        // TODO: Optimize dotmarker generation
        //        for m in monthSchedule {
        //            println(m.startDate)
        //        }
        
        
        let day = dayView.date.monthDayYear
        var shouldShowDot = false
        
        for s in monthSchedule {
            if day == s.startDate {
                shouldShowDot = true
            }
        }
        
        return shouldShowDot
    }
    
    func dotMarker(colorOnDayView dayView: CVCalendarDayView) -> [UIColor] {
        
        var currentMonth = dayView.date.currentMonth
        let monthPredicate = NSPredicate(format: "startDate contains[c] %@", currentMonth)
        let jobPredicate = NSPredicate(format: "job == %@", job)
        
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [monthPredicate, jobPredicate])
        
        var monthSchedule = dataManager.fetch("ScheduledShift", predicate: predicate) as! [ScheduledShift]
        
        
        let day = dayView.date.monthDayYear
        let color = job.color.getColor
        var numberOfDots = 0
        
        for s in monthSchedule {
            if day == s.startDate {
                numberOfDots++
            }
        }
        
        if numberOfDots == 2 {
            return [color, color]
        } else if numberOfDots >= 3 {
            return [color, color, color]
        } else {
            return [color]
        }
    }
    
    func dotMarker(shouldMoveOnHighlightingOnDayView dayView: CVCalendarDayView) -> Bool {
        return false
    }
}


// MARK: - CVCalendarViewAppearanceDelegate

extension JobOverviewViewController: CVCalendarViewAppearanceDelegate {
    func dayLabelPresentWeekdayInitallyBold() -> Bool {
        return false
    }
    
    func spaceBetweenDayViews() -> CGFloat {
        return 2
    }
}


// MARK: - CVCalendarMenuViewDelegate

extension JobOverviewViewController: CVCalendarMenuViewDelegate {
    // firstWeekday() has been already implemented.
}

