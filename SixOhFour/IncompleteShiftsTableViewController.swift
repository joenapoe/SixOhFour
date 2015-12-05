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
    var incompleteShifts = [WorkedShift]()
    var selectedWorkedShift : WorkedShift!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Incomplete Shifts"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        fetchIncomplete()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchIncomplete() {

        incompleteShifts = []

        let predicateIncomplete = NSPredicate(format: "status == 1")
        var sortByTime = NSSortDescriptor(key: "startTime", ascending: true)
        incompleteShifts = dataManager.fetch("WorkedShift", predicate: predicateIncomplete, sortDescriptors: [sortByTime]) as! [WorkedShift]
        
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return incompleteShifts.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ShiftListTableViewCell", forIndexPath: indexPath) as! ManualEditsListTableViewCell
        cell.workedShift = incompleteShifts[indexPath.row]
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedWorkedShift = incompleteShifts[indexPath.row]
        self.performSegueWithIdentifier("showShift", sender: tableView.cellForRowAtIndexPath(indexPath))
    }
    
    // Tableview Headers
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel.textColor = UIColor.blackColor()
        header.textLabel.frame = header.frame
        header.textLabel.textAlignment = NSTextAlignment.Justified
        header.textLabel.text = "You have \(incompleteShifts.count) unsaved shifts:"
        
        if incompleteShifts.count == 0 {
            header.textLabel.hidden = true
        } else {
            header.textLabel.hidden = false
            if incompleteShifts.count == 1 {
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
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            let shiftToDelete = incompleteShifts[indexPath.row]
            dataManager.delete(shiftToDelete)
            incompleteShifts.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath],  withRowAnimation: .Fade)
            tableView.reloadData() // Needed to udate header // TODO: Time the reload data to better show animation of delete
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showShift" {
            let destinationVC = segue.destinationViewController as! ShiftViewController
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.Plain, target: nil, action: nil)
            destinationVC.hidesBottomBarWhenPushed = true;
            destinationVC.selectedWorkedShift = self.selectedWorkedShift
        }
    }
}