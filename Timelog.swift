//
//  Timelog.swift
//  SixOhFour
//
//  Created by vinceboogie on 7/29/15.
//  Copyright (c) 2015 vinceboogie. All rights reserved.
//

import Foundation
import CoreData
@objc(Timelog)

class Timelog: NSManagedObject {

    @NSManaged var comment: String
    @NSManaged var lastUpdate: NSDate
    @NSManaged var time: NSDate
    @NSManaged var type: String
    @NSManaged var updatedBy: String
    @NSManaged var workedShift: WorkedShift
    @NSManaged var id: Int16

}
