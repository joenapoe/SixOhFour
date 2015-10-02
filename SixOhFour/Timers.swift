//
//  Timers.swift
//  SixOhFour
//
//  Created by Joseph Pelina on 9/25/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

class Timers {
    
    //    TODO: Migrate the timers from ClockIn to this class
    
    var seconds: Double!
    
    func work() -> Double {
        
        return seconds
    }
    
//    func countdownBreaktime(breaktimeSecondsRemaining: Double, startedBreakTime: NSDate! ) -> String {
//            
//            var differenceInTime = NSDate().timeIntervalSinceDate(startedBreakTime)
//            breaktimeSecondsRemaining = breaktimeSecondsSet - differenceInTime
//            
//            if breaktimeSecondsRemaining >= 3600 {
//                breakSeconds = (breaktimeSecondsRemaining % 60 ) % 60
//                breakMinutes = (breaktimeSecondsRemaining % 3600 ) / 60
//                breakHours = breaktimeSecondsRemaining / 60 / 60
//            } else if breaktimeSecondsRemaining >= 60 {
//                breakSeconds = breaktimeSecondsRemaining % 60
//                breakMinutes = breaktimeSecondsRemaining / 60
//                breakHours = 0
//            } else if breaktimeSecondsRemaining >= 0 {
//                breakSeconds = breaktimeSecondsRemaining
//                breakMinutes = 0
//                breakHours = 0
//            } else {
//                alertBreakOver()
//                breakTimer.invalidate()
//                breakTimerOver = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("runBreakTimerOver"), userInfo: nil, repeats: true)
//            }
//            breakTimerString  = getTimerString(breakSeconds, minutes: breakMinutes, hours: breakHours)
//            breakTimeLabel.text = breakTimerString
//        
//            return breakTimerString
//        
//    }

    func overBreak() -> Double {

        return seconds
    }





//    var remainingbreakSeconds = 0
//    var remainingbreakMinutes = 0
//    var remainingbreakHours = 0
//
//    var breakMinutesSet = 30
//    var breakSecondsSet = 0
//    var breakHoursSet = 0
//
//    var breakMinutesChange = 0
//    var breakHoursChange = 0




//    func breakReset() {
//        breakMinutes = breakMinutesSet
//        breakSeconds = breakSecondsSet
//        breakHours = breakHoursSet
//    }

    var hours: Double = 0.0
    var minutes: Double = 0.0
//    var seconds: Double = 0.0
    
    func convertSecondsIntoTime(totalSeconds: Double) {
        if totalSeconds >= 3600 {
            seconds = (totalSeconds % 60 ) % 60
            minutes = (totalSeconds % 3600 ) / 60
            hours = totalSeconds / 60 / 60
        } else if totalSeconds >= 60 {
            seconds = totalSeconds % 60
            minutes = totalSeconds / 60
            hours = 0
        } else {
            seconds = totalSeconds
            minutes = 0
            hours = 0
        }
    }
}