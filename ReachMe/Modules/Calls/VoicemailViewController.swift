//
//  VoicemailViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 6/28/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class VoicemailViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var viewModel = VoicemailViewModel()
    var dataSource: RxTableViewSectionedAnimatedDataSource<AnimatableSectionModel<String, Message>>!
    private let disposeBag = DisposeBag()

    lazy var searchController: UISearchController = {
        $0.searchResultsUpdater = self
        $0.obscuresBackgroundDuringPresentation = false
        $0.delegate = self
        $0.searchBar.sizeToFit()
        definesPresentationContext = true
        return $0
    }(UISearchController(searchResultsController: nil))
    
    var isPresentingSearchBar: Bool = false
    var playingJukebox: Jukebox?
    //var observer: CoreDataContextObserver?

    override func viewDidLoad() {
        super.viewDidLoad()
        //        observer = CoreDataContextObserver(context: Constants.appDelegate.coreDataStack.defaultContext)
        //        observer?.observeObject(object: Constants.appDelegate.userProfile!, state: .Updated, completionBlock: { object, state in
        //            // print("CHANGED VALUES: \(object.changedValuesForCurrentEvent())")
        //            do {
        //                try self.fetchedResultsController.performFetch()
        //                self.handleBadgeCount()
        //            } catch { fatalError("Error in fetching records") }
        //        })

        configureView()
        bindViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playingJukebox?.pause()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.tableView.reloadData()
            }
        }
    }
    
    func configureView() {
        //Searchbar
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            extendedLayoutIncludesOpaqueBars = true
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        //TableView
        tableView.tableFooterView = UIView()
        dataSource = RxTableViewSectionedAnimatedDataSource<AnimatableSectionModel<String, Message>>(configureCell: { dateSource, tableView, indexPath, message in
            let cell = tableView.dequeueReusableCell(withIdentifier: VoicemailsGeneralCell.identifier, for: indexPath) as! VoicemailsGeneralCell
            
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
                cell.isRead = true
                self.viewModel.playAction.execute(message)
            })
            
            cell.layoutIfNeeded()
            return cell
        })
        
        dataSource.canEditRowAtIndexPath = { _, _  in
            return true
        }
    }
    
    func bindViewModel() {
        let observableMessagess = viewModel.getVoiceMails().asObservable()
        observableMessagess
            .map { messages in
                [AnimatableSectionModel(model: "Section 1", items: messages)]
            }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        //Badge Update
        observableMessagess.subscribe(onNext: { _ in
            self.viewModel.handleBadgeCount()
        }).disposed(by: disposeBag)
        
        //Badge Update
        viewModel.unreadMessageCount.bind { (count) in
            self.tabBarController?.tabBar.items?[1].badgeValue = count
        }.disposed(by: disposeBag)
        
        //Delete Action
        tableView.rx.itemDeleted
            .subscribe(onNext: { indexPath in
                let alert = UIAlertController(style: .alert, title: "Delete voicemail?", message: "This voicemail will be deleted from your account.")
                alert.addAction(title: "Cancel")
                alert.addAction(title: "Delete", handler: { _ in
                    guard RMUtility.isNetwork() else {
                        RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                        return
                    }
                                        
                    let cellToDelete = self.tableView.cellForRow(at: indexPath) as! VoicemailsGeneralCell
                    cellToDelete.deleteSpinner.startAnimating()
                    cellToDelete.jukebox.stop()
                    cellToDelete.alpha = 0.6
                    cellToDelete.isUserInteractionEnabled = false
                    
                    self.viewModel.deleteMessage(withIndex: indexPath.row, completionHandler: { (success) in
                        DispatchQueue.main.async { cellToDelete.deleteSpinner.stopAnimating() }
                        guard success else {
                            cellToDelete.alpha = 1
                            cellToDelete.isUserInteractionEnabled = true
                            return
                        }
                    })
                })
                alert.show()
                
            }).disposed(by: disposeBag)

        //Item Select
        tableView.rx.itemSelected
            .map { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
        }.subscribe().disposed(by: disposeBag)
        
        //Search Action
        searchController.searchBar.rx.text
            .throttle(0.3, scheduler: MainScheduler.instance)
            .map { return $0! }
            .subscribe(viewModel.searchAction.inputs)
            .disposed(by: disposeBag)
    }
}

// MARK: - Search Delegates
extension VoicemailViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        isPresentingSearchBar = true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard !isPresentingSearchBar else {
            isPresentingSearchBar = false
            return
        }
    }
}
