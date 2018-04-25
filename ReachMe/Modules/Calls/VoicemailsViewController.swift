//
//  VoicemailsViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/27/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import CoreData
import Alertift
import RxSwift
import RxCocoa

class VoicemailsViewController: UITableViewController {

    lazy var fetchedResultsController: NSFetchedResultsController<Message> = {
        let frc: NSFetchedResultsController<Message>
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type == %@", "vsms")
        let sort = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sort]
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
    var playingJukebox: Jukebox?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        handleBadgeCount()
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
            do {
                try self.fetchedResultsController.performFetch()
                self.handleBadgeCount()
            } catch { fatalError("Error in fetching records") }
        })

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playingJukebox?.pause()
    }

    // MARK: - Custom Methods
    func handleBadgeCount() {
        var unreadMessageCount: String? = nil
        
        if let messageCount  = self.fetchedResultsController.fetchedObjects?.filter({$0.readCount == 0}).count,
            messageCount > 0 {
            unreadMessageCount = "\(messageCount)"
        }
        DispatchQueue.main.async {
            self.tabBarController?.tabBar.items?[1].badgeValue = unreadMessageCount
        }
    }
}

// MARK: - TableView Delegate & Datasource
extension VoicemailsViewController {
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        Alertift.alert(title: "Delete voicemail?",
                       message: "This voicemail will be deleted from your account.")
            .action(.default("Cancel"))
            .action(.default("Delete")) { (action, count, nil) in
                
                guard RMUtility.isNetwork() else {
                    RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                    return
                }
                
                let cellToDelete = tableView.cellForRow(at: indexPath) as! VoicemailsGeneralCell
                cellToDelete.deleteSpinner.startAnimating()
                cellToDelete.jukebox.stop()
                cellToDelete.alpha = 0.6
                cellToDelete.isUserInteractionEnabled = false
                
                let messageToDelete = self.fetchedResultsController.object(at: indexPath)
                ServiceRequest.shared().startRequestForDeleteMessage(message: messageToDelete, completionHandler: { (success) in
                    cellToDelete.deleteSpinner.stopAnimating()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: VoicemailsGeneralCell.identifier, for: indexPath) as! VoicemailsGeneralCell
        
        let message = fetchedResultsController.object(at: indexPath)
        cell.message = message
        
        let playButtonTap = cell.playButton.rx.tap.asDriver()
        _ =  playButtonTap.drive(onNext: {
            //Handle Playing state in other cells
            if cell.jukebox.state == .playing || cell.jukebox.state == .loading {
                if let jukebox = self.playingJukebox {
                    jukebox.pause()
                }
                self.playingJukebox = cell.jukebox
            }
            
            //Handle Readstate
            guard message.readCount == 0 else { return }
            ServiceRequest.shared().startRequestForReadMessages(messages: [message]) { (success) in
                guard success else { return }
                
                //Detaching delegate notification of fetch results during read state update in DB, otherwise cells are freshly reloading, so playing state in UI not updating properly
                self.fetchedResultsController.delegate = nil
                message.readCount = 1
                CoreDataModel.sharedInstance().saveContext()
                self.handleBadgeCount()
                cell.isRead = true
                self.fetchedResultsController.delegate = self
            }
        })
        
        cell.layoutIfNeeded()
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
extension VoicemailsViewController: NSFetchedResultsControllerDelegate {
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
extension VoicemailsViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        isPresentingSearchBar = true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard !isPresentingSearchBar else {
            isPresentingSearchBar = false
            return
        }
        
        if searchController.searchBar.text!.isEmpty {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(type == %@)", "vsms")
        } else {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(type == %@) && (senderName contains [cd] %@)", "vsms", searchController.searchBar.text!.lowercased())
        }
        
        do {
            try self.fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch { fatalError("Error in fetching records") }
    }
}
