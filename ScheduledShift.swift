//
//  ScheduledShift.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/29/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import Foundation
import CoreData
@objc(ScheduledShift)

class ScheduledShift: NSManagedObject {

    @NSManaged var endTime: NSDate
    @NSManaged var startTime: NSDate
    @NSManaged var job: Job
}
