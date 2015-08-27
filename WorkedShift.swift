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

    @NSManaged var duration: Double
    @NSManaged var source: String
    @NSManaged var status: NSNumber
    @NSManaged var job: Job
    @NSManaged var timelogs: NSSet
    
    var pay: Double!
    var dataManager = DataManager()
    var totalBreaktime : Double = 0.0
    var sortedTLnsarr = [Timelog]()
    
    func hoursWorked() -> Double {
        sumUpDuration()
        var hoursWorked: Double = (round( 100 * ( duration / 3600 ) ) / 100 )
        return hoursWorked
    }
    
    func moneyShift() -> Double {
        pay  = (round( 100 * (duration / 3600) * ( Double(self.job.payRate) ) ) / 100)
        return pay
    }


    func moneyShiftOT() -> Double {
        if duration > (60*60*8) {
            pay =  (round( 100 * (((duration / 3600) - 8 )*1.5 + 8) * ( Double(self.job.payRate) ) ) / 100)
            return pay
        } else {
            moneyShift()
        }
        return pay
    }
    
    func moneyShiftOTx2() -> Double {
        if duration > (60*60*12) {
            pay =  (round( 100 * (((duration / 3600) - 12 )*2 + (8) + (1.5*4) ) * ( Double(self.job.payRate) ) ) / 100)
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
        sortedTLnsarr = (TLnsarr).sortedArrayUsingDescriptors([NSSortDescriptor(key: "time", ascending: true)]) as! [Timelog]
        
        println("SELF timelogslist count = \(sortedTLnsarr.count)")
//        println("SELF timelogslist = \(sortedTLnsarr)")
        
        //SUM UP TOTAL
        let totalShiftTimeInterval = (sortedTLnsarr.last!.time).timeIntervalSinceDate(sortedTLnsarr.first!.time)
        duration = (totalShiftTimeInterval) - ( sumUpBreaktime() )
        
        println("totalBreaktime from workedshit.class = \(totalBreaktime)")
        println("duration from workedshit.class = \(duration)")
        println("workedshift from workedshit.class = \(self)")

    }

    func sumUpBreaktime() -> Double{
            
        // TODO : Remove this factors
        var subtractor = 0
        var open = 0
        
        //SUMMING UP BREAKS!
        
        if self.status == 1 { //if open status, then need to add in subrator for possible open breaks
            
            if sortedTLnsarr.count % 2 == 0  { //last entry = "start break" // currently on break
                subtractor = 1
            } else { //last entry = "end break"
                subtractor = 0
            }
            open = 0
        } else {
            open = 1 //last entry = "clocked out" so need to subtract 1 from array.count
        }
        
        if ((self.status != 0) && (sortedTLnsarr.count > 1)) || ((self.status == 0) && (sortedTLnsarr.count > 2)) {
            
            var breakCount: Int =  (( sortedTLnsarr.count - open )/2)
            println("breakCount = \(breakCount)")
            println("subtractor = \(subtractor)")
            
            var tempTotalBreaktime = Double()
            var breakCountdown =  ( (breakCount) - subtractor) * 2
            totalBreaktime = Double()
            var partialBreaktime = Double()
            
            // NOTE : Calculates Break times for all the breakSets the user has in the shift
            if breakCount-subtractor >= 1 {
                for i in 1...(breakCount-subtractor) {
                    println("PERFORMING TASK#1")
                    
                    var endBreak = sortedTLnsarr[breakCountdown].time
                    var startBreak = sortedTLnsarr[breakCountdown-1].time
                    partialBreaktime = endBreak.timeIntervalSinceDate(startBreak)
                    
                    println("partialBreaktime from workedshit.class = \(partialBreaktime)")
                    tempTotalBreaktime = tempTotalBreaktime + partialBreaktime
                    println("tempTotalBreaktime from workedshit.class = \(tempTotalBreaktime)")
                    breakCountdown = breakCountdown - 2
                }
            }
            totalBreaktime = tempTotalBreaktime
        }

        return totalBreaktime
    }
    
}