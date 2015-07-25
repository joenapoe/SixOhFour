//
//  SetBreakTimeViewController.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 7/16/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class SetBreakTimeViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    
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

        // Do any additional setup after loading the view.
        
        self.SetBreakTimePicker.dataSource = self
        self.SetBreakTimePicker.delegate = self

        SetBreakTimePicker.selectRow(breakHours, inComponent: 0, animated: true)
        SetBreakTimePicker.selectRow(breakMinutes, inComponent: 1, animated: true)
        
        println("breakMinutesSet from Clockin = \(breakMinutes)")
        println("breakHoursSet from Clockin = \(breakHours)")

        doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: "doneSettingBreak")
        self.navigationItem.rightBarButtonItem = doneButton
        
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func doneSettingBreak () {
        self.performSegueWithIdentifier("unwindFromSetBreakTimeViewController", sender: self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - Set Break Time Picker
    
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
            println("breakMinutesSet changed to \(breakMinutes)")
        } else if component == 1 {
            breakMinutes = row
            
            if breakMinutes == 0 && breakHours == 0 {
                breakMinutes = 1
                println("Minimum 1 min break")
            } else {
            println("breakMinutesSet changed to \(breakMinutes)")
            }
        }
    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        println("This happened")
//        if segue.identifier == "unwindFromSetBreakTimeViewController" {
//            let destinationVC = segue.destinationViewController as! ClockInViewController
//            
//            //Passes 2 data variables
//            destinationVC.breakMinutes = self.breakMinutes
//            destinationVC.breakHours = self.breakHours
//        }
//    }
}
