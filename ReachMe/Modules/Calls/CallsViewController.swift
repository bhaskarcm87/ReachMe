//
//  CallsViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/23/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import RxSwift
import RxCocoa
import RxDataSources

class CallsViewController: UIViewController {
   
    @IBOutlet weak var tableView: UITableView!
    var viewModel = CallsViewModel()
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

    override func awakeFromNib() {
        super.awakeFromNib()
        tabBarController?.customizableViewControllers = []
        tabBarController?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        bindViewModel()
        
    }
    
    @IBAction func testButtonAction(_ sender: Any) {
    }
    
    // MARK: - Custom Methods
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
            let cell = tableView.dequeueReusableCell(withIdentifier: CallsGeneralCell.identifier, for: indexPath) as! CallsGeneralCell
            cell.confiureCellForMessage(message: message)
            return cell
        })
        
        dataSource.canEditRowAtIndexPath = { _, _  in
            return true
        }
    }
    
    func bindViewModel() {
        
        let observableMessagess = viewModel.getMissedCalls().asObservable()
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
            self.tabBarController?.tabBar.items?.first?.badgeValue = count
        }.disposed(by: disposeBag)
        
        //Delete Action
        tableView.rx.itemDeleted
            .subscribe(onNext: { indexPath in
                
            let alert = UIAlertController(style: .alert, title: "Delete missed call?", message: "This missed call will be deleted from your account.")
            alert.addAction(title: "Cancel")
            alert.addAction(title: "Delete", handler: { _ in
                guard RMUtility.isNetwork() else {
                    RMUtility.showAlert(withMessage: "NET_NOT_AVAILABLE".localized)
                    return
                }
    
                let cellToDelete = self.tableView.cellForRow(at: indexPath) as! CallsGeneralCell
                cellToDelete.spinner.startAnimating()
                cellToDelete.alpha = 0.6
                cellToDelete.isUserInteractionEnabled = false
    
                self.viewModel.deleteMessage(withIndex: indexPath.row, completionHandler: { (success) in
                    DispatchQueue.main.async { cellToDelete.spinner.stopAnimating() }
                    guard success else {
                        cellToDelete.alpha = 1
                        cellToDelete.isUserInteractionEnabled = true
                        return
                    }
                })
            })
            alert.show()

        }).disposed(by: disposeBag)
        
        //Select Action
        tableView.rx.itemSelected
            .map { [unowned self] indexPath -> Message in
                return try self.tableView.rx.model(at: indexPath)
            }
            .subscribe(viewModel.selectAction.inputs)
        .disposed(by: disposeBag)
        
        //Search Action
        searchController.searchBar.rx.text
            .throttle(0.3, scheduler: MainScheduler.instance)
            .map { return $0! }
            .subscribe(viewModel.searchAction.inputs)
        .disposed(by: disposeBag)

    }
    
    // MARK: - Segue Actions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.tableView.deselectRow(at: tableView.indexPathForSelectedRow!, animated: true)
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
    }
}

// MARK: - Tabbar Delegate
extension CallsViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if !((viewController as! UINavigationController).topViewController?.isKind(of: CallsViewController.self))!,
            tabBarController.selectedIndex == 0 {
            
            viewModel.unReadCallToReadStateAction.execute(nil)
        }
        return true
    }
}
