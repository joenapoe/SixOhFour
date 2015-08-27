//
//  ClockInJobsPopoverViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 7/8/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class ClockInJobsPopoverViewController: UIViewController {
    
    @IBOutlet weak var ClockInJobsTable: UITableView!
    
    var jobs = [Job]()
    var selectedJob: Job!
    var selectedJobIndex: Int!
    var dataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // DELETE: Review and Delete
        // Now using the DataManager class
//        var appDel:AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
//        var context:NSManagedObjectContext = appDel.managedObjectContext!
//        
//        var request = NSFetchRequest(entityName: "Job")
//        request.returnsObjectsAsFaults = false ;
//        
//        var results:NSArray = context.executeFetchRequest(request, error: nil)!
//        jobs = results as! [Job]

        
        // So fresh and so clean :]
        jobs = dataManager.fetch("Job") as! [Job]
        
        
        ClockInJobsTable.delegate = self
        ClockInJobsTable.dataSource = self
        
        self.ClockInJobsTable.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


// MARK: - Table View Data Source and Delegate

extension ClockInJobsPopoverViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jobs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ClockInJobsCell", forIndexPath: indexPath) as! JobsListCell
        
        cell.job = jobs[indexPath.row]
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.selectedJobIndex = indexPath.row
        
        self.dismissViewControllerAnimated(true, completion: {})
        
        self.performSegueWithIdentifier("unwindFromClockInPopoverViewControllerIdentifier", sender: self)
        
    }
}
