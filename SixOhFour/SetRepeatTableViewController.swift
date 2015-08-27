//
//  SetRepeatTableViewController.swift
//  SixOhFour
//
//  Created by jemsomniac on 7/16/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit

class SetRepeatTableViewController: UITableViewController {

    @IBOutlet weak var repeatPicker: UIPickerView!
    @IBOutlet weak var frequencyPicker: UIPickerView!
    @IBOutlet weak var viewByPicker: UIPickerView!
    @IBOutlet weak var repeatLabel: UILabel!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var viewByLabel: UILabel!
    @IBOutlet var collectionView: [UICollectionView]!
    
    var doneButton: UIBarButtonItem!
    var repeatSettings: RepeatSettings!
    var selectedDay: NSDate!
    
    var repeatPickerHidden = true
    var frequencyPickerHidden = true
    var viewByPickerHidden = true

    let weekdaysArray = ["S", "M", "T", "W", "T", "F", "S"]
    let repeatTypes = ["Never", "Weekly", "Monthly"]
    let viewBy = ["Date", "Day"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        repeatLabel.text = repeatSettings.type
        setFrequencyLabelText(repeatSettings.repeatEvery)
        
        if let repeatSettings = repeatSettings as? RepeatMonthly {
            viewByLabel.text = viewBy[repeatSettings.viewType]
        }
        
        doneButton = UIBarButtonItem(title:"Done", style: .Plain, target: self, action: "setRepeat")
        self.navigationItem.rightBarButtonItem = self.doneButton
    
        var row = 0
        
        if repeatSettings.type == "Weekly" {
            row = 1
        } else if repeatSettings.type == "Monthly" {
            row = 2
        }
        
        repeatPicker.selectRow(row, inComponent: 0, animated: true)
        frequencyPicker.selectRow(repeatSettings.repeatEvery-1, inComponent: 0, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Class Functions
    
    func setFrequencyLabelText(row: Int) {
        var str = "\(row) "
        
        if repeatSettings.type == "Weekly" {
            // Max value for weeks is 4
            if row > 4 {
                str = "4 "
            }
            
            str += "week"
        } else if repeatSettings.type == "Monthly" {
            str += "month"
        }
        
        if row > 1 {
            str += "s"
        }
        
        frequencyLabel.text = str
    }
    
    func setRepeat() {
        if repeatSettings.type == "Never" {
            repeatSettings = RepeatSettings(startDate: selectedDay)
        }
        
        self.performSegueWithIdentifier("unwindAfterSetRepeat", sender: self)
    }
    
    func togglePicker(picker: String) {
        switch(picker) {
        case "repeatPicker":
            repeatPickerHidden = !repeatPickerHidden
            frequencyPickerHidden = true
            viewByPickerHidden = true
        case "frequencyPicker":
            frequencyPickerHidden = !frequencyPickerHidden
            repeatPickerHidden = true
            viewByPickerHidden = true
        case "viewByPicker":
            viewByPickerHidden = !viewByPickerHidden
            repeatPickerHidden = true
            frequencyPickerHidden = true
        default:
            repeatPickerHidden = true
            frequencyPickerHidden = true
            viewByPickerHidden = true
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if repeatSettings.type == "Never" {
            return 1
        } else {
            return 2
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 6
        } else {
            if repeatSettings.type == "Weekly" {
                return repeatSettings.repeatEvery
            } else {
                return 0
            }
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var header = ""
        
        if let repeatSettings = repeatSettings as? RepeatWeekly {
            if repeatSettings.repeatEvery == 1 {
                header = "Repeat every week"
            } else {
                header = "Repeat every \(repeatSettings.repeatEvery) weeks"
            }
        }
        
        if let repeatSettings = repeatSettings as? RepeatMonthly {
            header = "Repeat on the following \(viewBy[repeatSettings.viewType])s"
        }
        
        if section == 1 {
            return header
        }
        
        return ""
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            togglePicker("repeatPicker")
        } else if indexPath.section == 0 && indexPath.row == 2 {
            togglePicker("frequencyPicker")
        } else if indexPath.section == 0 && indexPath.row == 4 {
            togglePicker("viewByPicker")
        } else {
            togglePicker("close")
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if repeatPickerHidden && indexPath.section == 0 && indexPath.row == 1 {
            return 0
        }
        
        if frequencyPickerHidden && indexPath.section == 0 && indexPath.row == 3 {
            return 0
        }
        
        if viewByPickerHidden && indexPath.section == 0 && indexPath.row == 5 {
            return 0
        }
        
        if repeatSettings.type == "Never" && indexPath.section == 0 && indexPath.row == 2 {
            return 0
        }
        
        if repeatSettings.type != "Monthly" && indexPath.section == 0 && indexPath.row == 4 {
            return 0
        }
        
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
}


// MARK: - Picker View Data Source and Delegate

extension SetRepeatTableViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        switch(pickerView) {
        case repeatPicker:
            return 1
        case frequencyPicker:
            return 2
        case viewByPicker:
            return 1
        default:
            return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch(pickerView) {
        case repeatPicker:
            // TODO: Enable monthly repeat on next version
            return 2
        case frequencyPicker:
            if component == 0 {
                if repeatSettings.type == "Weekly" {
                    return 4
                } else if repeatSettings.type == "Monthly" {
                    return 12
                }
            }
            return 1
        case viewByPicker:
            return 2
        default:
            return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        switch(pickerView) {
        case repeatPicker:
            return repeatTypes[row]
        case frequencyPicker:
            if component == 0 {
                return "\(row+1)"
            } else {
                if repeatSettings.type == "Weekly" {
                    if pickerView.selectedRowInComponent(0) > 0 {
                        return "weeks"
                    } else {
                        return "week"
                    }
                } else if repeatSettings.type == "Monthly" {
                    if pickerView.selectedRowInComponent(0) > 0  {
                        return "months"
                    } else {
                        return "month"
                    }
                } else {
                    return ""
                }
            }
        case viewByPicker:
            return viewBy[row]
        default:
            return ""
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch(pickerView) {
        case repeatPicker:
            repeatLabel.text = repeatTypes[row]

            if row == 1 {
                repeatSettings = RepeatWeekly(startDate: selectedDay)
                
                let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
                let components = calendar.components(NSCalendarUnit.CalendarUnitWeekday, fromDate: selectedDay)
                
                repeatSettings.daySelectedIndex = components.weekday-1

                if let repeatSettings = self.repeatSettings as? RepeatWeekly {
                    repeatSettings.daysToRepeat[0][repeatSettings.daySelectedIndex] = true
                }
            } else if row == 2 {
                repeatSettings = RepeatMonthly(startDate: selectedDay)
                
                if let repeatSettings = self.repeatSettings as? RepeatMonthly  {
                    viewByLabel.text = viewBy[repeatSettings.viewType]
                    viewByPicker.selectRow(repeatSettings.viewType, inComponent: 0, animated: true)

                }
            }
            
            repeatSettings.type = repeatTypes[row]

            var repeatEvery = frequencyPicker.selectedRowInComponent(0)+1
            setFrequencyLabelText(repeatEvery)
            
            if repeatSettings.type == "Weekly" && repeatEvery > 4 {
                repeatSettings.repeatEvery = 4
            } else {
                repeatSettings.repeatEvery = repeatEvery
            }
                        
            // Update table view cells
            for x in 0...3 {
                collectionView[x].reloadData()
            }
            
        case frequencyPicker:
            setFrequencyLabelText(row+1)
            
            var previous = repeatSettings.repeatEvery
            var current = row + 1
            
            repeatSettings.repeatEvery = current
            
            if let repeatSettings = self.repeatSettings as? RepeatWeekly  {
                if current > previous {
                    for x in previous...row {
                        for y in 0...6 {
                            repeatSettings.daysToRepeat[x][y] = repeatSettings.daysToRepeat[x-1][y]
                        }
                        collectionView[x].reloadData()
                    }
                }
            }
            
        case viewByPicker:
            if let repeatSettings = repeatSettings as? RepeatMonthly  {
                repeatSettings.viewType = row
                viewByLabel.text = viewBy[repeatSettings.viewType]
                
                self.repeatSettings = repeatSettings
            }
        default: ()
            
        }

        frequencyPicker.reloadAllComponents()
        tableView.reloadData()
    }
}


// MARK: - Collection View Data Source and Delegate

extension SetRepeatTableViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weekdaysArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("WeekDayCell", forIndexPath: indexPath) as! WeekDayCollectionViewCell
        
        var weekIndex = collectionView.tag
        
        if let repeatSettings = repeatSettings as? RepeatWeekly {
            if (weekIndex == 0 && indexPath.row == repeatSettings.daySelectedIndex) {
                cell.backgroundColor = .colorFromCode(0xFF5E3A)
                cell.dayLabel.textColor = UIColor.whiteColor()
            } else if repeatSettings.daysToRepeat[weekIndex][indexPath.row]{
                cell.backgroundColor = .colorFromCode(0x1D62F0)
                cell.dayLabel.textColor = UIColor.whiteColor()
            } else {
                cell.backgroundColor = UIColor.whiteColor()
                cell.dayLabel.textColor = UIColor.blackColor()
            }
            
            cell.dayLabel.font = UIFont.boldSystemFontOfSize(12.0)
            cell.dayLabel.text = weekdaysArray[indexPath.row]
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! WeekDayCollectionViewCell
        
        var weekIndex = collectionView.tag
        
        if let repeatSettings = repeatSettings as? RepeatWeekly {
     
            if repeatSettings.daysToRepeat[weekIndex][indexPath.row] == false{
                cell.backgroundColor = .colorFromCode(0x1D62F0)
                cell.dayLabel.textColor = UIColor.whiteColor()
                
                repeatSettings.daysToRepeat[weekIndex][indexPath.row] = true
            } else {
                if !(weekIndex == 0 && indexPath.row == repeatSettings.daySelectedIndex) {
                cell.backgroundColor = UIColor.whiteColor()
                cell.dayLabel.textColor = UIColor.blackColor()
                
                repeatSettings.daysToRepeat[weekIndex][indexPath.row] = false
                }
            }
    
            // Reset the selected days for weeks not displayed
            if repeatSettings.repeatEvery < 4 {
                for x in repeatSettings.repeatEvery...3 {
                    for y in 0...6 {
                        repeatSettings.daysToRepeat[x][y] = false
                    }
                }
            }
            
        }
    }
}

