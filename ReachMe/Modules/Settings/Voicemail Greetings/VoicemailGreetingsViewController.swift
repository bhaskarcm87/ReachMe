//
//  VoicemailGreetingsViewController.swift
//  ReachMe
//
//  Created by Bhaskar Munireddy on 30/04/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

class VoicemailGreetingsViewController: UITableViewController {
    
    // MARK: - Properties
    @IBOutlet weak var nameRecordButton: UIButton!
    @IBOutlet weak var welcomeRecordButton: UIButton!
    @IBOutlet weak var nameRecordStatus: UILabel!
    @IBOutlet weak var welcomeRecordStatus: UILabel!
    @IBOutlet weak var nameVoiceView: UIView!
    @IBOutlet weak var welcomeVoiceView: UIView!
    @IBOutlet weak var namePlayButton: UIImageView!
    @IBOutlet weak var welcomePlayButton: UIImageView!
    @IBOutlet weak var nameAudioSlider: UISlider!
    @IBOutlet weak var welcomeAudioSlider: UISlider!
    @IBOutlet weak var nameAudioDuration: UILabel!
    @IBOutlet weak var welcomeAudioDuration: UILabel!
    @IBOutlet weak var nameCancelRecordButton: UIButton!
    @IBOutlet weak var welcomeCancelRecordButton: UIButton!
    
    var isNameGreetingAvailable: Bool!
    var isWelcomeGreetingAvailable: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        view.backgroundColor = UIColor.groupTableViewBackground
        
        isNameGreetingAvailable = true
        isWelcomeGreetingAvailable = true
        
        nameAudioSlider.setThumbImage(UIImage(named: "slide-img-small-red"), for: .normal)
        welcomeAudioSlider.setThumbImage(UIImage(named: "slide-img-small-red"), for: .normal)
        
        let nameDurationStringValue = NSString(format: "0:%.2ld", (Constants.appDelegate.userProfile?.greetingNameDuration)!)
        let welcomeDurationStringValue = NSString(format: "0:%.2ld", (Constants.appDelegate.userProfile?.greetingWelcomeDuration)!)
        
        nameAudioDuration.text = nameDurationStringValue as String
        welcomeAudioDuration.text = welcomeDurationStringValue as String
        
    }
    
    @IBAction func cancelRecording(_ sender: Any) {
        
        if (sender as AnyObject).tag == 101 {
            
            nameVoiceView.isHidden = true
            isNameGreetingAvailable = false
            
        } else {
            
            welcomeVoiceView.isHidden = true
            isWelcomeGreetingAvailable = false
            
        }
        
        tableView.reloadData()
    }
    
    @IBAction func didTapOnRecord(_ sender: Any) {
        
    }
    
    @IBAction func audioSliderTouchCancel(_ sender: Any) {
        
    }
    
    @IBAction func audioSliderTouchDragInside(_ sender: Any) {
        
    }
    
    @IBAction func audioSliderTouchDragOutSide(_ sender: Any) {
        
    }
    
    @IBAction func audioSliderTouchUpInside(_ sender: Any) {
        
    }
    
    @IBAction func audioSliderTouchUpOutside(_ sender: Any) {
        
    }
    
    @IBAction func audioSliderValueChanged(_ sender: Any) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == 1 {
            
            if !isNameGreetingAvailable {
                return 90.0
            } else {
                return 140.0
            }
            
        } else if indexPath.row == 2 {
            
            if !isWelcomeGreetingAvailable {
                return 90.0
            } else {
                return 140.0
            }
            
        }
        
        return 80.0
    }
}
