//
//  ManualEditsShiftTableViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/13/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class ManualEditsShiftTableViewController: UITableViewController {
    var dataManager = DataManager()
    var selectedWorkedShift : WorkedShift!
    var TLresults = [Timelog]()
    var JOBresults = [Job]()
    
    var nItemClockIn : Timelog!
    var nItemClockInPrevious : Timelog!
    var nItemClockInNext : Timelog!
    var selectedJob : Job!
    var noMinDate: Bool = false
    var noMaxDate: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.title = "Unsaved Shifts"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: nil)
        self.tableView.rowHeight = 30.0

        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        
        var predicate = NSPredicate(format: "SELF.workedShift == %@", selectedWorkedShift)
        
        TLresults = dataManager.fetch("Timelog", predicate: predicate) as! [Timelog]
        


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TLresults.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TimelogCell", forIndexPath: indexPath) as! TimelogCell

        cell.timelog = TLresults[indexPath.row]

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println(indexPath.row)
        
        
        var predicateJob = NSPredicate(format: "company.name == %@", (TLresults[indexPath.row].workedShift.job.company.name) )
        JOBresults = dataManager.fetch("Job", predicate: predicateJob) as! [Job]
        
        
        selectedJob = JOBresults[0]
            
        nItemClockIn = TLresults[indexPath.row]
        
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
        
        self.performSegueWithIdentifier("showDetails", sender: tableView.cellForRowAtIndexPath(indexPath))
        
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
        
    destinationVC.nItem = self.nItemClockIn
    destinationVC.nItemPrevious = self.nItemClockInPrevious
    destinationVC.nItemNext = self.nItemClockInNext
    destinationVC.noMinDate = self.noMinDate
    destinationVC.noMaxDate = self.noMaxDate
    destinationVC.selectedJob = self.selectedJob
        }
    }

}
