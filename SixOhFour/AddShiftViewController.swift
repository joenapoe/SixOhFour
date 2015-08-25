//
//  AddShiftViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 8/22/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class AddShiftViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var addBreakButton: UIButton!
    @IBOutlet var worktimeLabel: UILabel!
    @IBOutlet var timelogTable: UITableView!
    @IBOutlet var earnedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Add Shift"

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: nil)
        
        timelogTable.sectionHeaderHeight = 0.0
        timelogTable.sectionFooterHeight = 0.0
    }


    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 45
        } else {
            return 30
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
//        if indexPath.section == 1 {
//            let cell = tableView.dequeueReusableCellWithIdentifier("TimelogCell", forIndexPath: indexPath) as! TimelogCell
//            cell.timelog = TLresults[indexPath.row]
//            cell.jobColorView.setNeedsDisplay()
//            return cell
//        } else {
//            cellIncomp = tableView.dequeueReusableCellWithIdentifier("TimelogCell") as! TimelogCell
//            cellIncomp.time.text = "Missing Time"
//            cellIncomp.jobColorView.color = TLresults[indexPath.row].workedShift.job.color.getColor
//            
//            if indexPath.row == 0 && (TLresults.count % 2 == 0) {
//                var breakNumber : Int = (TLresults.count / 2)
//                if breakNumber == 1 {
//                    cellIncomp.type.text = "Ended Break"
//                } else {
//                    cellIncomp.type.text = "Ended Break #\(breakNumber)"
//                }
//            } else {
//                cellIncomp.type.text = "Clocked Out"
//            }
//            cellIncomp.jobColorView.setNeedsDisplay()
//            return cellIncomp

        if indexPath.section == 0 {
        let cell = tableView.dequeueReusableCellWithIdentifier("JobsListCell", forIndexPath: indexPath) as! JobsListCell
        return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("TimelogCell", forIndexPath: indexPath) as! TimelogCell
            cell.time.text = "Missing Time"
            
            if indexPath.section == 1 {
                cell.type.text = "Clocked In"
            } else if indexPath.section == 3 {
                cell.type.text = "Clocked Out"
            }

            
            return cell
        }
        
        
        
    }
    
 
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        
        header.textLabel.textColor = UIColor.blackColor()
        //        header.textLabel.font = UIFont.boldSystemFontOfSize(18)
        header.textLabel.frame = header.frame
        header.textLabel.textAlignment = NSTextAlignment.Justified
//        header.textLabel.text = "Entries for the shift"

        if section == 0 {
            header.textLabel.text = "Job"
        } else if section == 1 {
            header.textLabel.text = "Entries"
        }

        
//        if timelogList.count == 0 {
//            header.textLabel.hidden = true
//        } else {
//            header.textLabel.hidden = false
//        }
    }
    
//    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return -35
//    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0 {
        return "Job"
        } else if section == 1 {
        return "Entries"
        } else {
            return nil
        }
//        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
