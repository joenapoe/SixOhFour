//
//  DailyTimesheetTableViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 8/26/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class DailyTimesheetTableViewController: UITableViewController {

    let dataManager = DataManager()
    var allWorkedShifts = [WorkedShift]()
    var openShiftsCIs = [Timelog]()
    var selectedWorkedShift : WorkedShift!
    var startDate: NSDate!
    var endDate: NSDate!
    var selectedJob: Job!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        pullShiftsInTimeFrame()
        tableView.reloadData()
    }

    func pullShiftsInTimeFrame() {
        
        openShiftsCIs = []
        allWorkedShifts = []
        
        let predicateCurrent = NSPredicate(format: "workedShift.status != 2")
        let predicateTypeJob = NSPredicate(format: "workedShift.job == %@ && type == %@", selectedJob, "Clocked In")
        let predicateTime = NSPredicate(format: "time >= %@ && time <= %@", startDate, endDate)
        let compoundPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([predicateTime, predicateTypeJob, predicateCurrent])
        
        var sortNSDATE = NSSortDescriptor(key: "time", ascending: true)
        
        openShiftsCIs = dataManager.fetch("Timelog", predicate: compoundPredicate, sortDescriptors: [sortNSDATE] ) as! [Timelog]
        
        for timelog in openShiftsCIs {
            allWorkedShifts.append(timelog.workedShift)
        }
        for shift in allWorkedShifts {
            println(shift.status)
        }
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return allWorkedShifts.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DayCellTableViewCell", forIndexPath: indexPath) as! DayCellTableViewCell
        cell.workedShift = allWorkedShifts[indexPath.row]
        cell.clockInTL = openShiftsCIs[indexPath.row]
        
        if cell.workedShift.status == 1 {
            cell.dateLabel.textColor = UIColor.redColor()
            cell.timeLabel.textColor = UIColor.redColor()
            cell.durationLabel.textColor = UIColor.redColor()
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        selectedWorkedShift = allWorkedShifts[indexPath.row]
        
        let clockInStoryboard: UIStoryboard = UIStoryboard(name: "ClockInStoryboard", bundle: nil)
        let shiftVC: ShiftTableViewController = clockInStoryboard.instantiateViewControllerWithIdentifier("ShiftTableViewController")
            as! ShiftTableViewController

        shiftVC.selectedWorkedShift = selectedWorkedShift
        self.navigationController?.pushViewController(shiftVC, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            tableView.beginUpdates()
            
            let shiftToDelete = allWorkedShifts[indexPath.row]
            allWorkedShifts.removeAtIndex(indexPath.row)
            
            //TODO: Remove with new DataManager Funct.
            for timelog in shiftToDelete.timelogs {
                dataManager.delete(timelog as! Timelog)
            }
            
            dataManager.delete(shiftToDelete)
            
            tableView.deleteRowsAtIndexPaths([indexPath],  withRowAnimation: .Fade)
            
            tableView.endUpdates()
            
        }
    }


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

}
