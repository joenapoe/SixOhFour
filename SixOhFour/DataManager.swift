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
    
    func delete(objectToDelete: NSManagedObject) {
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
