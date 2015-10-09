//
//  DataManager.swift
//  SixOhFour
//
//  Created by jemsomniac on 8/6/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import CoreData

class DataManager {
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    func fetch(entityName: String) -> NSArray {
        var request = NSFetchRequest(entityName: entityName)
        request.returnsObjectsAsFaults = false;
        
        var results: NSArray = context!.executeFetchRequest(request, error: nil)!
        
        return results
    }
    
    func fetch(entityName: String, predicate: NSPredicate) -> NSArray {
        var request = NSFetchRequest(entityName: entityName)
        
        request.returnsObjectsAsFaults = false;
        request.predicate = predicate
        
        var results:NSArray = context!.executeFetchRequest(request, error: nil)!
        
        return results
    }
    
    func fetch(entityName: String, sortDescriptors: [NSSortDescriptor]) -> NSArray {
        var request = NSFetchRequest(entityName: entityName)
        
        request.returnsObjectsAsFaults = false;
        request.sortDescriptors = sortDescriptors
        
        var results:NSArray = context!.executeFetchRequest(request, error: nil)!
        
        return results
    }
    
    func fetch(entityName: String, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) -> NSArray {
        var request = NSFetchRequest(entityName: entityName)
        
        request.returnsObjectsAsFaults = false;
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        var results:NSArray = context!.executeFetchRequest(request, error: nil)!
        
        return results
    }
    
    func fetchRepeatingSchedule(shift: ScheduledShift) -> [ScheduledShift]{
        var schedule = [ScheduledShift]()
        
        let sortDescriptor = NSSortDescriptor(key: "startTime", ascending: true)
        let sortDescriptors = [sortDescriptor]
        let results = fetch("ScheduledShift", sortDescriptors: sortDescriptors)
        let firstShift = results[0] as! ScheduledShift
        let lastShift = results[results.count-1] as! ScheduledShift
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        var today = NSDate()
        today = calendar.startOfDayForDate(today)
        let startDateMidnight = calendar.startOfDayForDate(shift.startTime)
        let endDateMidnight = calendar.startOfDayForDate(shift.endTime)

        let startComponents = calendar.components(NSCalendarUnit.CalendarUnitDay, fromDate: today, toDate: startDateMidnight, options: nil)
        let endComponents = calendar.components(NSCalendarUnit.CalendarUnitDay, fromDate: today, toDate: endDateMidnight, options: nil)
        let startOffset = startComponents.day % 7
        let endOffset = startOffset + (endComponents.day - startComponents.day)

        let timeComps = (NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitMinute | NSCalendarUnit.CalendarUnitSecond)
        let startTimeComponents = calendar.components(timeComps, fromDate: shift.startTime)
        let endTimeComponents = calendar.components(timeComps, fromDate: shift.endTime)
        
        var startDate = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: startOffset, toDate: today, options: nil)!
        var endDate = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: endOffset, toDate: today, options: nil)!

        startDate = calendar.dateByAddingComponents(startTimeComponents, toDate: startDate, options: nil)!
        endDate = calendar.dateByAddingComponents(endTimeComponents, toDate: endDate, options: nil)!
        
        // DELETE TEST
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        formatter.timeZone = NSTimeZone()
        
        println(formatter.stringFromDate(shift.startTime))
        println(formatter.stringFromDate(shift.endTime))
        
        println(formatter.stringFromDate(startDate))
        println(formatter.stringFromDate(endDate))
        
        while startDate.compare(lastShift.startTime) == NSComparisonResult.OrderedAscending {
            
            let predicate = NSPredicate(format: "startTime == %@ && endTime == %@", startDate, endDate)
            let results = fetch("ScheduledShift", predicate: predicate) as! [ScheduledShift]

            if results.count > 0 {
                if shift != results[0] {
                    schedule.append(results[0])
                }
            }
            
            startDate = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: 7, toDate: startDate, options: nil)!
            endDate = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: 7, toDate: endDate, options: nil)!
        }
        
        if shift != lastShift && startDate.compare(lastShift.startTime) == NSComparisonResult.OrderedSame && endDate.compare(lastShift.endTime) == NSComparisonResult.OrderedSame {
            schedule.append(lastShift)
        }

        return schedule
    }
    
    func delete(objectToDelete: NSManagedObject) {
        if let job = objectToDelete as? Job {

            let wArray = job.workedShifts.allObjects as NSArray
            let workedShifts = wArray as! [WorkedShift]
    
            for shift in workedShifts{
                delete(shift)
            }
            
            let sArray = job.scheduledShifts.allObjects as NSArray
            let scheduledShifts = sArray as! [ScheduledShift]
            
            for shift in scheduledShifts {
               delete(shift)
            }
        } else if let shift = objectToDelete as? ScheduledShift {
            let app = UIApplication.sharedApplication()

            for event in app.scheduledLocalNotifications {
                let notification = event as! UILocalNotification
                let startTime = notification.fireDate
                
                if shift.startTime.compare(startTime!) == NSComparisonResult.OrderedSame && notification.alertAction == "clock in"{
                    app.cancelLocalNotification(notification)
                    break
                }
            }
        } else if let shift = objectToDelete as? WorkedShift {
            for timelog in shift.timelogs {
                context?.deleteObject(timelog as! NSManagedObject)
            } 
        }
        
        context?.deleteObject(objectToDelete)
        save()
    }
    
    func addItem(entityName: String) -> NSManagedObject {
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context!)
        let object = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: context)
        
        return object
    }
    
    
    func editItem(entity: NSManagedObject, entityName: String) -> NSManagedObject {
        let predicate = NSPredicate(format: "SELF == %@", entity)
        let result = fetch(entityName, predicate: predicate)
        
        return result[0] as! NSManagedObject
    }
    
    func save() {
        context!.save(nil)
    }
    
    func undo() {
        context?.rollback()
    }
}
