//
//  SelectCarrierViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/28/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import RSSelectionMenu
import CoreData
import SwiftyUserDefaults

class SelectCarrierViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    lazy var searchController: UISearchController = {
        $0.searchResultsUpdater = self
        $0.obscuresBackgroundDuringPresentation = false
        $0.delegate = self
        $0.searchBar.sizeToFit()
        definesPresentationContext = true
        return $0
    }(UISearchController(searchResultsController: nil))
    
    @IBOutlet weak var tableView: UITableView!
    var selectionList = [String]()
    var filteredSearchData = [String]()
    var isPresentingSearchBar: Bool = false
    var userContact: UserContact!
    private let coreDataStack = Constants.appDelegate.coreDataStack
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Defaults[.IsCarrierSelection] {
            navigationItem.setHidesBackButton(true, animated: false)
        }
        
        //Searchbar
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            extendedLayoutIncludesOpaqueBars = true
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }

        tableView.register(SelectCarrierTableCell.self, forCellReuseIdentifier: SelectCarrierTableCell.identifier)
                
        ANLoader.showLoading("", disableUI: true)
        ServiceRequest.shared().startRequestForListOfCarriers(forUserContact: userContact, completionHandler: { (success) in
            guard success else { return }
            ANLoader.hide()
            //Prepare List data
            if self.userContact == nil {
                self.userContact = Constants.appDelegate.userProfile?.primaryContact!
                //If for secondary number carriers are not there, check if primary contact country code is same as secondary number then copy those to secondary number ans save context
            } else if self.userContact.carriers?.count == 0,
                Constants.appDelegate.userProfile?.primaryContact?.countryCode == self.userContact.countryCode {
                self.userContact.carriers = Constants.appDelegate.userProfile?.primaryContact?.carriers
                self.coreDataStack.saveContexts()
            }
            
            var resultSet = Set<String>()
            (self.userContact.carriers?.allObjects as? [Carrier])?
                .filter({!($0.carrierName!.isEmpty)})
                .forEach({
                    resultSet.insert($0.carrierName!)
                })
            self.selectionList.append(contentsOf: resultSet)
            self.filteredSearchData.append(contentsOf: resultSet)
            self.tableView.reloadData()
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - TableView data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredSearchData.count : selectionList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectCarrierTableCell.identifier, for: indexPath)
        cell.textLabel?.text = searchController.isActive ? filteredSearchData[indexPath.row] : selectionList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedText = searchController.isActive ? filteredSearchData[indexPath.row] : selectionList[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)!
        if searchController.isActive {
            searchController.searchBar.endEditing(true)
        }
        
        var resultSet = Set<String>()
        (userContact.carriers?.allObjects as? [Carrier])?
            .filter({($0.networkName!.lowercased().contains(selectedText.lowercased()))})
            .forEach({
                resultSet.insert($0.networkName!)
            })
        
        let selectionMenu =  RSSelectionMenu(dataSource: Array(resultSet)) { (cell, object, indexPath) in
            cell.textLabel?.text = object
        }
        selectionMenu.setSelectedItems(items: []) { (text, isSelected, selectedItems) in
            
            if !Defaults[.IsCarrierSelection] {
                guard self.userContact.selectedCarrier?.networkName != text! else {
                    RMUtility.showAlert(withMessage: "You are on same carrier")
                    return
                }
            }
            
            guard RMUtility.isNetwork() else {
                RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                return
            }
            
            let predicate = NSPredicate(format: "networkName contains[c] %@", text!)
            let selctedCarrier = self.userContact.carriers?.filtered(using: predicate).first as! Carrier
            self.userContact.selectedCarrier = selctedCarrier
            self.userContact.isReachMeHomeActive = false
            self.userContact.isReachMeIntlActive = false
            self.userContact.isReachMeVoiceMailActive = false
            
            self.updateServerforChangedSettings()
        }
        selectionMenu.showSearchBar(withPlaceHolder: "Select Network", tintColor: UIColor.white.withAlphaComponent(0.3)) { (searchText) -> ([String]) in
            return Array(resultSet).filter({ $0.lowercased().contains(searchText.lowercased()) })
        }
        selectionMenu.show(style: .Popover(sourceView: cell, size: CGSize(width: 300, height: 400)), from: self)
    }
    
    // MARK: - Actions
    @IBAction func onCarrierNotListedClicked(_ sender: UIButton) {
        
        userContact.selectedCarrier?.countryCode = "-1"
        userContact.selectedCarrier?.networkID = "-1"
        userContact.selectedCarrier?.vsmsNodeID = -1
        userContact.selectedCarrier?.networkName = "Unknown Carrier"
        
        userContact.isReachMeHomeActive = false
        userContact.isReachMeIntlActive = false
        userContact.isReachMeVoiceMailActive = false
        
        updateServerforChangedSettings()
    }
    
    // MARK: - Custom Methods
    func updateServerforChangedSettings() {
        
        ANLoader.showLoading("", disableUI: true)
        ServiceRequest.shared().startRequestForUpdateSettings(completionHandler: { (success) in
            guard success else {//If error occurs undo the local changes for this context
                Constants.appDelegate.userProfile?.managedObjectContext?.rollback()
                return
            }
            
            self.coreDataStack.saveContexts(withCompletion: { (error) in
                ANLoader.hide()
                if Defaults[.IsCarrierSelection] {
                    Defaults[.IsCarrierSelection] = false
                    Defaults[.IsOnBoarding] = true
                    self.performSegue(withIdentifier: Constants.Segues.ACTIVATE_REACHME, sender: self)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            })
        })
    }
}

extension SelectCarrierViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        isPresentingSearchBar = true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard !isPresentingSearchBar else {
            isPresentingSearchBar = false
            return
        }
        
        filteredSearchData.removeAll(keepingCapacity: false)
        
        guard !searchController.searchBar.text!.isEmpty else {
            filteredSearchData.append(contentsOf: selectionList)
            tableView.reloadData()
            return
        }
        
        let resultArray = selectionList.filter({ $0.lowercased().contains(searchController.searchBar.text!.lowercased()) })
        filteredSearchData.append(contentsOf: resultArray)
        tableView.reloadData()
    }
}

// MARK: - Table Cell
final class SelectCarrierTableCell: UITableViewCell {
    
    static let identifier = String(describing: SelectCarrierTableCell.self)
    
    // MARK: Initialize
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = nil
        contentView.backgroundColor = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: Configure Selection
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .checkmark : .none
    }
}
