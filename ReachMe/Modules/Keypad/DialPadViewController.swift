//
//  DialPadViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 5/22/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class DialPadViewController: UIViewController {

    @IBOutlet weak var dialTextField: UITextField!
    @IBOutlet weak var blankDialButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        dialTextField.inputView = UIView()
        
        let dialText = dialTextField.rx.text.map { $0!.isEmpty }
        dialText.bind(to: backButton.rx.RxHidden).disposed(by: disposeBag)
        dialText.bind(to: blankDialButton.rx.RxHiddenToggle).disposed(by: disposeBag)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Button Actions
    @IBAction func onBackButtonClicked(_ sender: UIButton) {
        dialTextField.deleteBackward()
    }
    
    @IBAction func onNumberButtonClicked(_ sender: UIButton) {
        if sender.tag == 10 {
            dialTextField.insertText("*")
        } else if sender.tag == 11 {
            dialTextField.insertText("#")
        } else {
            dialTextField.insertText("\(sender.tag)")
        }
    }
    
    @IBAction func zeroLongpressAction(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            dialTextField.deleteBackward()
            dialTextField.insertText("+")
        }
    }
    
    @IBAction func backLongpressAction(_ sender: UILongPressGestureRecognizer) {
        dialTextField.deleteBackward()
    }
    
    @IBAction func onCallButtonClicked(_ sender: UIButton) {
        AppDelegate.shared.callManager.startCall(handle: "9742675676", videoEnabled: false)
        
    }

}

// MARK: - Textfield Delegate
extension DialPadViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let charset = CharacterSet(charactersIn: "0123456789*#+")
        return charset.isDisjoint(with: charset)
    }
}
