//
//  PayRateTableViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/9/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class PayRateTableViewController: UITableViewController, UITextFieldDelegate {
    
    var saveButton: UIBarButtonItem!
    var job: Job!
    var currentString = ""
    
    let dataManager = DataManager()

    @IBOutlet weak var payTextField: UITextField!
    @IBOutlet weak var toggleOvertime: UISwitch!
    @IBOutlet weak var toggleSpecial: UISwitch!
    @IBOutlet weak var toggleShift: UISwitch!
    @IBOutlet weak var eightHrSwitch: UISwitch!
    @IBOutlet weak var twelveHrSwitch: UISwitch!
    @IBOutlet weak var holidaySwitch: UISwitch!
    
    @IBAction func holidaySwitch(sender: AnyObject) {
        
    }
    
    @IBAction func twelveHrSwitch(sender: AnyObject) {
        
    }
    
    @IBAction func eightHrSwitch(sender: AnyObject) {
        
    }
    
    @IBAction func toggleOvertimeValue(sender: AnyObject) {
        tableView.reloadData()
    }
    
    @IBAction func toggleSpecialValue(sender: AnyObject) {
        tableView.reloadData()
    }
    
    @IBAction func toggleShiftValue(sender: AnyObject) {
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.payTextField.delegate = self
        
        saveButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "savePayRate")
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.title = "Pay Rate"
        
        if job != nil {
            let unitedStatesLocale = NSLocale(localeIdentifier: "en_US")
            let pay = job.payRate
            var numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
            numberFormatter.locale = unitedStatesLocale
            
            payTextField.text = numberFormatter.stringFromNumber(pay)!
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 1 && toggleOvertime.on == false {
            return 0
        }
        else if indexPath.section == 1 && indexPath.row == 2 && toggleOvertime.on == false {
            return 0
        }
        else if indexPath.section == 2 && indexPath.row == 1 && toggleSpecial.on == false {
            return 0
        }
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    //Textfield delegates
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool { // return NO to not change text
        
        switch string {
        case "0","1","2","3","4","5","6","7","8","9":
            currentString += string
            formatCurrency(string: currentString)
        default:
            var array = Array(string)
            var currentStringArray = Array(currentString)
            if array.count == 0 && currentStringArray.count != 0 {
                currentStringArray.removeLast()
                currentString = ""
                for character in currentStringArray {
                    currentString += String(character)
                }
                formatCurrency(string: currentString)
            }
        }
        return false
    }
    
    func formatCurrency(#string: String) {
        println("format \(string)")
        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        formatter.locale = NSLocale(localeIdentifier: "en_US")
        var numberFromField = (NSString(string: currentString).doubleValue)/100
        payTextField.text = formatter.stringFromNumber(numberFromField)
        println(payTextField.text)
    }
    
    func savePayRate() {
        self.performSegueWithIdentifier("unwindFromPayRate", sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    /*
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return 0
    }
    */

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...

        return cell
    }
    */

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

}
