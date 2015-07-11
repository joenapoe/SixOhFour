//
//  AddJobTableViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/9/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class AddJobTableViewController: UITableViewController, writeValueBackDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var positionTextField: UITextField!
    @IBOutlet weak var payRateLabel: UILabel!
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var colorPicker: UIPickerView!
    @IBOutlet weak var jobColorView: JobColorView!

    let pickerData = ["Red", "Blue", "Green", "Yellow", "Purple"]
    
    var pickerVisible = false
    
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var nItem : Jobs? = nil
    
    // DUMY FUNCTION - DELETE LATER
    func getJobColor() -> UIColor {
        
        if colorLabel.text == "Red" {
            return UIColor.redColor()
        } else if colorLabel.text == "Blue" {
            return UIColor.blueColor()
        } else if colorLabel.text == "Green" {
            return UIColor.greenColor()
        } else if colorLabel.text == "Yellow" {
            return UIColor.yellowColor()
        } else if colorLabel.text == "Purple" {
            return UIColor.purpleColor()
        } else {
            return UIColor.blackColor()
        }
    }
    
    @IBAction func payRateButtonPressed(sender: AnyObject) {
        let addJobStoryboard: UIStoryboard = UIStoryboard(name: "AddJobStoryboard", bundle: nil)
        var payRateTableViewController: PayRateTableViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("PayRateTableViewController") as! PayRateTableViewController
        payRateTableViewController.writeValueDelegate = self
        navigationController?.pushViewController(payRateTableViewController, animated: true)
    }
    
    @IBAction func saveJobButton(sender: AnyObject) {
        if nItem != nil {
            editItem()
        } else {
            newItem()
        }
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        colorPicker.dataSource = self
        colorPicker.delegate = self

        if nItem != nil {
            nameTextField.text = nItem?.jobName
            positionTextField.text = nItem?.jobPosition
            payRateLabel.text = nItem?.jobPay
            colorLabel.text = nItem?.jobColor
            if jobColorView != nil {
                jobColorView.color = nItem!.getJobColor()
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 3 {
            pickerVisible = !pickerVisible
            tableView.reloadData()
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 4 {
            if pickerVisible == false {
                return 0.0
            }
            return 150.0
        }
        return 44.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func writeValueBack(vc: PayRateTableViewController, value: String) {
        self.payRateLabel.text = "$\(value)"
    }
    
    func newItem() {
        let context = self.context
        let ent = NSEntityDescription.entityForName("Jobs", inManagedObjectContext: context!)
            
        let nItem = Jobs(entity: ent!, insertIntoManagedObjectContext: context)
        nItem.jobName = nameTextField.text
        nItem.jobPosition = positionTextField.text
        nItem.jobPay = payRateLabel.text!
        nItem.jobColor = colorLabel.text!
        context!.save(nil)
    }
        
    func editItem() {
        nItem!.jobName = nameTextField.text
        nItem!.jobPosition = positionTextField.text
        nItem!.jobPay = payRateLabel.text!
        nItem!.jobColor = colorLabel.text!
        context!.save(nil)
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return pickerData[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        colorLabel.text = pickerData[row]
        jobColorView.color = getJobColor()
    }

}
