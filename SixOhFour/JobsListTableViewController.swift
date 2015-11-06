//
//  JobsListTableViewController.swift
//  SixOhFour
//
//  Created by jemsomniac on 7/10/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class JobsListTableViewController: UITableViewController {

    var selectedJob: Job!
    var previousSelection: Job!
    var source: String!

    var jobs = [Job]()
    
    let dataManager = DataManager()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        let sortDescriptors = [sortDescriptor]
        jobs = dataManager.fetch("Job", sortDescriptors: sortDescriptors) as! [Job]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Class Functions
    
    func performUnwindTo(source: String) {
        switch source {
        case "addSchedule":
            self.performSegueWithIdentifier("unwindFromJobsListTableViewController", sender: self)
        case "clockin":
            self.performSegueWithIdentifier("unwindFromJobsListTableViewControllerToClockIn", sender: self)
        case "details":
            self.performSegueWithIdentifier("unwindFromJobsListTableViewControllerToDetails", sender: self)
        case "shift":
            self.performSegueWithIdentifier("unwindFromJobsListTableViewControllerToShift", sender: self)
        default:
            ()
        }
    }

    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jobs.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("JobsListCell", forIndexPath: indexPath) as! JobsListCell
        
        cell.job = jobs[indexPath.row]
        
        if cell.job == previousSelection {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedJob = jobs[indexPath.row]
        
        performUnwindTo(source)
    }
}
