//
//  MessagesTableCells.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/23/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MediaPlayer

class CallsGeneralCell: UITableViewCell {

    static let identifier = String(describing: CallsGeneralCell.self)
    
    @IBOutlet weak var msgProfileImageView: UIImageView!
    @IBOutlet weak var msgStatusImageView: UIImageView!
    @IBOutlet weak var msgUsernameLabel: UILabel!
    @IBOutlet weak var msgDateLabel: UILabel!
    @IBOutlet weak var msgContentLabel: UILabel!
    @IBOutlet weak var msgReachmeLabel: UILabel!
    @IBOutlet weak var msgFromLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    var message: Message!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func confiureCellForMessage(message: Message) {
        self.message = message
        
        //TODO:- msgProfileImageView.image  -- check for single or gorup image by conversation type,  EX- g for gorup
        msgUsernameLabel.text = message.senderName//TODO: handle while phone number will come this place, parse in phonekit
        msgDateLabel.text = RMUtility.convertUTCNumberToDateString(number: message.date)
        if message.readCount > 0 {
            msgContentLabel.textColor = #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
            msgContentLabel.font = UIFont.systemFont(ofSize: 15)
            msgDateLabel.textColor = #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
            msgDateLabel.font = UIFont.systemFont(ofSize: 13)
        } else {
            msgContentLabel.textColor = .black
            msgContentLabel.font = UIFont.boldSystemFont(ofSize: 15)
            msgDateLabel.textColor = .black
            msgDateLabel.font = UIFont.boldSystemFont(ofSize: 13)
        }
        
        if message.type == "mc" {
            msgContentLabel.text = "Missed call"
            if message.flow == "r" {
                msgStatusImageView.image = #imageLiteral(resourceName: "receive_message")
            } else if message.flow == "s" {
                msgStatusImageView.image = #imageLiteral(resourceName: "sent_message")
            }
        }
        
        if let contactCount = Constants.appDelegate.userProfile?.userContacts?.count, contactCount > 1 {
            msgFromLabel.text = "To: \(message.receivePhoneNumber!)"
        }
    }
    
    // MARK: - Button Actions
    @IBAction func onCallButtonClicked(_ sender: UIButton) {
        UIApplication.shared.open(NSURL(string: "telprompt://\(message.fromPhoneNumber!)")! as URL, options: [:], completionHandler: nil)
    }
}

class VoicemailsGeneralCell: UITableViewCell, JukeboxDelegate {
    
    static let identifier = String(describing: VoicemailsGeneralCell.self)
    
    @IBOutlet weak var msgProfileImageView: UIImageView!
    @IBOutlet weak var msgStatusImageView: UIImageView!
    @IBOutlet weak var msgUsernameLabel: UILabel!
    @IBOutlet weak var msgDateLabel: UILabel!
    @IBOutlet weak var deleteSpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    var itemDuration: Double = 0.0
    var isSliderChanged: Bool  = false
    var message: Message!
    
    lazy var jukebox: Jukebox = {
        $0.volume = 1.0
        return $0
    }(Jukebox(delegate: self, items: [])!)
    
    var isRead: Bool {
        get {
            return message.readCount == 0 ? false : true
        }
        set {
            if newValue {
                msgDateLabel.textColor = #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
                msgDateLabel.font = UIFont.systemFont(ofSize: 13)
                slider.setThumbImage(#imageLiteral(resourceName: "slide-img-small-gray"), for: .normal)
                if jukebox.state == .loading || jukebox.state == .playing {
                    playButton.setImage(#imageLiteral(resourceName: "pause-gray"), for: .normal)
                } else {
                    playButton.setImage(#imageLiteral(resourceName: "play-gray"), for: .normal)
                }
            } else {
                msgDateLabel.textColor = .black
                msgDateLabel.font = UIFont.boldSystemFont(ofSize: 13)
                slider.setThumbImage(#imageLiteral(resourceName: "slide-img-small-red"), for: .normal)
                
                if jukebox.state == .loading || jukebox.state == .playing {
                    playButton.setImage(#imageLiteral(resourceName: "pause-red"), for: .normal)
                } else {
                    playButton.setImage(#imageLiteral(resourceName: "play-red"), for: .normal)
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super .layoutSubviews()
        
        //TODO:- msgProfileImageView.image  -- check for single or gorup image by conversation type,  EX- g for gorup
        msgUsernameLabel.text = message.senderName//TODO: handle while phone number will come this place, parse in phonekit
        msgDateLabel.text = RMUtility.convertUTCNumberToDateString(number: message.date)
        isRead = message.readCount == 0 ? false : true
        
        if message.type == "vsms" {
            if message.flow == "r" {
                msgStatusImageView.image = #imageLiteral(resourceName: "receive_message")
            } else if message.flow == "s" {
                msgStatusImageView.image = #imageLiteral(resourceName: "sent_message")
            }
        }
        
        if jukebox.state == .ready {
                    let jukeItem = JukeboxItem(URL: URL(string: "http://www.noiseaddicts.com/samples_1w72b820/2514.mp3")!)
            //        let jukeItem = JukeboxItem(URL: URL(string: "http://www.noiseaddicts.com/samples_1w72b820/2958.mp3")!)
            //        let jukeItem = JukeboxItem(URL: URL(string: message.content!)!)
            //let jukeItem = JukeboxItem(URL: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!)
            jukebox = Jukebox(delegate: self, items: [jukeItem])!
        }
        
        populateLabelWithTime(timerLabel, time: itemDuration)
    }
    
    func jukeboxStateDidChange(_ jukebox: Jukebox) {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.indicator.alpha = jukebox.state == .loading ? 1 : 0
            self.playButton.alpha = jukebox.state == .loading ? 0 : 1
            self.playButton.isEnabled = jukebox.state == .loading ? false : true
        })
        
        if jukebox.state == .ready {
            slider.setValue(0.0, animated: true)
            populateLabelWithTime(self.timerLabel, time: self.itemDuration)
            if isRead {
                playButton.setImage(#imageLiteral(resourceName: "play-gray"), for: .normal)
            } else {
                playButton.setImage(#imageLiteral(resourceName: "play-red"), for: .normal)
            }

        } else if jukebox.state == .loading || jukebox.state == .playing {
            if isRead {
                playButton.setImage(#imageLiteral(resourceName: "pause-gray"), for: .normal)
            } else {
                playButton.setImage(#imageLiteral(resourceName: "pause-red"), for: .normal)
            }
        } else if jukebox.state == .paused || jukebox.state == .failed {
            if isRead {
                playButton.setImage(#imageLiteral(resourceName: "play-gray"), for: .normal)
            } else {
                playButton.setImage(#imageLiteral(resourceName: "play-red"), for: .normal)
            }
        }
        
        print("Jukebox state changed to \(jukebox.state)")
    }
    
    func jukeboxPlaybackProgressDidChange(_ jukebox: Jukebox) {
        //--Skipping Playertime if user drags slider at initial, i.e before download or start play
        if isSliderChanged {
            isSliderChanged = false
            if let duration = jukebox.currentItem?.meta.duration {
                jukebox.seek(toSecond: Int(Double(slider.value) * duration))
            }
            return
        }
        
        //Regular Update
        if let currentTime = jukebox.currentItem?.currentTime, let duration = jukebox.currentItem?.meta.duration {
            let value = Float(currentTime / duration)
            slider.setValue(value, animated: true)
            populateLabelWithTime(timerLabel, time: currentTime)
            itemDuration = duration
        }
    }
    
    func jukeboxDidLoadItem(_ jukebox: Jukebox, item: JukeboxItem) {
        print("Jukebox did load: \(item.URL.lastPathComponent)")
    }
    
    func jukeboxDidUpdateMetadata(_ jukebox: Jukebox, forItem: JukeboxItem) {
    }
    
    func populateLabelWithTime(_ label: UILabel, time: Double) {
        let minutes = Int(time / 60)
        let seconds = Int(time) - minutes * 60
        
        label.text = String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds)
    }
    
    // MARK: - Button Actions
    @IBAction func onPlayButtonClicked(_ sender: UIButton) {
        switch jukebox.state {
        case .ready :
            jukebox.play(atIndex: 0)
        case .playing :
            jukebox.pause()
        case .paused :
            jukebox.play()
        default:
            jukebox.stop()
        }
    }
    
    @IBAction func sliderVlaueChanged(_ sender: UISlider) {
        isSliderChanged = true
        if let duration = jukebox.currentItem?.meta.duration {
            isSliderChanged = false
            jukebox.seek(toSecond: Int(Double(sender.value) * duration))
        }
    }
    
    @IBAction func onCallButtonClicked(_ sender: UIButton) {
        UIApplication.shared.open(NSURL(string: "telprompt://\(message.fromPhoneNumber!)")! as URL, options: [:], completionHandler: nil)
    }
}
