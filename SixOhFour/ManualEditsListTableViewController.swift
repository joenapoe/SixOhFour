//
//  ManualEditsListTableViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/13/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class ManualEditsListTableViewController: UITableViewController {

    var dataManager = DataManager()
    var allOpenWorkedShifts = [WorkedShift]()
    var allOpenWorkedShiftsCIs = [Timelog]()
    var selectedWorkedShift : WorkedShift!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        var doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: nil)
//        self.navigationItem.rightBarButtonItem = doneButton

        self.title = "Incomplete Shifts"
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: nil)
        
        
        
        let predicateOpen = NSPredicate(format: "status == 1")
        allOpenWorkedShifts = dataManager.fetch("WorkedShift", predicate: predicateOpen) as! [WorkedShift]
        println(allOpenWorkedShifts.count)
    
        
        
        let predicateOpenWS = NSPredicate(format: "workedShift.status == 1")
        let predicateCI = NSPredicate(format: "type == %@" , "Clocked In")
        let compoundPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([predicateCI, predicateOpenWS])
        allOpenWorkedShiftsCIs = dataManager.fetch("Timelog", predicate: compoundPredicate) as! [Timelog]
        
        println(allOpenWorkedShiftsCIs.count)

        
        
        
        println(allOpenWorkedShifts)
        println(allOpenWorkedShiftsCIs)

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allOpenWorkedShifts.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ManualEditsListTableViewCell", forIndexPath: indexPath) as! ManualEditsListTableViewCell
        
        cell.workedShift = allOpenWorkedShifts[indexPath.row]
        
        cell.clockInTL = allOpenWorkedShiftsCIs[indexPath.row]
        
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println(indexPath.row)
        selectedWorkedShift = allOpenWorkedShifts[indexPath.row]
        
        self.performSegueWithIdentifier("showManualEditsShift", sender: tableView.cellForRowAtIndexPath(indexPath))
        
    }

// Tableview Headers
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        
        header.textLabel.textColor = UIColor.blackColor()
        //        header.textLabel.font = UIFont.boldSystemFontOfSize(18)
        header.textLabel.frame = header.frame
        header.textLabel.textAlignment = NSTextAlignment.Justified
        header.textLabel.text = "You have \(allOpenWorkedShifts.count) unsaved shifts:"
        
        if allOpenWorkedShifts.count == 0 {
            header.textLabel.hidden = true
        } else {
            header.textLabel.hidden = false
            if allOpenWorkedShifts.count == 1 {
                header.textLabel.text = "You have 1 unsaved shift:"
            }
        }
    }
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showManualEditsShift" {
            let destinationVC = segue.destinationViewController as! ManualEditsShiftTableViewController
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.Plain, target: nil, action: nil)
            destinationVC.hidesBottomBarWhenPushed = true;
            //            //Passes 2 data variables
            destinationVC.selectedWorkedShift = self.selectedWorkedShift
            //            destinationVC.breakHours = self.breakHoursSet
            //            //Pass same 2 variable to get the delta
            //            destinationVC.breakMinutesSetIntial = self.breakMinutesSet
            //            destinationVC.breakHoursSetIntial = self.breakHoursSet
        }
        
    }


    
}
