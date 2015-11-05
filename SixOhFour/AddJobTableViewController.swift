//
//  AddJobTableViewController.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/9/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class AddJobTableViewController: UITableViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var positionTextField: UITextField!
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var colorPicker: UIPickerView!
    @IBOutlet weak var jobColorView: JobColorView!
    @IBOutlet weak var saveJobButton: UIBarButtonItem!
    @IBOutlet weak var payTextField: UITextField!
    
    var job: Job!
    var pickerVisible = false
    var payRate: NSDecimalNumber!
    var previousColor: Color!
    var selectedColor: Color!
    var currentString = ""
    var company = ""
    var position = ""
    var order: Int32!
    var colors = [Color]()
    
    let dataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let predicate = NSPredicate(format: "isSelected == false")
        colors = dataManager.fetch("Color", predicate: predicate) as! [Color]
        
        selectedColor = colors[0]
        
        tableView.dataSource = self
        tableView.delegate = self
        
        payTextField.delegate = self
        
        var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        
        colorPicker.dataSource = self
        colorPicker.delegate = self
        
        if job != nil {
            let unitedStatesLocale = NSLocale(localeIdentifier: "en_US")
            let pay = job.payRate
            var numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
            numberFormatter.locale = unitedStatesLocale
            
            nameTextField.text = job.company
            positionTextField.text = job.position
            payTextField.text = numberFormatter.stringFromNumber(pay)!
            
            payRate = job.payRate
            
            colorLabel.text = job.color.name
            jobColorView.color = job.color.getColor
            
            previousColor = job.color
            selectedColor = job.color
            colors.insert(selectedColor, atIndex: 0)
        } else {
            colorLabel.text = selectedColor.name
            jobColorView.color = colors[0].getColor

            let jobs = dataManager.fetch("Job") as! [Job]
            order = Int32(jobs.count)
        }
        
        toggleSaveButton()

    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        nameTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        
        positionTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBActions
    
    @IBAction func saveJobButton(sender: AnyObject) {
        var str = nameTextField.text
        company = str.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        str = positionTextField.text
        position = str.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        if payTextField.text != nil {
            var payStr = payTextField.text
            payStr = payStr.stringByReplacingOccurrencesOfString(",", withString: "")
            payStr = payStr.stringByReplacingOccurrencesOfString("$", withString: "")
            
            payRate = NSDecimalNumber(string: payStr)
        } else {
            payRate = 0.00
        }
        
        if job != nil {
            editItem()
        } else {
            newItem()
        }
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    // MARK: - Class functions
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func toggleSaveButton() {
        if nameTextField.text == "" || positionTextField.text == "" {
            self.navigationItem.rightBarButtonItem!.enabled = false
        } else {
            self.navigationItem.rightBarButtonItem!.enabled = true
        }
    }
    
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
    }
    
    func newItem() {
        
        let color = dataManager.editItem(selectedColor, entityName: "Color") as! Color
        color.isSelected = true
        
        let job = dataManager.addItem("Job") as! Job
        
        job.order = order
        job.company = company
        job.position = position
        job.setValue(color, forKey: "color")
        job.payRate = payRate
        
        dataManager.save()
    }
    
    func editItem() {
        
        let previous = dataManager.editItem(previousColor, entityName: "Color") as! Color
        previous.isSelected = false
        
        let currentColor = dataManager.editItem(selectedColor, entityName: "Color") as! Color
        currentColor.isSelected = true
        
        let editJob = dataManager.editItem(job, entityName: "Job") as! Job
        
        editJob.company = company
        editJob.position = position
        editJob.payRate = payRate
        editJob.color = currentColor
        
        dataManager.save()
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 && indexPath.row == 1 {
            pickerVisible = !pickerVisible
            
            tableView.reloadData()
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 2 {
            if pickerVisible == false {
                return 0.0
            }
            return 150.0
        }
        return 44.0
    }
    
    
    // MARK: - Navigation 
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "payRate" {
            let destinationVC = segue.destinationViewController as! PayRateTableViewController
            destinationVC.job = self.job
        }
    }
    
}


// MARK: - Picker Data Source and Delegate

extension AddJobTableViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return colors.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return colors[row].name
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
  
        selectedColor = colors[row]
        
        colorLabel.text = selectedColor.name
        jobColorView.color = selectedColor.getColor
        jobColorView.setNeedsDisplay()
    }

}

// MARK: - TextField Delegate

extension AddJobTableViewController: UITextFieldDelegate {
    
    func textFieldDidChange(textField: UITextField) {
        let whitespaceSet = NSCharacterSet.whitespaceCharacterSet()
        
        toggleSaveButton()
    }
    
}