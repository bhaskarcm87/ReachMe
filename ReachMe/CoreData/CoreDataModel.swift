//
//  CoreDataModel.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/20/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import CoreData

open class CoreDataModel {
    
    var userProfile: Profile?

    static let sharedInstanc = CoreDataModel()
    
    open var dataModel = "ReachMe"
    
    private lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: self.dataModel, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("\(self.dataModel).sqlite")
        var failureReason = "CoreData - There was an error creating or loading the application's saved data."
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true ]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "CoreData - Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSLog("CoreData - Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    open lazy var managedObjectContext: NSManagedObjectContext = {
        
        var managedObjectContext: NSManagedObjectContext?
//        if #available(iOS 10.0, *) {
//            managedObjectContext = self.persistentContainer.viewContext
//        } else {
            let coordinator = self.persistentStoreCoordinator
            managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            managedObjectContext?.persistentStoreCoordinator = coordinator
            
        //}
        return managedObjectContext!
    }()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.dataModel)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("CoreData - Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    open func saveContext () {
        if managedObjectContext.hasChanges {
            //managedObjectContext.performAndWait({
                do {
                    try self.managedObjectContext.save()
                    //CoreDataModel.sharedInstance().userProfile = nil
                } catch {
                    let nserror = error as NSError
                    NSLog("CoreData - Unresolved error \(nserror), \(nserror.userInfo)")
                    abort()
                }
           // })
        }
    }
    
}

// MARK: - CoreDataModel Entities
open class CoreDataModelEntity<String>: CoreDataModel {
    open let _entity: String
    
    public init(_ entity: String) {
        self._entity = entity
        super.init()
    }
}

// MARK: - CoreData Wrapper

extension CoreDataModel {
    
    open func getNewObject(entityName: CoreDataModelEntity<String>) -> NSManagedObject {
        return NSEntityDescription.insertNewObject(forEntityName: entityName._entity, into: managedObjectContext)
        
    }
    open func fetchRecords(entityName: CoreDataModelEntity<String>, predicate: String? = nil, sortDescriptors: [NSSortDescriptor]? = nil, completion: @escaping (_ records: Any?) -> Void) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName._entity)
        
        if let string = predicate {
            fetchRequest.predicate = NSPredicate(format: string)
        }
        
        fetchRequest.sortDescriptors = sortDescriptors
        
        do {
            let result = try managedObjectContext.fetch(fetchRequest)
            if result.count > 0 {
                completion(result)
            } else {
                completion(nil)
            }
        } catch let error as NSError {
            print("CoreData - Fetch failed: \(error.localizedDescription)")
        }
    }
    
    open func deleteRecord(_ object: NSManagedObject) {
        managedObjectContext.delete(object)
    }
    
    open func deleteAllRecords(entity: CoreDataModelEntity<String>) {
        if #available(iOS 9.0, *) {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: entity._entity)
            let batchReq = NSBatchDeleteRequest(fetchRequest: req)
            execute(batchReq)
        } else {
            fetchRecords(entityName: entity, completion: { (results) in
                if let records = results as? [NSManagedObject] {
                    for record in records {
                        self.deleteRecord(record)
                    }
                } else {
                    print("CoreData - No records found to delete")
                }
            })
            
        }
    }
    
    open func updateRecords(entity: CoreDataModelEntity<String>, properties: [AnyHashable: Any]) {
    
        let batchUpdateRequest = NSBatchUpdateRequest(entityName: entity._entity)
        batchUpdateRequest.propertiesToUpdate = properties
        batchUpdateRequest.resultType = .updatedObjectIDsResultType
        
        do {
            let batchUpdateResult = try managedObjectContext.execute(batchUpdateRequest) as? NSBatchUpdateResult
            
            if let result = batchUpdateResult {
                let objectIds = result.result as! [NSManagedObjectID]
                for objectId in objectIds {
                    let managedObject = managedObjectContext.object(with: objectId)
                    if !managedObject.isFault {
                        managedObjectContext.stalenessInterval = 0
                        managedObjectContext.refresh(managedObject, mergeChanges: true)
                    }
                }
            }
        } catch { print(error) }
    }
    
    open func execute(_ request: NSPersistentStoreRequest) {
        do {
            try managedObjectContext.execute(request)
        } catch {
            print(error)
        }
    }
    
}

extension CoreDataModel {
    static let ProfileEntity = CoreDataModelEntity<String>("Profile")
    static let SupportContactEntity = CoreDataModelEntity<String>("SupportContact")
    static let UserContactEntity = CoreDataModelEntity<String>("UserContact")
    static let CarrierEntity = CoreDataModelEntity<String>("Carrier")
    static let VoiceMailEntity = CoreDataModelEntity<String>("VoiceMail")
    static let MessageEntity = CoreDataModelEntity<String>("Message")
    static let MqttEntity = CoreDataModelEntity<String>("MQTT")
}
