//
//  WorkedShift.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/29/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import UIKit
import Foundation
import CoreData
@objc(WorkedShift)

class WorkedShift: NSManagedObject {

    @NSManaged var source: String
    @NSManaged var status: NSNumber
    @NSManaged var job: Job
    @NSManaged var timelogs: NSSet
    @NSManaged var duration: Double
    
    
    var pay: Double!
    var dataManager = DataManager()
    
    func hoursWorked() -> Double {
        var hoursWorked: Double = round(( 100 * ( duration / 3600 ) ) / 100 )
        return hoursWorked
    }
    
    func moneyShift() -> Double {
        pay  = round(( 100 * (duration / 3600) * ( Double(self.job.payRate) ) ) / 100)
        return pay
    }

    func moneyShiftOT() -> Double {
        if duration > (60*60*8) {
            pay =  round(( 100 * ((duration-(60*60*8))*1.5+8) * ( Double(self.job.payRate) ) ) / 100)
            return pay
        } else {
            moneyShift()
        }
        return pay
    }
    
    func moneyShiftOTx2() -> Double {
        if duration > (60*60*12) {
            pay =  round(( 100 * ((duration-(60*60*12))*2+8+(1.5*4)) * ( Double(self.job.payRate) ) ) / 100)
            return pay
        } else if duration > (60*60*8) {
            moneyShiftOT()
        } else {
            moneyShift()
        }
        return pay
    }
    
    

    
    

    func sumUpDuration() {
        
        var TLset = self.timelogs //NSSet
//        var arr = set.allObjects //Swift Array
        var TLnsarr = TLset.allObjects as NSArray  //NSArray
        var sortedTLnsarr = (TLnsarr).sortedArrayUsingDescriptors([NSSortDescriptor(key: "time", ascending: true)]) as! [Timelog]
        
        println("SELF timelogslist count = \(sortedTLnsarr.count)")
//        println("SELF timelogslist = \(sortedTLnsarr)")

        
        var totalBreaktime : Double = 0.0
        var subtractor = 0
        
        
        //SUMMING UP BREAKS!
        
        //if open status, then need to add in subrator for possible open breaks
        if self.status == 1 {
            //last time is a start break // currently on break
            if sortedTLnsarr.count % 2 == 0  {
                subtractor = 1
            } else {
                subtractor = 0
            }
        }
//        println("subtrator = \(subtractor)")
        
        if ((self.status == 1) && (sortedTLnsarr.count > 1)) || ((self.status == 0) && (sortedTLnsarr.count > 2)) {
        
//            var hoursWorked: Double = round(( 100 * ( duration / 3600 ) ) / 100 )
            
            var breakCount: Int =  ((sortedTLnsarr.count)/2)
            var tempTotalBreaktime = Double()
                    var breakCountdown =  ( (breakCount) - subtractor) * 2
                    totalBreaktime = Double()
                    var partialBreaktime = Double()
        
                    // NOTE : Calculates Break times for all the breakSets the user has in the shift
                    if breakCount-subtractor >= 1 {
                        for i in 1...(breakCount-subtractor) {
                            println("PERFORMING TASK#1")
                            partialBreaktime = (sortedTLnsarr[breakCountdown].time).timeIntervalSinceDate((sortedTLnsarr[breakCountdown-1]).time)
                            println("partialBreaktime from workedshit.class = \(partialBreaktime)")
                            tempTotalBreaktime = tempTotalBreaktime + partialBreaktime
                            println("tempTotalBreaktime from workedshit.class = \(tempTotalBreaktime)")
                            breakCountdown = breakCountdown - 2
                        }
                    }
                    totalBreaktime = tempTotalBreaktime

        }
        
        //SUM UP TOTAL
        let totalShiftTimeInterval = (sortedTLnsarr.last!.time).timeIntervalSinceDate(sortedTLnsarr.first!.time)
        duration = (totalShiftTimeInterval) - (totalBreaktime)
        
        println("totalBreaktime from workedshit.class = \(totalBreaktime)")
        println("duration from workedshit.class = \(duration)")
        println("workedshift from workedshit.class = \(self)")

        
    
    
    
//    func sumUpBreaks() {
//        
//        if timelogs.containsObject(Timelog).type == "" {
//        
//        }
//        
//        var subtractor: Int!
//        
//        if flow == "onBreak" {
//            subtractor = 1
//        } else {
//            subtractor = 0
//        }
//        
//        if breakCount > 0 {
//            
//            var breakCountdown = (breakCount-subtractor) * 2
//            var tempTotalBreaktime : Double = 0
//            var partialBreaktime: Double = 0
//            
//            // NOTE : Calculates Break times for all the breakSets the user has in the shift
//            if breakCount-subtractor >= 1 {
//                for i in 1...(breakCount-subtractor) {
//                    partialBreaktime = timelogTimestamp[breakCountdown].timeIntervalSinceDate(timelogTimestamp[breakCountdown-1])
//                    tempTotalBreaktime = tempTotalBreaktime + partialBreaktime
//                    breakCountdown = breakCountdown - 2
//                }
//                
//            }
//            totalBreaktime = tempTotalBreaktime
//        }
//    }
//    
//    func sumUpWorkDuration() {
//        
//        let totalShiftTimeInterval = (timelogTimestamp.last)!.timeIntervalSinceDate(timelogTimestamp[0])
//        duration = (totalShiftTimeInterval) - (totalBreaktime)
//        elapsedTime = Int(duration)
//        updateWorkTimerLabel()
//        
    }
    
}