//
//  NSManagedObjectContext+Extension.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 5/12/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import CoreData

/**
 This extension defines a extra function to the NSManagedObjectContext objects
 in order to save the context and its parents.
 */
extension NSManagedObjectContext {
    
    /**
     Asynchronously save the changes of the context to its parent(s).
     Use this method with the NSManagedObject contexts bound to the main thread.
     */
    public func saveToParents(withCompletion completion: ((Error?) -> Void)?) {
        // A completion block is defined to call the original completion block into the main thread.
        let completionInMainThread: (Error?) -> Void = { error in
            if let completion = completion {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
        
        // If the context has no changes no need to continue.
        guard hasChanges else {
            completionInMainThread(nil)
            return
        }
        
        do {
            try save()
            
            // If this context has no parent no need to continue.
            guard let parent = parent else {
                completionInMainThread(nil)
                return
            }
            
            // Now save to its parent context.
            parent.perform {
                parent.saveToParents(withCompletion: completion)
            }
        } catch let e {
            completionInMainThread(e)
        }
    }
    
    /**
     Synchronously save the changes of the context to its parent(s)
     */
    public func saveToParentsAndWait() -> Error? {
        // If the context has no changes no need to continue.
        guard hasChanges else {
            return nil
        }
        
        do {
            try save()
            
            // If this context has no parent no need to continue.
            guard let parent = parent else {
                return nil
            }
            
            // Now save to its parent context.
            var error: Error?
            parent.performAndWait {
                error = parent.saveToParentsAndWait()
            }
            
            return error
        } catch let e {
            return e
        }
    }
}
