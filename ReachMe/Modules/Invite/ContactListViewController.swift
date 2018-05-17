//
//  ContactListViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 5/17/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import CoreData

class ContactListViewController: UITableViewController {
    
    private let coreDataStack = Constants.appDelegate.coreDataStack
    var contactListType: RMUtility.ContactListType!

    lazy var fetchedResultsController: NSFetchedResultsController<DeviceContact> = {
        let frc: NSFetchedResultsController<DeviceContact>
        let fetchRequest: NSFetchRequest<DeviceContact> = DeviceContact.fetchRequest()
        if contactListType == .email {
            fetchRequest.predicate = NSPredicate(format: "isEmailType == %@", NSNumber(value: true))
        }
        let sort = NSSortDescriptor(key: "firstName", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.defaultContext, sectionNameKeyPath: nil, cacheName: nil)
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

    var isPresentingSearchBar: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Searchbar
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            extendedLayoutIncludesOpaqueBars = true
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

// MARK: - TableView Delegate & Datasource
extension ContactListViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactListTableCell.identifier, for: indexPath) as! ContactListTableCell
        let contact = fetchedResultsController.object(at: indexPath)
        
        if let contactPicData = contact.contactPicData,
            let contactImage = UIImage(data: contactPicData) {
            cell.contactImageView.image = contactImage
        } else {
            cell.contactImageView.image = #imageLiteral(resourceName: "default_profile_img_user")
        }
        cell.nameLabel.text = contact.firstName! + " " + contact.lastName!
        if contactListType == .phone {
            cell.titleLabel.text = contact.phones?.first?.formatedNumber
            if let type = contact.phones?.first?.type, !type.isEmpty {
                cell.detailLabel.text = type
            } else {
                cell.detailLabel.text = "Phone"
            }
        } else {
            cell.titleLabel.text = contact.emails?.first
            cell.detailLabel.text = ""
        }
        
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
extension ContactListViewController: NSFetchedResultsControllerDelegate {
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
extension ContactListViewController: UISearchResultsUpdating, UISearchControllerDelegate {
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

class ContactListTableCell: UITableViewCell {
    
    static let identifier = String(describing: ContactListTableCell.self)
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var contactImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        updateCell()
    }
    
    func updateCell() {
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
