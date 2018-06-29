//
//  CallsViewModel.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 6/27/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import RxSwift
import Action

struct CallsViewModel {
    
    private var missedCallMessages = Variable<[Message]>([])
    private var messagessDataProvider = MessagessDataProvider()
    private var disposeBag = DisposeBag()
    private let unreadMessageCountVariable = Variable<String?>("0")
    var unreadMessageCount: Observable<String?> {
        return unreadMessageCountVariable.asObservable()
    }

    init() {
        ServiceRequest.shared.startRequestForFetchMessages(completionHandler: nil)
        fetchMissedCalls()
    }
    
    public func getMissedCalls() -> Variable<[Message]> {
        return missedCallMessages
    }

    private func fetchMissedCalls() {
        messagessDataProvider.fetchMissedCalls()
            .map({ $0 })
            .subscribe(onNext: { (messages) in
                self.missedCallMessages.value = messages
        }).disposed(by: disposeBag)
    }
    
    private func fetchMissedCallsForSearchText(searchText: String) {
        messagessDataProvider.fetchMissedCallsForSearchText(searchText: searchText)
            .map({ $0 })
            .subscribe(onNext: { (messages) in
                self.missedCallMessages.value = messages
        }).disposed(by: disposeBag)
    }
    
    func handleBadgeCount() {
        var unreadMessageCount: String? = nil
        
        if let messageCount  = missedCallMessages.value.filter({$0.readCount == 0}).count as Int?,
            messageCount > 0 {
            unreadMessageCount = "\(messageCount)"
        }
        unreadMessageCountVariable.value = unreadMessageCount
    }
    
    public func deleteMessage(withIndex index: Int, completionHandler: @escaping ((Bool) -> Swift.Void)) {
        let messageToDelete = missedCallMessages.value[index]
         ServiceRequest.shared.startRequestForDeleteMessage(message: messageToDelete, completionHandler: { (success) in
            guard success else {
                completionHandler(false)
                return
            }
            self.messagessDataProvider.deleteMessage(withIndex: index)
            completionHandler(true)
         })
    }
    
    lazy var selectAction: Action<Message, Void> = { this in
        return Action { selectedMessage in
            guard selectedMessage.readCount == 0 else { return .empty() }

            ServiceRequest.shared.startRequestForReadMessages(messages: [selectedMessage]) { (success) in
                guard success else { return }
                
                this.messagessDataProvider.readMessage(withIndex: this.missedCallMessages.value.index(of: selectedMessage)!)
            }
            return .empty()
        }
    }(self)
    
    lazy var searchAction: Action<String, Void> = { this in
        return Action { searchText in
            if searchText.isEmpty {
                this.fetchMissedCalls()
            } else {
                this.fetchMissedCallsForSearchText(searchText: searchText)
            }
            return .empty()
        }
    }(self)
    
    lazy var unReadCallToReadStateAction: Action<Any?, Void> = { this in
        return Action { _ in
            if let unreadMessages = this.missedCallMessages.value.filter({$0.readCount == 0}) as [Message]?,
                unreadMessages.count > 0 {
                ServiceRequest.shared.startRequestForReadMessages(messages: unreadMessages) { (success) in
                    guard success else { return }
                    
                    let indexList = unreadMessages.map { this.missedCallMessages.value.index(of: $0)! }
                    this.messagessDataProvider.readMessages(withIndexes: indexList)
                }
            }
            return .empty()
        }
    }(self)
}
