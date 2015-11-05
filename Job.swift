//
//  Job.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/29/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import Foundation
import CoreData
@objc(Job)

class Job: NSManagedObject {

    @NSManaged var company: String
    @NSManaged var order: Int32
    @NSManaged var payRate: NSDecimalNumber
    @NSManaged var position: String
    @NSManaged var color: Color
    @NSManaged var scheduledShifts: NSSet
    @NSManaged var workedShifts: NSSet

    
}
