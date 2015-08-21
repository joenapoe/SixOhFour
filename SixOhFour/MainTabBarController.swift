//
//  MainTabBarController.swift
//  SixOhFour
//
//  Created by Jem on 6/24/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    var dataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //  Each of these are relative to the storyboard files they belong to
        let addJobStoryboard: UIStoryboard = UIStoryboard(name: "AddJobStoryboard", bundle: nil)
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let clockInStoryboard: UIStoryboard = UIStoryboard(name: "ClockInStoryboard", bundle: nil)
        let calendarStoryboard: UIStoryboard = UIStoryboard(name: "CalendarStoryboard", bundle: nil)
        
        let clockInVC: UINavigationController = clockInStoryboard.instantiateViewControllerWithIdentifier("ClockInNavController") as! UINavigationController
        let calendarVC: UINavigationController = calendarStoryboard.instantiateViewControllerWithIdentifier("CalendarNavController") as! UINavigationController
        let addJobsVC: HomeViewController = addJobStoryboard.instantiateViewControllerWithIdentifier("HomeViewController") as! HomeViewController
        
        let homeIcon = UITabBarItem(title: "", image:UIImage(named: "home.png"), tag: 1)
        let clockInIcon = UITabBarItem(title: "", image:UIImage(named: "clock.png"), tag: 2)
        let calendarIcon = UITabBarItem(title: "", image:UIImage(named: "calendar.png"), tag: 3)

        addJobsVC.tabBarItem = homeIcon
        clockInVC.tabBarItem = clockInIcon
        calendarVC.tabBarItem = calendarIcon
        
        self.viewControllers = [UINavigationController(rootViewController: addJobsVC), clockInVC, calendarVC ]
        

        // Pre-populate the Color table when the app is opened for the first time
        
        var colors = dataManager.fetch("Color") as! [Color]
        
        let defaultColors = ["Red", "Magenta", "Purple", "Blue", "Cyan", "Green", "Yellow", "Orange", "Brown", "Gray"]

        if colors.isEmpty {
            for d in defaultColors {
                
                let color = dataManager.addItem("Color") as! Color
            
                color.name = d
                color.isSelected = false
                
                dataManager.save()
            }
        }
     
        // Check to see if last running shift (status = 2) needs to be convert to incomplete (status = 1)
        
        let predicateOpenWS = NSPredicate(format: "status == 2")
        var runningShifts = [WorkedShift]()
        runningShifts = dataManager.fetch("WorkedShift", predicate: predicateOpenWS) as! [WorkedShift]
        println("First Checkpoint = see if there are any runningShifts:")
        println("runningShifts.count = \(runningShifts.count)")
    
        if runningShifts.count > 0 {

            //convert all status = 1
            for WorkedShift in runningShifts {
                WorkedShift.status = 1
            }
            dataManager.save()

            // TEST: Check to see if 0
            runningShifts = dataManager.fetch("WorkedShift", predicate: predicateOpenWS) as! [WorkedShift]
            println("Second checkpoint: was it converted?")
            println("runningShifts.count = \(runningShifts.count)")
        }
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
