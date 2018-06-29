//
// MessagessDataProvider.swift
//
//  Created by Sachin Kumar Patra on 6/27/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import RxSwift
import CoreData

class MessagessDataProvider: NSObject {
    
    private var messagesFromCoreData = Variable<[Message]>([])
    private let coreDataStack = Constants.appDelegate.coreDataStack

    private lazy var fetchedResultsController: NSFetchedResultsController<Message> = {
        let frc: NSFetchedResultsController<Message>
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.defaultContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        
        return frc
    }()
    
    override init() {
        super.init()
    }
    
    // MARK: - Common Methods
    private func fetchMessages() -> [Message] {
        do {
            try fetchedResultsController.performFetch()
            return fetchedResultsController.fetchedObjects!
        } catch {
            return []
        }
    }
    
    public func deleteMessage(withIndex index: Int) {
        coreDataStack.defaultContext.delete(messagesFromCoreData.value[index])
    }
    
    public func readMessage(withIndex index: Int) {
        messagesFromCoreData.value[index].readCount = 1
    }
    
    public func readMessages(withIndexes indexList: [Int]) {
        indexList.forEach { messagesFromCoreData.value[$0].readCount = 1 }
    }

    // MARK: - MissedCall Methods
    private func missedCalls() -> [Message] {
        fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "type == %@", "mc")
        return fetchMessages()
    }
    
    public func fetchMissedCalls() -> Observable<[Message]> {
        messagesFromCoreData.value = missedCalls()
        return messagesFromCoreData.asObservable()
    }
    
    private func missedCallsForSearchText(searchText: String) -> [Message] {
        fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(type == %@) && (senderName contains [cd] %@)", "mc", searchText.lowercased())
        return fetchMessages()
    }
    
    public func fetchMissedCallsForSearchText(searchText: String) -> Observable<[Message]> {
        messagesFromCoreData.value = missedCallsForSearchText(searchText: searchText)
        return messagesFromCoreData.asObservable()
    }
    
    // MARK: - Voicemail Methods
    private func voiceMails() -> [Message] {
        fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "type == %@", "vsms")
        return fetchMessages()
    }
    
    public func fetchVoiceMails() -> Observable<[Message]> {
        messagesFromCoreData.value = voiceMails()
        return messagesFromCoreData.asObservable()
    }
    
    private func voiceMailsForSearchText(searchText: String) -> [Message] {
        fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(type == %@) && (senderName contains [cd] %@)", "vsms", searchText.lowercased())
        return fetchMessages()
    }
    
    public func fetchVoiceMailsForSearchText(searchText: String) -> Observable<[Message]> {
        messagesFromCoreData.value = voiceMailsForSearchText(searchText: searchText)
        return messagesFromCoreData.asObservable()
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension MessagessDataProvider: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        messagesFromCoreData.value = fetchedResultsController.fetchedObjects!
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        coreDataStack.saveContexts()
    }
}
