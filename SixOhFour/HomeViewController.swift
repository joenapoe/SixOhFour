//
//  HomeViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 6/24/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var editButton: UIBarButtonItem!
    
    var jobs = [Job]()
    var job: Job!
    var previousColor: Color!
    var selectedColor: Color!
    var colors = [Color]()

    let dataManager = DataManager()

    override func viewDidLoad() {
        super.viewDidLoad()
            
        editButton = editButtonItem()
        self.navigationItem.leftBarButtonItem = editButton
        
        tableView.dataSource = self
        tableView.delegate = self
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let font = UIFont(name: "GrandHotel-Regular", size: 28) {
            self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: font]
        }
        
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        let sortDescriptors = [sortDescriptor]
        jobs = dataManager.fetch("Job", sortDescriptors: sortDescriptors) as! [Job]
        
        // TODO: DELETE
        for job in jobs {
            println(job.company)
            println(job.order)
        }
        
        if jobs.count == 10 {
            addButton.enabled = false
        } else {
            addButton.enabled = true
        }
        
        if jobs.count > 0 {
            editButton.enabled = true
        } else {
            editButton.enabled = false
        }
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        let font = UIFont.boldSystemFontOfSize(18)
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: font]
        
        if (editing) {
            editing = false
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        tableView.setEditing(editing, animated: true)
        
        if editing {
            addButton.enabled = false
        } else {
            updateOrder()
            addButton.enabled = true
        }
    }
    
    func updateOrder() {
        var order = 0
        
        for job in jobs {
            job.order = Int32(order)
            order++
        }
        
        dataManager.save()
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "add" {
            let destinationVC = segue.destinationViewController as! AddJobTableViewController
            destinationVC.hidesBottomBarWhenPushed = true;
        } else if segue.identifier == "jobOverview" {
            let destinationVC = segue.destinationViewController as! JobOverviewViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            
            destinationVC.job = self.job
        }
    }
}


// MARK: TableView Data Source and Delegate

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            tableView.beginUpdates()
            
            var title = "Warning!"
            
            var message = "Deleting this job will also delete all associated shifts with it!"
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            let delete = UIAlertAction(title: "Delete", style: .Destructive) { (action) in
                
                let jobDelete = self.jobs[indexPath.row]
                let color = jobDelete.color
                
                let updateColor = self.dataManager.editItem(color, entityName: "Color") as! Color
                updateColor.isSelected = false
                
                self.jobs.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                
                //TODO: END TIMERS!
                NSNotificationCenter.defaultCenter().postNotificationName("StopTimerNotification", object: nil)

                self.dataManager.delete(jobDelete)
                self.updateOrder()
                
                if self.jobs.count == 0 {
                    self.editing = false
                    self.editButton.enabled = false
                } else {
                    self.editButton.enabled = true
                }
                
                tableView.reloadData()
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            
            }
            
            alertController.addAction(delete)
            alertController.addAction(cancel)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
            tableView.endUpdates()
            
            if jobs.count == 10 {
                addButton.enabled = false
            } else {
                addButton.enabled = true
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel.textAlignment = NSTextAlignment.Justified
        
        if jobs.count > 1 {
            header.textLabel.text = "My Jobs"
        } else if jobs.count > 0 {
            header.textLabel.text = "My Job"
        } else if jobs.count == 0 {
            header.textLabel.text = ""
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jobs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("JobsListCell", forIndexPath: indexPath) as! JobsListCell
        
        cell.jobNameLabel.text = jobs[indexPath.row].company
        cell.jobPositionLabel.text = jobs[indexPath.row].position
        cell.jobColorView.color = jobs[indexPath.row].color.getColor
        cell.jobColorView.setNeedsDisplay()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.job = jobs[indexPath.row]
        
        self.performSegueWithIdentifier("jobOverview", sender: self)
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let itemToMove = jobs[sourceIndexPath.row]
        jobs.removeAtIndex(sourceIndexPath.row)
        jobs.insert(itemToMove, atIndex: destinationIndexPath.row)
        
    }
    
}