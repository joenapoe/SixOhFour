//
//  ManualEditsListTableViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/13/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class IncompleteShiftsTableViewController: UITableViewController {
    
    var dataManager = DataManager()
    var openShifts = [WorkedShift]()
    var openShiftsCIs = [Timelog]()
    var selectedWorkedShift : WorkedShift!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Incomplete Shifts"
        //        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: nil)
        //        var doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: nil)
        //        self.navigationItem.rightBarButtonItem = doneButton
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(true)
        
        let predicateOpenWS = NSPredicate(format: "workedShift.status == 1")
        let predicateCI = NSPredicate(format: "type == %@" , "Clocked In")
        let compoundPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([predicateCI, predicateOpenWS])
        
        var sortNSDATE = NSSortDescriptor(key: "time", ascending: true)
        
        openShiftsCIs = dataManager.fetch("Timelog", predicate: compoundPredicate, sortDescriptors: [sortNSDATE] ) as! [Timelog]
        
        openShifts = [WorkedShift]()
        
        for timelog in openShiftsCIs {
            openShifts.append(timelog.workedShift)
        }
        
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return openShifts.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ShiftListTableViewCell", forIndexPath: indexPath) as! ManualEditsListTableViewCell
        
        cell.workedShift = openShifts[indexPath.row]
        cell.clockInTL = openShiftsCIs[indexPath.row]
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println(indexPath.row)
        selectedWorkedShift = openShifts[indexPath.row]
        
        self.performSegueWithIdentifier("showShift", sender: tableView.cellForRowAtIndexPath(indexPath))
        
    }
    
    // Tableview Headers
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        
        header.textLabel.textColor = UIColor.blackColor()
        //        header.textLabel.font = UIFont.boldSystemFontOfSize(18)
        header.textLabel.frame = header.frame
        header.textLabel.textAlignment = NSTextAlignment.Justified
        header.textLabel.text = "You have \(openShifts.count) unsaved shifts:"
        
        if openShifts.count == 0 {
            header.textLabel.hidden = true
        } else {
            header.textLabel.hidden = false
            if openShifts.count == 1 {
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
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
        tableView.beginUpdates()

        let shiftToDelete = openShifts[indexPath.row]
        openShifts.removeAtIndex(indexPath.row)

        dataManager.delete(shiftToDelete)

        tableView.deleteRowsAtIndexPaths([indexPath],  withRowAnimation: .Fade)
        
        tableView.endUpdates()
        
        // TODO: Time the reload data to better show animation of delete
        tableView.reloadData() // Needed to udate header
        //tableView.reloadSectionIndexTitles()
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showShift" {
            let destinationVC = segue.destinationViewController as! ShiftTableViewController
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.Plain, target: nil, action: nil)
            destinationVC.hidesBottomBarWhenPushed = true;
            destinationVC.selectedWorkedShift = self.selectedWorkedShift
        }
    }
    
    
    
}
