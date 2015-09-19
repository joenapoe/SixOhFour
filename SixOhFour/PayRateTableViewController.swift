//
//  PayRateTableViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/9/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class PayRateTableViewController: UITableViewController {
    
    @IBOutlet weak var payTextField: UITextField!
    @IBOutlet weak var toggleOvertime: UISwitch!
    @IBOutlet weak var toggleSpecial: UISwitch!
    @IBOutlet weak var toggleShift: UISwitch!
    @IBOutlet weak var eightHrSwitch: UISwitch!
    @IBOutlet weak var twelveHrSwitch: UISwitch!
    @IBOutlet weak var holidaySwitch: UISwitch!
    
    var saveButton: UIBarButtonItem!
    var job: Job!
    var currentString = ""
    
    let dataManager = DataManager()
    
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
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBActions
    
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
    
    // MARK: - Class Functions
    
    func savePayRate() {
        self.performSegueWithIdentifier("unwindFromPayRate", sender: self)
    }
    
    // MARK: - TableView
    
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
    
}


// MARK: - TextField Delegate

extension PayRateTableViewController: UITextFieldDelegate {
    
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
    
}

