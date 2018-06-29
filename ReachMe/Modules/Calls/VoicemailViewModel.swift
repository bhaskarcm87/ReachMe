//
//  VoicemailViewModel.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 6/28/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import RxSwift
import Action

struct VoicemailViewModel {
    
    private var voicemailMessages = Variable<[Message]>([])
    private var messagessDataProvider = MessagessDataProvider()
    private var disposeBag = DisposeBag()
    private let unreadMessageCountVariable = Variable<String?>("0")
    var unreadMessageCount: Observable<String?> {
        return unreadMessageCountVariable.asObservable()
    }
    
    init() {
        fetchVoiceMails()
    }
    
    public func getVoiceMails() -> Variable<[Message]> {
        return voicemailMessages
    }
    
    private func fetchVoiceMails() {
        messagessDataProvider.fetchVoiceMails()
            .map({ $0 })
            .subscribe(onNext: { (messages) in
                self.voicemailMessages.value = messages
            }).disposed(by: disposeBag)
    }
    
    private func fetchVoiceMailsForSearchText(searchText: String) {
        messagessDataProvider.fetchVoiceMailsForSearchText(searchText: searchText)
            .map({ $0 })
            .subscribe(onNext: { (messages) in
                self.voicemailMessages.value = messages
            }).disposed(by: disposeBag)
    }
    
    func handleBadgeCount() {
        var unreadMessageCount: String? = nil
        
        if let messageCount  = voicemailMessages.value.filter({$0.readCount == 0}).count as Int?,
            messageCount > 0 {
            unreadMessageCount = "\(messageCount)"
        }
        unreadMessageCountVariable.value = unreadMessageCount
    }
    
    public func deleteMessage(withIndex index: Int, completionHandler: @escaping ((Bool) -> Swift.Void)) {
        let messageToDelete = voicemailMessages.value[index]
        ServiceRequest.shared.startRequestForDeleteMessage(message: messageToDelete, completionHandler: { (success) in
            guard success else {
                completionHandler(false)
                return
            }
            self.messagessDataProvider.deleteMessage(withIndex: index)
            completionHandler(true)
        })
    }
    
    lazy var playAction: Action<Message, Void> = { this in
        return Action { selectedMessage in
            guard selectedMessage.readCount == 0 else { return .empty() }
            
            ServiceRequest.shared.startRequestForReadMessages(messages: [selectedMessage]) { (success) in
                guard success else { return }
                
                this.messagessDataProvider.readMessage(withIndex: this.voicemailMessages.value.index(of: selectedMessage)!)
            }
            return .empty()
        }
    }(self)
    
    lazy var searchAction: Action<String, Void> = { this in
        return Action { searchText in
            if searchText.isEmpty {
                this.fetchVoiceMails()
            } else {
                this.fetchVoiceMailsForSearchText(searchText: searchText)
            }
            return .empty()
        }
    }(self)
}
