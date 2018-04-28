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

class ProfileViewController: FormViewController {

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
    }

    lazy var emailRow = TextFieldRowFormer<FormTextFieldCell>() {
        $0.titleLabel.text = "Email"
        $0.textField.returnKeyType = .next
        $0.textField.textAlignment = .right
        $0.textField.clearButtonMode = .never
        $0.textField.inputAccessoryView = self.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Enter email"
    }
    
    lazy var genderRow = InlinePickerRowFormer<FormInlinePickerCell, UITableViewRowAnimation>(instantiateType: .Class) {
        $0.titleLabel.text = "Gender"
        }.configure {
            let genders = ["N/A", "Male", "Female", "Other"]
            $0.pickerItems = genders.map { InlinePickerItem(title: $0) }
        }.onValueChanged { _ in
            //$0.value!
    }
    
    let birthdayRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
        $0.titleLabel.text = "Birthday"
        }.inlineCellSetup {
            $0.datePicker.datePickerMode = .date
        }.configure { _ in
        }.displayTextFromDate(String.profileDateStyle)
    
    lazy var countryRow = InlinePickerRowFormer<FormInlinePickerCell, UITableViewRowAnimation>(instantiateType: .Class) {
        $0.titleLabel.text = "Country"
        }.configure {
            let genders = ["N/A", "Male", "Female", "Other"]
            $0.pickerItems = genders.map { InlinePickerItem(title: $0) }
        }.onValueChanged { _ in
            //$0.value!
    }
    
    lazy var stateRow = LabelRowFormer<FormLabelCell>()
        .configure {
            $0.text = "State"
            $0.subText = "Select State"
        }.onSelected { [weak self] _ in
            self?.former.deselect(animated: true)
    }
    
    lazy var cityRow = TextFieldRowFormer<FormTextFieldCell>() {
        $0.titleLabel.text = "City"
        $0.textField.textAlignment = .right
        $0.textField.clearButtonMode = .never
        }.configure {
            $0.placeholder = "Enter City"
    }

    lazy var section = SectionFormer(rowFormer: nameRow, emailRow, genderRow, birthdayRow, countryRow, stateRow, cityRow)
        .set(headerViewFormer: createHeader(""))

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        
        if let profilePicData = userProfile?.profilePicData,
            let profileImage = UIImage(data: profilePicData) {
            let headerView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 250))
            headerView.image = profileImage
            coordinateManager = MTCoordinateManager.init(vc: self, scrollView: self.tableView, header: headerView)
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
        
        let firstChildView = MTCoordinateContainer.init(view: iconView, endForm: CGRect(x: centerX, y: 120, width: 0, height: 0), corner: 0.5, completion: { [weak self] in
            self?.hadleEditPhotoAction()
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
    
    func hadleEditPhotoAction() {
        
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
    var state: String?
    var city: String?
}
