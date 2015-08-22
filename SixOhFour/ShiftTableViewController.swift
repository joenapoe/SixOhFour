//
//  ManualEditsShiftTableViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/13/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class ShiftTableViewController: UITableViewController {
    
    //PASSED IN VARIABLES:
    var selectedWorkedShift : WorkedShift!
    
    //Fetched Info from passed in var.
    var dataManager = DataManager()
    var TLresults = [Timelog]()
    var JOBresults = [Job]()
    
    // NOTE Variables passed to Details
    var nItemClockIn : Timelog!
    var nItemClockInPrevious : Timelog!
    var nItemClockInNext : Timelog!
    var selectedJob : Job!
    var noMinDate: Bool = false
    var noMaxDate: Bool = false
    var selectedRowIndex = Int()
    
    // Created to handle Incomplete
    var cellIncomp: TimelogCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Shift"
        self.tableView.rowHeight = 30.0
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        fetchTLresults()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        fetchTLresults()
        tableView.reloadData()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        tableView.reloadData()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return TLresults.count
        } else if section == 2{
            if TLresults.last!.type == "Clocked Out" {
                return 0
            } else if TLresults.count % 2 == 1 {
                return 1
            } else {
                return 2
            }
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("TimelogCell", forIndexPath: indexPath) as! TimelogCell
            cell.timelog = TLresults[indexPath.row]
            cell.jobColorView.setNeedsDisplay()
            return cell
        } else {
            cellIncomp = tableView.dequeueReusableCellWithIdentifier("TimelogCell") as! TimelogCell
            cellIncomp.time.text = "Missing Time"
            cellIncomp.jobColorView.color = TLresults[indexPath.row].workedShift.job.color.getColor
            
            if indexPath.row == 0 && (TLresults.count % 2 == 0) {
                var breakNumber : Int = (TLresults.count / 2)
                if breakNumber == 1 {
                    cellIncomp.type.text = "Ended Break"
                } else {
                    cellIncomp.type.text = "Ended Break #\(breakNumber)"
                }
            } else {
                cellIncomp.type.text = "Clocked Out"
            }
            cellIncomp.jobColorView.setNeedsDisplay()
            return cellIncomp
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var predicateJob = NSPredicate(format: "company.name == %@", (TLresults[indexPath.row].workedShift.job.company.name) )
        JOBresults = dataManager.fetch("Job", predicate: predicateJob) as! [Job]
        
        selectedJob = JOBresults[0]
        
        if indexPath.section == 1 {
            nItemClockIn = TLresults[indexPath.row]
            
            selectedRowIndex = (indexPath.row)
            
            if (indexPath.row) == 0 {
                noMinDate = true // user select CLOCKIN so noMinDate
            } else {
                noMinDate = false
                self.nItemClockInPrevious = TLresults[indexPath.row - 1]
            }
            
            if (TLresults.count - indexPath.row - 1) == 0 {
                noMaxDate = true //user select last TIMELOD so noMaxDat is sent, and will use NSDATE instead
            } else {
                noMaxDate = false
                self.nItemClockInNext = TLresults[indexPath.row + 1]
            }
        } else if indexPath.section == 2 {
            
            if indexPath.row == 1 { //clock out is sitting 2nd position so you need to add end break
                let tempTL2 = dataManager.addItem("Timelog") as! Timelog
                tempTL2.workedShift = selectedWorkedShift
                tempTL2.time = TLresults.last!.time
                tempTL2.comment = ""
                if TLresults.count < 3 {
                    tempTL2.type = "Ended Break"
                } else {
                    tempTL2.type = "Ended Break #\((TLresults.count)/2)"
                }
            }
            
            let tempTL = dataManager.addItem("Timelog") as! Timelog
            tempTL.workedShift = selectedWorkedShift
            tempTL.comment = ""
            tempTL.time = (TLresults.last!.time).dateByAddingTimeInterval(1)
            
            if (indexPath.row) == 0 && TLresults.count % 2 == 0 { //you selected endbreak
                if TLresults.count < 3 {
                    tempTL.type = "Ended Break"
                } else {
                    tempTL.type = "Ended Break #\((TLresults.count)/2)"
                }
            } else { // you selected clock out
                tempTL.type = "Clocked Out"
                selectedWorkedShift.status = 0
            }
            
            
            nItemClockIn = tempTL
            
            noMinDate = false
            self.nItemClockInPrevious = TLresults.last
            
            //            noMaxDate = false
            noMaxDate = true
            // Sim : need to send up a restriction of 24hrs
            
            //            if (TLresults.count - indexPath.row - 1) == 0 {
            //                noMaxDate = true //user select last TIMELOD so noMaxDat is sent, and will use NSDATE instead
            //            } else {
            //                noMaxDate = false
            //                self.nItemClockInNext = TLresults[indexPath.row + 1]
            //            }
            
            
        }
        self.performSegueWithIdentifier("showDetails", sender: tableView.cellForRowAtIndexPath(indexPath))
    }
    
    // Tableview Headers
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel.textAlignment = NSTextAlignment.Left
        
        if section == 0 {
            header.textLabel.text = "Work time = \( selectedWorkedShift.hoursWorked() ) hrs"
            header.textLabel.textColor = UIColor.blackColor()
            header.textLabel.font = UIFont.systemFontOfSize(16)
            header.textLabel.numberOfLines = 2;
        } else if section == 1 {
            header.textLabel.text = "Saved Entries:"
            header.textLabel.textColor = UIColor.blackColor()
            header.textLabel.font = UIFont.systemFontOfSize(12)
        } else if section == 2 && TLresults.last!.type != "Clocked Out" {
            header.textLabel.text = "Incomplete Entries:"
            header.textLabel.textColor = UIColor.redColor()
            header.textLabel.font = UIFont.boldSystemFontOfSize(12)
        }
    }
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 40
        } else if section == 1{
            return 35
        } else {
            return 35
        }
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let footer:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        //        header.textLabel.frame = header.frame
        footer.textLabel.textAlignment = NSTextAlignment.Left
        if section == 0 {
            footer.textLabel.text = "You earned $\( selectedWorkedShift.moneyShiftOTx2()) for this shift"
            footer.textLabel.textColor = UIColor.blackColor()
            footer.textLabel.font = UIFont.systemFontOfSize(12)
        }
    }
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return ""
    }
    
    func fetchTLresults() {
        var predicate = NSPredicate(format: "SELF.workedShift == %@", selectedWorkedShift)
        var sortNSDATE = NSSortDescriptor(key: "time", ascending: true)
        TLresults = dataManager.fetch("Timelog", predicate: predicate, sortDescriptors: [sortNSDATE] ) as! [Timelog]
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
    
    // MARK: Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showDetails" {
            
            let destinationVC = segue.destinationViewController as! DetailsTableViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Cancel", style:.Plain, target: nil, action: nil)

            destinationVC.nItem = self.nItemClockIn
            destinationVC.nItemPrevious = self.nItemClockInPrevious
            destinationVC.nItemNext = self.nItemClockInNext
            destinationVC.noMinDate = self.noMinDate
            destinationVC.noMaxDate = self.noMaxDate
            destinationVC.selectedJob = self.selectedJob
        }
    }
    
    @IBAction func unwindFromShift (segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! ShiftTableViewController
        let destVC = segue.destinationViewController as! IncompleteShiftsTableViewController
        destVC.selectedWorkedShift = self.selectedWorkedShift
        dataManager.save()
    }
    
    @IBAction func unwindFromDetailsTableViewController (segue: UIStoryboardSegue) {
        
        let sourceVC = segue.sourceViewController as! DetailsTableViewController
        TLresults[selectedRowIndex] = sourceVC.nItem
        
        selectedWorkedShift.sumUpDuration()
        selectedWorkedShift.hoursWorked()
        selectedWorkedShift.moneyShiftOTx2()
        tableView.reloadData()
        dataManager.save()
        println("selectedWorkedShift = \(selectedWorkedShift)")
        
        
        selectedJob = sourceVC.selectedJob
        selectedWorkedShift.job = selectedJob

        
//        if sourceVC.selectedJob != nil {
//            selectedJob = sourceVC.selectedJob
////            jobColorDisplay.color = selectedJob.color.getColor
//        }
        
//        if timelogList != [] {
//            saveWorkedShiftToJob()
//        }
        
        dataManager.save()
        
    }
}
