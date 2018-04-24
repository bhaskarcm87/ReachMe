//
//  ChatUserViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 4/10/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit


class ChatUserViewController: RCMessagesView/*, UIGestureRecognizerDelegate*/ {
    static let MESSAGE_STATUS = "status"
    static let MESSAGE_TEXT = "text"
    static let MESSAGE_EMOJI = "emoji"
    static let MESSAGE_PICTURE = "picture"
    static let MESSAGE_VIDEO = "video"
    static let MESSAGE_AUDIO = "audio"
    static let MESSAGE_LOCATION = "location"

    var dbmessages: [Message]!
    var insertCounter: Int!
    var rcmessages: [String:RCMessage]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        hidesBottomBarWhenPushed = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       // navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        self.tableView!.backgroundView = UIImageView.init(image: #imageLiteral(resourceName: "Chat_Background"))
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func actionSendMessage(_ text: String!) {
        
    }
    
    override func actionSendAudio(_ path: String!) {
        
    }
    
    //MARK: - - DBMessage methods
    func index(indexPath: IndexPath) -> Int {
        let count = min(insertCounter, dbmessages.count)
        let offset = dbmessages.count - count
        return indexPath.section + offset
    }
    
    func dbmessage(indexPath: IndexPath) -> Message {
        let index = self.index(indexPath: indexPath)
        return dbmessages[index]
    }
    
    func dbmessageAbove(indexPath: IndexPath) -> Message? {
        guard indexPath.section > 0 else { return nil }
        
        let indexAbove = IndexPath.init(row: 0, section: indexPath.section - 1)
        return dbmessage(indexPath: indexAbove)
    }
    
    //MARK: - Message methods
    override func rcmessage(_ indexPath: IndexPath!) -> RCMessage! {
        //let dbmessage = self.dbmessage(indexPath: indexPath)
        
       let rcMessage = RCMessage.init(text: "Sachin Hello", incoming: true)

        
//        guard let rcMessage = rcmessages[dbmessage.guide!] else {
//
//            var rcMessage: RCMessage!
//            let incoming: Bool = false //TODO: assign here Proper value
//
//            switch dbmessage.type {
//            case ChatUserViewController.MESSAGE_STATUS?:
//                rcMessage = RCMessage.init(status: dbmessage.content)
//            case ChatUserViewController.MESSAGE_TEXT?:
//                rcMessage = RCMessage.init(text: dbmessage.content, incoming: incoming)
//            case ChatUserViewController.MESSAGE_EMOJI?:
//                rcMessage = RCMessage.init(emoji: dbmessage.content, incoming: incoming)
//            case ChatUserViewController.MESSAGE_PICTURE?:
//                rcMessage = RCMessage.init(picture: UIImage(), width: 0, height: 0, incoming: incoming)
//            case ChatUserViewController.MESSAGE_AUDIO?:
//                rcMessage = RCMessage.init(audio: String(), durarion: 0, incoming: incoming)
//            default:
//                break
//            }
//
//            rcmessages[dbmessage.guide!] = rcMessage
//            return rcMessage
//        }
        
        return rcMessage
    }
    
    //MARK: - - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
//        return min(insertCounter, dbmessages.count)
    }
}
