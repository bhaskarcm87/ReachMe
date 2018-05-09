//
//  CallsViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/23/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import CoreData
import Alertift
import SwiftyUserDefaults

class CallsViewController: UITableViewController {
   
    lazy var fetchedResultsController: NSFetchedResultsController<Message> = {
        let frc: NSFetchedResultsController<Message>
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type == %@", "mc") // only missed calls
        let sort = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        //fetchRequest.returnsObjectsAsFaults
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataModel.sharedInstance().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        do { try frc.performFetch() } catch { fatalError("Error in fetching records") }
        
        return frc
    }()
    lazy var searchController: UISearchController = {
        $0.searchResultsUpdater = self
        $0.obscuresBackgroundDuringPresentation = false
        $0.delegate = self
        $0.searchBar.sizeToFit()
        definesPresentationContext = true
        return $0
    }(UISearchController(searchResultsController: nil))

    var userProfile: Profile? {
        get {
            return CoreDataModel.sharedInstance().getUserProfle()!
        }
    }
    var observer: CoreDataContextObserver?
    var isPresentingSearchBar: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        tabBarController?.customizableViewControllers = []
        tabBarController?.delegate = self
        tableView.tableFooterView = UIView()

        handleBadgeCount()
        ServiceRequest.shared().startRequestForFetchMessages(completionHandler: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Searchbar
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            extendedLayoutIncludesOpaqueBars = true
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        observer = CoreDataContextObserver(context: (userProfile?.managedObjectContext)!)
        observer?.observeObject(object: userProfile!, state: .Updated, completionBlock: { object, state in
            // print("CHANGED VALUES: \(object.changedValuesForCurrentEvent())")
            do {
                try self.fetchedResultsController.performFetch()
                self.handleBadgeCount()
            } catch { fatalError("Error in fetching records") }
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
        
    // MARK: - Custom Methods
    func handleBadgeCount() {
        var unreadMessageCount: String? = nil
        
        if let messageCount  = self.fetchedResultsController.fetchedObjects?.filter({$0.readCount == 0}).count,
            messageCount > 0 {
            unreadMessageCount = "\(messageCount)"
        }
        DispatchQueue.main.async {
            self.tabBarController?.tabBar.items?.first?.badgeValue = unreadMessageCount
        }
    }
    
    // MARK: - Segue Actions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedMessage = fetchedResultsController.object(at: tableView.indexPathForSelectedRow!)
        guard selectedMessage.readCount == 0 else { return }
        
        ServiceRequest.shared().startRequestForReadMessages(messages: [selectedMessage]) { (success) in
            guard success else { return }
            
            selectedMessage.readCount = 1
            CoreDataModel.sharedInstance().saveContext()
            self.handleBadgeCount()
        }
    }
}

// MARK: - TableView Delegate & Datasource
extension CallsViewController {
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
            
        Alertift.alert(title: "Delete missed call?",
                       message: "This missed call will be deleted from your account.")
            .action(.default("Cancel"))
            .action(.default("Delete")) { (action, count, nil) in
                
                guard RMUtility.isNetwork() else {
                    RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                    return
                }
                
                let cellToDelete = tableView.cellForRow(at: indexPath) as! CallsGeneralCell
                cellToDelete.spinner.startAnimating()
                cellToDelete.alpha = 0.6
                cellToDelete.isUserInteractionEnabled = false
                
                let messageToDelete = self.fetchedResultsController.object(at: indexPath)
                ServiceRequest.shared().startRequestForDeleteMessage(message: messageToDelete, completionHandler: { (success) in
                    cellToDelete.spinner.stopAnimating()
                    guard success else {
                        cellToDelete.alpha = 1
                        cellToDelete.isUserInteractionEnabled = true
                        return
                    }
                    CoreDataModel.sharedInstance().managedObjectContext.delete(messageToDelete)
                    CoreDataModel.sharedInstance().saveContext()
                    self.handleBadgeCount()
                })

            }.show()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CallsGeneralCell.identifier, for: indexPath) as! CallsGeneralCell
        
        let message = fetchedResultsController.object(at: indexPath)
        cell.confiureCellForMessage(message: message)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension CallsViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .left)
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .top)
        case .move:
            print("Move")
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

// MARK: - Search Delegates
extension CallsViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        isPresentingSearchBar = true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard !isPresentingSearchBar else {
            isPresentingSearchBar = false
            return
        }
        
        if searchController.searchBar.text!.isEmpty {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(type == %@)", "mc")
        } else {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(type == %@) && (senderName contains [cd] %@)", "mc", searchController.searchBar.text!.lowercased())
        }

        do {
            try self.fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch { fatalError("Error in fetching records") }
    }
}

// MARK: - Tabbar Delegate
extension CallsViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if !((viewController as! UINavigationController).topViewController?.isKind(of: CallsViewController.self))!,
            tabBarController.selectedIndex == 0 {
            
            if let unreadMessages  = self.fetchedResultsController.fetchedObjects?.filter({$0.readCount == 0}),
                unreadMessages.count > 0 {
                ServiceRequest.shared().startRequestForReadMessages(messages: unreadMessages) { (success) in
                    guard success else { return }
                    
                    //CoreDataModel.sharedInstance().updateRecords(entity: .MessageEntity, properties: ["readCount" : 1])

                    unreadMessages.forEach { $0.readCount = 1}
                    CoreDataModel.sharedInstance().saveContext()
                    self.handleBadgeCount()
                }
            }
        }
        
        return true
    }
}
