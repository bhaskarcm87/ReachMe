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

class ProfileViewController: FormViewController {

    // MARK: - Properties
    var userProfile: Profile? {
        get {
            return CoreDataModel.sharedInstance().getUserProfle()!
        }
    }
    fileprivate var coordinateManager: MTCoordinateManager?
    var editPicView: MTCoordinateContainer!
    
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
        $0.textField.returnKeyType = .next
        $0.textField.textAlignment = .right
        $0.textField.clearButtonMode = .never
        $0.textField.inputAccessoryView = self.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Enter name"
        }.onTextChanged {
            EditProfile.sharedInstance.name = $0
    }

    lazy var emailRow = TextFieldRowFormer<FormTextFieldCell>() {
        $0.titleLabel.text = "Email"
        $0.textField.returnKeyType = .next
        $0.textField.textAlignment = .right
        $0.textField.clearButtonMode = .never
        $0.textField.inputAccessoryView = self.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Enter email"
        }.onTextChanged {
            EditProfile.sharedInstance.email = $0
    }
    
    lazy var genderRow = InlinePickerRowFormer<FormInlinePickerCell, UITableViewRowAnimation>(instantiateType: .Class) {
        $0.titleLabel.text = "Gender"
        $0.displayLabel.textColor = .black
        }.configure {
            let genders = ["N/A", "Male", "Female", "Other"]
            $0.pickerItems = genders.map { InlinePickerItem(title: $0) }
        }.onValueChanged {
            EditProfile.sharedInstance.gender = $0.title
    }
    
    let birthdayRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
        $0.titleLabel.text = "Birthday"
        $0.displayLabel.textColor = .black
        }.inlineCellSetup {
            $0.datePicker.datePickerMode = .date
        }.configure { _ in
        }.displayTextFromDate(String.profileDateStyle)
    
    lazy var countryRow = LabelRowFormer<FormLabelCell>()
        .configure {
            $0.text = "Country"
            $0.cell.formSubTextLabel()?.textColor = .black
            if let country = userProfile?.countryName {
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
                EditProfile.sharedInstance.country = $0?.country
                EditProfile.sharedInstance.phoneCode = $0?.phoneCode
            }
            alert.addAction(title: "Cancel", style: .cancel)
            alert.show()
    }
    
    lazy var stateRow = LabelRowFormer<FormLabelCell>()
        .configure {
            $0.text = "State"
            $0.subText = "Select State"
            $0.cell.formSubTextLabel()?.textColor = .black
            
        }.onSelected { [weak self] _ in
            self?.former.deselect(animated: true)
            ANLoader.showLoading("", disableUI: true)
            ServiceRequest.shared().startRequestForStatesList(forCountryCode: "091", completionHandler: { (responseDisc, success) in
                ANLoader.hide()
                guard success else { return }
                if let states = responseDisc?["state_list"] as? [[String: Any]], states.count > 0 {
                    let stateNames = states.map {$0["stateName"] as! String}
                    
                    let selectionMenu =  RSSelectionMenu(dataSource: stateNames) { (cell, object, indexPath) in
                        cell.textLabel?.text = object
                    }
                    if let rowFormer = self?.former.rowFormer(indexPath: IndexPath(row: 5, section: 0)) as? LabelRowFormer<FormLabelCell> {

                        selectionMenu.setSelectedItems(items: []) { (text, isSelected, selectedItems) in
                            rowFormer.subText = text
                            rowFormer.update()
                            EditProfile.sharedInstance.state = text
                        }
                        selectionMenu.showSearchBar(withPlaceHolder: "Select State", tintColor: UIColor.white.withAlphaComponent(0.3)) { (searchText) -> ([String]) in
                            return stateNames.filter({ $0.lowercased().contains(searchText.lowercased()) })
                        }
                        selectionMenu.show(style: .Popover(sourceView: rowFormer.cell, size: CGSize(width: 300, height: 400)), from: self!)
                    }
                }
            })
    }
    
    lazy var cityRow = TextFieldRowFormer<FormTextFieldCell>() {
        $0.titleLabel.text = "City"
        $0.textField.textAlignment = .right
        $0.textField.clearButtonMode = .never
        }.configure {
            $0.placeholder = "Enter City"
        }.onTextChanged {
            EditProfile.sharedInstance.city = $0
    }

    lazy var section = SectionFormer(rowFormer: nameRow, emailRow, genderRow, birthdayRow, countryRow, stateRow, cityRow)
        .set(headerViewFormer: createHeader(""))

    lazy var headerImageView: UIImageView = {
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.isUserInteractionEnabled = true
        return $0
    }(UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 250)))
    
    // MARK: - Viewlifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem

        UIApplication.shared.statusBarView?.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        
        if let profilePicData = userProfile?.profilePicData,
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

    func createEditPicView() -> MTCoordinateContainer {
        let iconView = UIImageView.init(image: #imageLiteral(resourceName: "edit_pic_camera"))
        let centerX = self.view.frame.width / 2
        let iconSize = 40.f
        let startX = centerX - (iconSize / 2)
        iconView.frame = CGRect(x: startX, y: 120.f, width: iconSize, height: iconSize)
        
        let firstChildView = MTCoordinateContainer(view: iconView, endForm: CGRect(x: centerX, y: 120, width: 0, height: 0), corner: 0.5, completion: { [weak self] in
            let alert = UIAlertController(style: .alert)
            alert.addPhotoLibraryPicker(flow: .vertical, paging: false,
                                        selection: .single(action: { assets in
                                            self?.headerImageView.image = RMUtility.getUIImage(asset: assets!)
                                            EditProfile.sharedInstance.image = RMUtility.getUIImage(asset: assets!)
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
        super.setEditing(editing, animated: true)
    }
    
}

final class EditProfile {
    
    static let sharedInstance = EditProfile()
    
    var image: UIImage?
    var name: String?
    var email: String?
    var gender: String?
    var birthDay: Date?
    var country: String?
    var phoneCode: String?
    var state: String?
    var city: String?
}
