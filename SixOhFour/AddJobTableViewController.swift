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
    @IBOutlet weak var payRateLabel: UILabel!
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var colorPicker: UIPickerView!
    @IBOutlet weak var jobColorView: JobColorView!
    @IBOutlet weak var saveJobButton: UIBarButtonItem!

    var job: Job!
    var pickerVisible = false
    var payRate: NSDecimalNumber!
    var previousColor: Color!
    var selectedColor: Color!
    
    let dataManager = DataManager()
    var colors = [Color]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let predicate = NSPredicate(format: "isSelected == false")
        colors = dataManager.fetch("Color", predicate: predicate) as! [Color]
        
        selectedColor = colors[0]
        
        tableView.dataSource = self
        tableView.delegate = self
        
        colorPicker.dataSource = self
        colorPicker.delegate = self
        
        if job != nil {
            let unitedStatesLocale = NSLocale(localeIdentifier: "en_US")
            let pay = job.payRate
            var numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
            numberFormatter.locale = unitedStatesLocale
            
            nameTextField.text = job.company.name
            positionTextField.text = job.position
            payRateLabel.text = numberFormatter.stringFromNumber(pay)!
            
            payRate = job.payRate
            colorLabel.text = job.color.name
            jobColorView.color = job.color.getColor
            
            previousColor = job.color
            selectedColor = job.color
            colors.insert(selectedColor, atIndex: 0)
        } else {
            colorLabel.text = selectedColor.name
            jobColorView.color = colors[0].getColor

        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if nameTextField.text == "" {
            self.navigationItem.rightBarButtonItem!.enabled = false
        }
        
        nameTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        
        // so fresh and so clean :]
//        if job != nil {
//            let selectedColor = find(colors, job.color)
//            colorPicker.selectRow(selectedColor!, inComponent: 0, animated: true)
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBActions
    
    @IBAction func saveJobButton(sender: AnyObject) {
        if job != nil {
            editItem()
        } else {
            newItem()
        }
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func unwindFromPayRateTableViewController(segue: UIStoryboardSegue) {
        let sourceVC = segue.sourceViewController as! PayRateTableViewController
        payRateLabel.text = "\(sourceVC.payTextField.text)"
        
        var str = sourceVC.payTextField.text
        str = str.stringByReplacingOccurrencesOfString(",", withString: "")
        str = str.stringByReplacingOccurrencesOfString("$", withString: "")
        
        print("str ")
        println(str)
        
        payRate = NSDecimalNumber(string: str)
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - Class functions
    
    func newItem() {
        // TODO: We should pass job.position to coredata instead of positionTextField.text
        
        let color = dataManager.editItem(selectedColor, entityName: "Color") as! Color
        color.isSelected = true
        
        let company = dataManager.addItem("Company") as! Company
        let job = dataManager.addItem("Job") as! Job
        
        company.name = nameTextField.text
        job.setValue(company, forKey: "company")
        job.position = positionTextField.text
        job.setValue(color, forKey: "color")
        
        if payRate == nil {
            job.payRate = 0.00
        } else {
            job.payRate = self.payRate
        }
        dataManager.save()
    }
    
    func editItem() {
        
        let previous = dataManager.editItem(previousColor, entityName: "Color") as! Color
        previous.isSelected = false
        
        let currentColor = dataManager.editItem(selectedColor, entityName: "Color") as! Color
        currentColor.isSelected = true
        
        let editJob = dataManager.editItem(job, entityName: "Job") as! Job
        
        editJob.company.name = nameTextField.text
        editJob.position = positionTextField.text
        editJob.payRate = payRate
        editJob.color = currentColor
        
        dataManager.save()
    }
    
    
    // MARK: - Table view data source
    
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
        if textField.text.stringByTrimmingCharactersInSet(whitespaceSet) != "" {
            self.navigationItem.rightBarButtonItem!.enabled = true
        }
    }
    
}