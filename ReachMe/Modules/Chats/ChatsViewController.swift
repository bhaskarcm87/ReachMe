//
//  ChatsViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 4/10/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import SwipeCellKit

class ChatsViewController: UITableViewController {

    lazy var searchController: UISearchController = {
        $0.searchResultsUpdater = self
        $0.obscuresBackgroundDuringPresentation = false
        $0.delegate = self
        $0.searchBar.sizeToFit()
        definesPresentationContext = true
        return $0
    }(UISearchController(searchResultsController: nil))
    var isPresentingSearchBar: Bool = false
    
    
    var mockChatUsers: [ChatUser] = [
        ChatUser(name: "Wordpress", lastChat: "New WordPress Site"),
        ChatUser(name: "IFTTT", lastChat: "See what’s new"),
        ChatUser(name: "Westin Vacations", lastChat: "Your Westin exclusive"),
        ChatUser(name: "Nugget Markets", lastChat: "Nugget Markets Weekly"),
        ChatUser(name: "GeekDesk", lastChat: "We have some exciting")]
    var defaultOptions = SwipeTableOptions()

    

    override func viewDidLoad() {
        super.viewDidLoad()
        //Searchbar
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            extendedLayoutIncludesOpaqueBars = true
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
     
        view.layoutMargins.left = 32
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

//MARK: - TableView Delegate & Datasource
extension ChatsViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mockChatUsers.count
    }
    
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatsGeneralCell.identifier, for: indexPath) as! ChatsGeneralCell
        cell.delegate = self
     
        let chatUser = mockChatUsers[indexPath.row]
        cell.userNameLabel.text = chatUser.name
        cell.chatMessageLabel.text = chatUser.lastChat
     
        return cell
     }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ChatsGeneralCell
        cell.setUnread(false, animated: true)
        let chatUser = mockChatUsers[indexPath.row]
        chatUser.unread = false

    }
}

//MARK: - Swipecell Delegate
extension ChatsViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        let chatUser = mockChatUsers[indexPath.row]
        
        if orientation == .left {
            
            let read = SwipeAction(style: .default, title: nil) { action, indexPath in
                let updatedStatus = !chatUser.unread
                chatUser.unread = updatedStatus
                
                let cell = tableView.cellForRow(at: indexPath) as! ChatsGeneralCell
                cell.setUnread(updatedStatus, animated: true)
            }
            
            read.hidesWhenSelected = true
            read.accessibilityLabel = chatUser.unread ? "Mark as Read" : "Mark as Unread"
            
            let descriptor: ActionDescriptor = chatUser.unread ? .read : .unread
            read.title = descriptor.title
            read.backgroundColor = descriptor.color
            
            return [read]
            
        } else {
            
            let close = SwipeAction(style: .destructive, title: nil) { action, indexPath in
                self.mockChatUsers.remove(at: indexPath.row)
            }
            close.title = ActionDescriptor.close.title
            close.backgroundColor = ActionDescriptor.close.color

            
            let block = SwipeAction(style: .default, title: nil) { action, indexPath in
            }
            block.hidesWhenSelected = true
            block.title = ActionDescriptor.block.title
            block.backgroundColor = ActionDescriptor.block.color

            
            return [close, block]
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        var options = SwipeTableOptions()
        options.expansionStyle = orientation == .left ? .selection : .destructive
        options.transitionStyle = defaultOptions.transitionStyle
        options.buttonSpacing = 11
        return options
    }
    
}

//MARK: - Search Delegates
extension ChatsViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        isPresentingSearchBar = true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard !isPresentingSearchBar else {
            isPresentingSearchBar = false
            return
        }
        
//        if searchController.searchBar.text!.isEmpty {
//            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(type == %@)", "mc")
//        } else {
//            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(type == %@) && (senderName contains [cd] %@)", "mc", searchController.searchBar.text!.lowercased())
//        }
//        
//        do {
//            try self.fetchedResultsController.performFetch()
//            tableView.reloadData()
//        } catch { fatalError("Error in fetching records") }
    }
}


class ChatUser {
    let name: String
    let lastChat: String
    var unread = false
    
    init(name: String, lastChat: String) {
        self.name = name
        self.lastChat = lastChat
    }

}
