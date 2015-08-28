//
//  SetBreakTimeViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 7/16/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class SetBreakTimeViewController: UIViewController {
    
    
    @IBOutlet weak var SetBreakTimePicker: UIPickerView!
    
    var breakHoursRange = 3
    var breakMinutesRange = 60
    
    var breakHours = 0 //intial value, but then changed with segue
    var breakMinutes = 0 //intial value, but then changed with segue
    
    var breakHoursSetIntial = 0 //intial value, but then changed with segue
    var breakMinutesSetIntial = 0 //intial value, but then changed with segue
    
    var doneButton : UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.SetBreakTimePicker.dataSource = self
        self.SetBreakTimePicker.delegate = self
        
        SetBreakTimePicker.selectRow(breakHours, inComponent: 0, animated: true)
        SetBreakTimePicker.selectRow(breakMinutes, inComponent: 1, animated: true)
        
        doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: "doneSettingBreak")
        self.navigationItem.rightBarButtonItem = doneButton
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Class Functions
    
    func doneSettingBreak () {
        self.performSegueWithIdentifier("unwindFromSetBreakTimeViewController", sender: self)
    }
}


// MARK: - Picker View Source and Delegate

extension SetBreakTimeViewController: UIPickerViewDataSource, UIPickerViewDelegate{
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if component == 0 {
            return breakHoursRange
        } else if component == 1 {
            return breakMinutesRange
        } else {
            return 0
        }
        
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        
        if component == 0{
            return "\(row)"
        } else {
            return "\(row)"
        }
        
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            breakHours = row
        } else if component == 1 {
            breakMinutes = row
            
            if breakMinutes == 0 && breakHours == 0 {
                breakMinutes = 1
                SetBreakTimePicker.selectRow(1, inComponent: 1, animated: true)
            } else {
            }
        }
    }
}