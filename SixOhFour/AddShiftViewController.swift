//
//  AddShiftViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/22/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class AddShiftViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var addBreakButton: UIButton!
    @IBOutlet var worktimeLabel: UILabel!
    @IBOutlet var timelogTable: UITableView!
    @IBOutlet var earnedLabel: UILabel!
    
    var newShift : WorkedShift!
    var breakCount = 0
    var dataManager = DataManager()
    var breakTLs : [Timelog]!
    var allTLsArrary : [Timelog]!
    
    //Variables for Segue: "showDetails"
    var nItemClockIn : Timelog!
    var nItemClockInPrevious : Timelog!
    var nItemClockInNext : Timelog!
    var selectedJob : Job!
    var noMinDate: Bool = false
    var noMaxDate: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Add Shift"

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: nil)
        
        timelogTable.sectionHeaderHeight = 1.0
        timelogTable.sectionFooterHeight = 1.0
        
        newShift = dataManager.addItem("WorkedShift") as! WorkedShift
        newShift.setValue(3, forKey: "status")
        newShift.job = selectedJob
        
        println(newShift)
        
        var saveButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "saveWS")
        self.navigationItem.rightBarButtonItem = saveButton
        var cancelButton = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelWS")
        self.navigationItem.leftBarButtonItem = cancelButton
        
        allTLsArrary = []
        
        createTLappend("Clocked In")
        createTLappend("Clocked Out")

        worktimeLabel.text = "Work time = \( newShift.hoursWorked() ) hrs"
        earnedLabel.text = "You earned $\( newShift.moneyShiftOTx2()) for this shift"
    }
    
    override func viewDidAppear(animated: Bool) {
        selectedJob.color.getColor
        timelogTable.reloadData()

    }

    func saveWS() {
        dataManager.save()
        self.performSegueWithIdentifier("unwindAddShiftSave", sender: self)
    }
    
    func cancelWS() {
        for i in allTLsArrary {
            dataManager.delete(i)
        }
        
        dataManager.delete(newShift)
        self.performSegueWithIdentifier("unwindAddShift", sender: self)
    }
    
    @IBAction func addBreakPressed(sender: AnyObject) {
        ++breakCount
        
        if breakCount == 1 {
            createTLinsert("Ended Break")
            createTLinsert("Started Break")
        } else if breakCount > 1 {
            for i in 2...breakCount{
                createTLinsert("Ended Break #\(breakCount)")
                createTLinsert("Started Break #\(breakCount)")
            }
        }
        
        var indexPathScroll = NSIndexPath(forRow: 0, inSection: 3)
        self.timelogTable.scrollToRowAtIndexPath(indexPathScroll, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        timelogTable.reloadData()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return (breakCount*2)
        } else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 45
        } else {
            return 30
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("JobsListCell", forIndexPath: indexPath) as! JobsListCell
            cell.job = selectedJob
            cell.jobColorView.setNeedsDisplay()
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("TimelogCell", forIndexPath: indexPath) as! TimelogCell
        
            //TODO: Change the TLs so that NSDATE is not choosen for new entries
            if indexPath.section == 1 {
                cell.timelog = allTLsArrary.first
//                cell.time.text = NSDateFormatter.localizedStringFromDate( (allTLsArrary.first!.time) , dateStyle: .MediumStyle, timeStyle: .MediumStyle)
                
//                cell.type.text = allTLsArrary.first?.type

            } else if indexPath.section == 3 {
                cell.timelog = allTLsArrary.last
//                cell.time.text = allTLsArrary.last?.time
//                cell.type.text = allTLsArrary.last?.type

            } else {
                cell.timelog = allTLsArrary[indexPath.row+1]
//                cell.time.text = allTLsArrary[indexPath.row+1].time
//                cell.type.text = allTLsArrary[indexPath.row+1].type
                
            }

            
            cell.job = selectedJob
            cell.jobColorView.setNeedsDisplay()

            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            let addJobStoryboard: UIStoryboard = UIStoryboard(name: "CalendarStoryboard", bundle: nil)
            let jobsListVC: JobsListTableViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("JobsListTableViewController")
                as! JobsListTableViewController
            jobsListVC.source = "details"
            jobsListVC.previousSelection = selectedJob.company.name
            
            
            self.navigationController?.pushViewController(jobsListVC, animated: true)

        } else {
            
            
            if indexPath.section == 1 {
                noMinDate = true // user select CLOCKIN so noMinDate
                nItemClockIn = allTLsArrary.first
            } else {
                noMinDate = false
                
                if indexPath.section == 3 {
                    nItemClockIn = allTLsArrary.last
                    self.nItemClockInPrevious = allTLsArrary[allTLsArrary.count-2]
                } else {
                    nItemClockIn = allTLsArrary[indexPath.row+1]
                    self.nItemClockInPrevious = allTLsArrary[indexPath.row]
                }
            }
            
            if indexPath.section == 3 {
                nItemClockIn = allTLsArrary.last
                noMaxDate = true //user select last TIMELOD so noMaxDat is sent, and will use NSDATE instead
            } else {
                noMaxDate = false
                
                if indexPath.section == 1 {
                    nItemClockIn = allTLsArrary.first
                    self.nItemClockInNext = allTLsArrary[1]
                } else {
                    nItemClockIn = allTLsArrary[indexPath.row+1]
                    self.nItemClockInNext = allTLsArrary[indexPath.row+2]
                }
            }
            
            self.performSegueWithIdentifier("showDetails", sender: tableView.cellForRowAtIndexPath(indexPath))
        }
        
    }
    
    func createTLappend(type: String){
        let newTL = dataManager.addItem("Timelog") as! Timelog
        newTL.workedShift = newShift
        newTL.comment = ""
        newTL.type = type
        newTL.time = NSDate()
        println(newTL)
        
        allTLsArrary.append(newTL)

        //test
        for i in allTLsArrary {
            println(i.type)
        }
    }

    func createTLinsert(type: String){
        let newTL = dataManager.addItem("Timelog") as! Timelog
        newTL.workedShift = newShift
        newTL.comment = ""
        newTL.type = type
        newTL.time = allTLsArrary[breakCount*2-1].time
        println(newTL)
        
        allTLsArrary.insert(newTL, atIndex: (breakCount*2-1))
        
        //test
        for i in allTLsArrary {
            println(i.type)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        
        if segue.identifier == "showDetails" {
            
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Cancel", style:.Plain, target: nil, action: nil)
            
            let destinationVC = segue.destinationViewController as! DetailsTableViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            
            println(nItemClockIn)
            
            destinationVC.nItem = self.nItemClockIn
            destinationVC.nItemPrevious = self.nItemClockInPrevious
            destinationVC.nItemNext = self.nItemClockInNext
            destinationVC.noMinDate = self.noMinDate
            destinationVC.noMaxDate = self.noMaxDate
            destinationVC.selectedJob = self.selectedJob
        }
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        
        header.textLabel.textColor = UIColor.blackColor()
        header.textLabel.frame = header.frame
        header.textLabel.textAlignment = NSTextAlignment.Justified

        if section == 0 {
            header.textLabel.text = "Job"
        } else if section == 1 {
            header.textLabel.text = "Entries"
        }

    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0 {
        return "Job"
        } else if section == 1 {
        return "Entries"
        } else {
            return nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func unwindFromJobsListTableViewControllerToDetails (segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! JobsListTableViewController
        selectedJob = sourceVC.selectedJob
        newShift.job = selectedJob
        earnedLabel.text = "You earned $\( newShift.moneyShiftOTx2()) for this shift"
        
    }
    
    @IBAction func unwindSaveDetailsTVC (segue: UIStoryboardSegue) {
            //by hitting the SAVE button
            let sourceVC = segue.sourceViewController as! DetailsTableViewController
            nItemClockIn = sourceVC.nItem
    
            newShift.sumUpDuration()
            worktimeLabel.text = "Work time = \( newShift.hoursWorked() ) hrs"
            earnedLabel.text = "You earned $\( newShift.moneyShiftOTx2()) for this shift"
            selectedJob = sourceVC.selectedJob
            timelogTable.reloadData()
        }
        
    @IBAction func unwindCancelDetailsTVC (segue: UIStoryboardSegue) {
        //by hitting the CANCEL button
        //Nothing saved!
    }
    
    

}
