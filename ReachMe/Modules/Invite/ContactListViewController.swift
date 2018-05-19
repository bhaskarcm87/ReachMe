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
    var isEmailType: Bool!

    lazy var phoneFetchedResults: NSFetchedResultsController<PhoneNumber> = {
        let frc: NSFetchedResultsController<PhoneNumber>
        let fetchRequest: NSFetchRequest<PhoneNumber> = PhoneNumber.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "parent.isIV == %@", NSNumber(value: false))
        let sort = NSSortDescriptor(key: "parent.contactName", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.defaultContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        do { try frc.performFetch() } catch { fatalError("Error in fetching records") }
        return frc
    }()
    
    lazy var emailFetchedResults: NSFetchedResultsController<EmailAddress> = {
        let frc: NSFetchedResultsController<EmailAddress>
        let fetchRequest: NSFetchRequest<EmailAddress> = EmailAddress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "parent.isIV == %@", NSNumber(value: false))
        let sort = NSSortDescriptor(key: "parent.contactName", ascending: true)
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
        if let sections = isEmailType ? emailFetchedResults.sections : phoneFetchedResults.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactListTableCell.identifier, for: indexPath) as! ContactListTableCell
        cell.contactImageView.isHidden = true
        cell.defaultAvatar.isHidden = true
        
        let deviceContact: DeviceContact!
        if isEmailType {
            let email = emailFetchedResults.object(at: indexPath)
            cell.titleLabel.text = email.emailID
            cell.detailLabel.text = email.labelType!.isEmpty ? "Phone" : email.labelType
            deviceContact = email.parent!
        } else {
            let phone = phoneFetchedResults.object(at: indexPath)
            cell.titleLabel.text = phone.displayFormatNumber
            cell.detailLabel.text = phone.labelType!.isEmpty ? "Phone" : phone.labelType
            deviceContact = phone.parent!
        }
        
        cell.nameLabel.text = deviceContact.contactName

        //ContactPIC
        if let icPicData = deviceContact.ivPicData,
            let ivImage = UIImage(data: icPicData) {
            cell.contactImageView.isHidden = false
            cell.contactImageView.image = ivImage
            
        } else if let contactPicData = deviceContact.contactPicData,
            let contactImage = UIImage(data: contactPicData) {
            cell.contactImageView.isHidden = false
            cell.contactImageView.image = contactImage
            
        } else {
            cell.defaultAvatar.isHidden = false
            cell.defaultAvatar.text = deviceContact.avatarText
            cell.defaultAvatar.backgroundColor = UIColor.decode(withData: deviceContact.avatarColor!)
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
        
        if isEmailType {
            if searchController.searchBar.text!.isEmpty {
                emailFetchedResults.fetchRequest.predicate = NSPredicate(format: "parent.isIV == %@", NSNumber(value: false))
            } else {
                emailFetchedResults.fetchRequest.predicate = NSPredicate(format: "parent.contactName contains [cd] %@", searchController.searchBar.text!.lowercased())
            }
            
            do {
                try emailFetchedResults.performFetch()
                tableView.reloadData()
            } catch { fatalError("Error in fetching records") }
        } else {
            if searchController.searchBar.text!.isEmpty {
                phoneFetchedResults.fetchRequest.predicate = NSPredicate(format: "parent.isIV == %@", NSNumber(value: false))
            } else {
                phoneFetchedResults.fetchRequest.predicate = NSPredicate(format: "parent.contactName contains [cd] %@", searchController.searchBar.text!.lowercased())
            }
            
            do {
                try phoneFetchedResults.performFetch()
                tableView.reloadData()
            } catch { fatalError("Error in fetching records") }

        }
    }
}

class ContactListTableCell: UITableViewCell {
    
    static let identifier = String(describing: ContactListTableCell.self)
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var defaultAvatar: UILabel!
    var defaultAvatarColor: UIColor?
    
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
