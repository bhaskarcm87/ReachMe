//
//  ProfileViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 4/26/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import MTCoordinatorView
import Former
import RSSelectionMenu
import SwiftyJSON

class ProfileViewController: FormViewController {

    // MARK: - Properties
    fileprivate var coordinateManager: MTCoordinateManager?
    var editPicView: MTCoordinateContainer!
    private let coreDataStack = Constants.appDelegate.coreDataStack

    lazy var createHeader: ((String) -> ViewFormer) = { text in
        return LabelViewFormer<FormLabelHeaderView>()
            .configure {
                $0.text = text
                $0.viewHeight = 40
        }
    }
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    lazy var nameRow = TextFieldRowFormer<FormTextFieldCell>() {
        $0.titleLabel.text = "Name"
        $0.titleLabel.font = .preferredFont(forTextStyle: .body)
        $0.titleLabel.adjustsFontForContentSizeCategory = true
        $0.textField.font = .preferredFont(forTextStyle: .body)
        $0.textField.adjustsFontForContentSizeCategory = true
        $0.textField.returnKeyType = .next
        $0.textField.textAlignment = .right
        $0.textField.clearButtonMode = .never
        $0.textField.inputAccessoryView = self.formerInputAccessoryView
        }.configure {
            if let username = Constants.appDelegate.userProfile?.userName, !username.isEmpty {
                $0.text = username
            } else {
                $0.placeholder = "Enter name"
            }
        }.onTextChanged {
            Constants.appDelegate.userProfile?.userName = $0
    }

    lazy var emailRow = TextFieldRowFormer<FormTextFieldCell>() {
        $0.titleLabel.text = "Email"
        $0.titleLabel.font = .preferredFont(forTextStyle: .body)
        $0.titleLabel.adjustsFontForContentSizeCategory = true
        $0.textField.font = .preferredFont(forTextStyle: .body)
        $0.textField.adjustsFontForContentSizeCategory = true
        $0.textField.returnKeyType = .next
        $0.textField.textAlignment = .right
        $0.textField.clearButtonMode = .never
        $0.textField.inputAccessoryView = self.formerInputAccessoryView
        }.configure {
            if let email = Constants.appDelegate.userProfile?.emailID, !email.isEmpty {
                $0.text = email
            } else {
                $0.placeholder = "Enter email"
            }
        }.onTextChanged {
            Constants.appDelegate.userProfile?.emailID = $0
    }
    
    lazy var genderRow = InlinePickerRowFormer<FormInlinePickerCell, UITableViewRowAnimation>(instantiateType: .Class) {
        $0.titleLabel.text = "Gender"
        $0.titleLabel.font = .preferredFont(forTextStyle: .body)
        $0.titleLabel.adjustsFontForContentSizeCategory = true
        $0.displayLabel.font = .preferredFont(forTextStyle: .body)
        $0.displayLabel.adjustsFontForContentSizeCategory = true
        $0.displayLabel.textColor = .black
        }.configure {
            let genders = ["N/A", "Male", "Female", "Other"]
            $0.pickerItems = genders.map { InlinePickerItem(title: $0) }
            if let gender = Constants.appDelegate.userProfile?.gender {
                if gender == "m" {
                    $0.selectedRow = 1
                } else if gender == "f" {
                    $0.selectedRow = 2
                } else if gender == "o" {
                    $0.selectedRow = 3
                }
            }
        }.onValueChanged {
            if $0.title == "Male" {
                Constants.appDelegate.userProfile?.gender = "m"
            } else if $0.title == "Female" {
                Constants.appDelegate.userProfile?.gender = "f"
            } else if $0.title == "Other" {
                Constants.appDelegate.userProfile?.gender = "o"
            } else {
                Constants.appDelegate.userProfile?.gender = nil
            }
    }
    
    lazy var birthdayRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
        $0.titleLabel.text = "Birthday"
        $0.titleLabel.font = .preferredFont(forTextStyle: .body)
        $0.titleLabel.adjustsFontForContentSizeCategory = true
        $0.displayLabel.font = .preferredFont(forTextStyle: .body)
        $0.displayLabel.adjustsFontForContentSizeCategory = true
        $0.displayLabel.textColor = .black
        }.inlineCellSetup {
            $0.datePicker.datePickerMode = .date
        }.configure {
            if let birthday = Constants.appDelegate.userProfile?.birthday {
                $0.date = birthday
            }
        }.onDateChanged {
            Constants.appDelegate.userProfile?.birthday = $0
        }.displayTextFromDate(String.profileDateStyle)
    
    lazy var noBirthDayRow = LabelRowFormer<FormLabelCell>()
        .configure {
            $0.text = "Birthday"
            $0.subText = "N/A"
            $0.cell.formTextLabel()?.font = .preferredFont(forTextStyle: .body)
            $0.cell.formTextLabel()?.adjustsFontForContentSizeCategory = true
            $0.cell.formSubTextLabel()?.font = .preferredFont(forTextStyle: .body)
            $0.cell.formSubTextLabel()?.adjustsFontForContentSizeCategory = true
            $0.cell.formSubTextLabel()?.textColor = .black
            
        }.onSelected { [weak self] _ in
            self?.former.deselect(animated: true)
            if self?.former.numberOfRows == 7 {
                self?.former.insertUpdate(rowFormers: [(self?.datePickerRow)!], above: (self?.countryRow)!, rowAnimation: .top)
            } else {
                self?.former.removeUpdate(rowFormers: [(self?.datePickerRow)!], rowAnimation: .bottom)
            }
    }
    
    lazy var datePickerRow = DatePickerRowFormer<FormDatePickerCell>() {
        $0.datePicker.datePickerMode = .date
        }.onDateChanged {
            self.noBirthDayRow.subText = String.profileDateStyle(date: $0)
            self.noBirthDayRow.update()
            Constants.appDelegate.userProfile?.birthday = $0
    }
    
    lazy var countryRow = LabelRowFormer<FormLabelCell>()
        .configure {
            $0.text = "Country"
            $0.cell.formTextLabel()?.font = .preferredFont(forTextStyle: .body)
            $0.cell.formTextLabel()?.adjustsFontForContentSizeCategory = true
            $0.cell.formSubTextLabel()?.font = .preferredFont(forTextStyle: .body)
            $0.cell.formSubTextLabel()?.adjustsFontForContentSizeCategory = true
            $0.cell.formSubTextLabel()?.textColor = .black
            if let country = Constants.appDelegate.userProfile?.countryName {
                $0.subText = country
            } else {
                $0.subText = "Select Country"
            }
        }.onSelected { [weak self] _ in
            self?.former.deselect(animated: true)
            let alert = UIAlertController(style: .alert)
            alert.addLocalePicker(type: .country) {
                if let rowFormer = self?.former.rowFormer(indexPath: IndexPath(row: 4, section: 0)) as? LabelRowFormer<FormLabelCell> {
                    rowFormer.subText = $0?.country
                    rowFormer.update()
                }
                Constants.appDelegate.userProfile?.countryName = $0?.country
                Constants.appDelegate.userProfile?.countryCode = $0?.code

                if let stateSearchCode = $0?.stateSearchCode {
                    Constants.appDelegate.userProfile?.countryPhoneCode = stateSearchCode
                } else {
                    Constants.appDelegate.userProfile?.countryPhoneCode = $0?.phoneCode
                }
            }
            alert.addAction(title: "Cancel", style: .cancel)
            alert.show()
    }
    
    lazy var stateRow = LabelRowFormer<FormLabelCell>()
        .configure {
            $0.text = "State"
            $0.cell.formTextLabel()?.font = .preferredFont(forTextStyle: .body)
            $0.cell.formTextLabel()?.adjustsFontForContentSizeCategory = true
            $0.cell.formSubTextLabel()?.font = .preferredFont(forTextStyle: .body)
            $0.cell.formSubTextLabel()?.adjustsFontForContentSizeCategory = true
            if let state  = Constants.appDelegate.userProfile?.state, !state.isEmpty {
                $0.subText = state
            } else {
                $0.subText = "Select State"
            }
            $0.cell.formSubTextLabel()?.textColor = .black
            
        }.onSelected { [weak self] _ in
            self?.former.deselect(animated: true)
            ANLoader.showLoading("", disableUI: true)
            ServiceRequest.shared.startRequestForStatesList(forCountryCode: (Constants.appDelegate.userProfile?.countryPhoneCode)!, completionHandler: { (responseDisc, success) in
                ANLoader.hide()
                guard success else { return }
                if let states = responseDisc?["state_list"] as? [[String: Any]], states.count > 0 {
                    let stateNames = states.map {$0["stateName"] as! String}
                    
                    OperationQueue.main.addOperation({
                        let selectionMenu =  RSSelectionMenu(dataSource: stateNames) { (cell, object, indexPath) in
                            cell.textLabel?.text = object
                        }
                        if let rowFormer = self?.former.rowFormer(indexPath: IndexPath(row: 5, section: 0)) as? LabelRowFormer<FormLabelCell> {
                            
                            selectionMenu.setSelectedItems(items: []) { (text, isSelected, selectedItems) in
                                rowFormer.subText = text
                                rowFormer.update()
                                Constants.appDelegate.userProfile?.state = text
                            }
                            selectionMenu.showSearchBar(withPlaceHolder: "Select State", tintColor: UIColor.white.withAlphaComponent(0.3)) { (searchText) -> ([String]) in
                                return stateNames.filter({ $0.lowercased().contains(searchText.lowercased()) })
                            }
                            selectionMenu.show(style: .Popover(sourceView: rowFormer.cell, size: CGSize(width: 300, height: 400)), from: self!)
                        }
                    })
                }
            })
    }
    
    lazy var cityRow = TextFieldRowFormer<FormTextFieldCell>() {
        $0.titleLabel.text = "City"
        $0.titleLabel.font = .preferredFont(forTextStyle: .body)
        $0.titleLabel.adjustsFontForContentSizeCategory = true
        $0.textField.font = .preferredFont(forTextStyle: .body)
        $0.textField.adjustsFontForContentSizeCategory = true
        $0.textField.textAlignment = .right
        $0.textField.clearButtonMode = .never
        }.configure {
            if let city = Constants.appDelegate.userProfile?.city, !city.isEmpty {
                $0.text = city
            } else {
                $0.placeholder = "Enter City"
            }
        }.onTextChanged {
            Constants.appDelegate.userProfile?.city = $0
    }

    lazy var section = SectionFormer(rowFormer: nameRow,
                                     emailRow,
                                     genderRow,
                                     (Constants.appDelegate.userProfile?.birthday != nil) ? birthdayRow : noBirthDayRow,
                                     countryRow,
                                     stateRow,
                                     cityRow)
        .set(headerViewFormer: createHeader(""))

    lazy var headerImageView: UIImageView = {
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.isUserInteractionEnabled = true
        return $0
    }(UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 250)))
    
    var changedPicData: Data?
    
    // MARK: - Viewlifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem

        UIApplication.shared.statusBarView?.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        
        if let profilePicData = Constants.appDelegate.userProfile?.profilePicData,
            let profileImage = UIImage(data: profilePicData) {
            headerImageView.image = profileImage
            coordinateManager = MTCoordinateManager(vc: self, scrollView: self.tableView, header: headerImageView)
            editPicView = createEditPicView()
            coordinateManager?.setContainer(self.tableView, views: editPicView)
        }
        
        former.append(sectionFormer: section).onScroll {
            guard let manager = self.coordinateManager else {
                return
            }
            manager.scrolledDetection($0)
        }
        self.former[0...0].flatMap { $0.rowFormers }.forEach {
            $0.enabled = false
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParentViewController {
            Constants.appDelegate.userProfile?.managedObjectContext?.rollback()
        }
    }
    
    func createEditPicView() -> MTCoordinateContainer {
        let iconView = UIImageView.init(image: #imageLiteral(resourceName: "edit_pic_camera"))
        let centerX = view.frame.width / 2
        let iconSize = 40.f
        let startX = centerX - (iconSize / 2)
        iconView.frame = CGRect(x: startX, y: 120.f, width: iconSize, height: iconSize)
        
        let firstChildView = MTCoordinateContainer(view: iconView, endForm: CGRect(x: centerX, y: 120, width: 0, height: 0), corner: 0.5, completion: { [weak self] in
            let alert = UIAlertController(style: .alert)
            alert.addPhotoLibraryPicker(flow: .vertical, paging: false,
                                        selection: .single(action: { assets in
                                            if let imageData = RMUtility.getImageData(asset: assets!) {
                                                self?.headerImageView.image = UIImage(data: imageData)
                                                self?.changedPicData = imageData
                                            }
                                        }))
            alert.addAction(title: "Cancel", style: .cancel)
            alert.show()
        })
        firstChildView.isHidden = true
        return firstChildView
    }

    // MARK: - Button Actions
    override func setEditing(_ editing: Bool, animated: Bool) {
        editPicView.isHidden = !editing
        self.former[0...0].flatMap { $0.rowFormers }.forEach {
            $0.enabled = editing
        }
        if !editing {
            ANLoader.showLoading("", disableUI: true)
            var params = JSON(["cmd": Constants.ApiCommands.UPDATE_PROFILE_INFO,
                                         "dob_format": "MM-dd-yyyy",
                                         "country_code": (Constants.appDelegate.userProfile?.countryPhoneCode)! as Any])
            if let username = Constants.appDelegate.userProfile?.userName {
                params["screen_name"].string = username
            }
            if let email = Constants.appDelegate.userProfile?.emailID {
                params["email"].string = email
            }
            if let gender = Constants.appDelegate.userProfile?.gender {
                params["gender"].string = gender
            } else {
                params["gender"].string = ""
            }
            if let birthday = Constants.appDelegate.userProfile?.birthday {
                params["date_of_birth"].string = RMUtility.getDOBStringFromDate(date: birthday)
            }
            if let state = Constants.appDelegate.userProfile?.state {
                params["state"].string = state
            }
            if let city = Constants.appDelegate.userProfile?.city {
                params["city"].string = city
            }
            
            ServiceRequest.shared.startRequestForUpdateProfileInfo(withProfileInfo: params) { (success) in
                guard success else { return }
                
                if let data = self.changedPicData {
                    ServiceRequest.shared.startRequestForUploadProfilePic(picData: data, completionHandler: { (successUpload) in
                        ANLoader.hide()
                        if successUpload {
                            Constants.appDelegate.userProfile?.profilePicData = data
                            self.changedPicData = nil
                            self.coreDataStack.saveContexts(withCompletion: { (error) in
                                ANLoader.hide()
                                RMUtility.showAlert(withMessage: "Profile saved successfully")
                            })
                        }
                    })
                } else {
                    self.coreDataStack.saveContexts(withCompletion: { (error) in
                        ANLoader.hide()
                        RMUtility.showAlert(withMessage: "Profile saved successfully")
                    })
                }
            }
        }
        super.setEditing(editing, animated: true)
    }
    
}
