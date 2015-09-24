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
    
    var jobs = [Job]()
    var selectedJob: Job!
    var previousColor: Color!
    var selectedColor: Color!
    var colors = [Color]()
    
    let dataManager = DataManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        fetchJobData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchJobData()
        
        toggleAddButton()
        
        tableView.reloadData()
    }
    
    func toggleAddButton() {
        if jobs.count == 10 {
            addButton.enabled = false
        } else {
            addButton.enabled = true
        }
    }
    
    func fetchJobData() {
        jobs = dataManager.fetch("Job") as! [Job]
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "add" {
            let destinationVC = segue.destinationViewController as! AddJobTableViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            
        }
        
        if segue.identifier == "jobOverview" {
            let destinationVC = segue.destinationViewController as! JobOverviewViewController
            destinationVC.hidesBottomBarWhenPushed = true;
            destinationVC.job = self.selectedJob
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
                self.dataManager.delete(jobDelete)
                
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            }
            
            alertController.addAction(delete)
            alertController.addAction(cancel)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
            tableView.endUpdates()
            
            self.toggleAddButton()
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
        
        cell.jobNameLabel.text = jobs[indexPath.row].company.name
        cell.jobPositionLabel.text = jobs[indexPath.row].position
        cell.jobColorView.color = jobs[indexPath.row].color.getColor
        cell.jobColorView.setNeedsDisplay()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedJob = jobs[indexPath.row]
        self.performSegueWithIdentifier("jobOverview", sender: self)
    }
    
}