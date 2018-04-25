//
//  SingleSelectionTableController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 1/29/18.
//  Copyright © 2018 Kirusa. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftyUserDefaults

@objc public protocol SingleSelectionDelegate: NSObjectProtocol {
    @objc optional func onSelection(_ selectionType: SelectionType)
}

@objc public enum SelectionType: Int {
    case ringTone
    case notificationTone
    
    var value: String {
        switch self {
        case .ringTone: return "Ringtones"
        case .notificationTone: return "Notification Tones"
        }
    }
}

final class SingleSelectionTableViewController: UITableViewController {
    
    @objc open weak var delegate: SingleSelectionDelegate?
    
    var listSelectionType: SelectionType
    var selectionList = Dictionary<String, String>()
    var sortedKeys = [String]()
    let fileManager: FileManager = FileManager()
    let audioController = AudioController.sharedInstance()
    var selectedTone: String!
    
    // MARK: Initialize
    @objc init(with selectionType: SelectionType) {
        self.listSelectionType = selectionType
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = listSelectionType.value
        tableView.register(SingleSelctionTableCell.self, forCellReuseIdentifier: SingleSelctionTableCell.identifier)
        
        switch listSelectionType {
        case .ringTone:
            //If multiple files added to Ringtone, use Below
            /*   let bundlePath = Bundle.main.path(forResource: "AudioResource.bundle/RingTones", ofType: nil)
             populateList(with: bundlePath!)
             populateList(with: "/Library/Ringtones")*/
            
            let bundlePath = Bundle.main.path(forResource: "AudioResource.bundle/RingTones/ReachMeDefaultRingTone", ofType: "mp3")
            selectionList["ReachMe"] = bundlePath
            selectionList["iPhone"] = "/Library/Ringtones/Opening.m4r"
            sortAllKeys()
            
            if Defaults[.isRingtoneSet] {
                selectedTone = "iPhone"
            } else {
                selectedTone = "ReachMe"
            }
            
        case .notificationTone:
            //            let bundlePath = Bundle.main.path(forResource: "InstavoiceNotificationTone", ofType: "caf")
            let bundlePath = Bundle.main.path(forResource: "AudioResource.bundle/NotificationTones/ReachMeDefaultNotificationTone", ofType: "mp3")
            selectionList["Opening (Default)"] = bundlePath
            populateList(with: "/System/Library/Audio/UISounds")
//            if let savedNotificationTone = Constants.appDelegate.confgReader.getNotificationSoundInfo(),
//                let notificationTone = savedNotificationTone.keys.first {
//                selectedTone = notificationTone
//            } else {
//                selectedTone = "Opening (Default)"
//            }
        }
        
        //Selct saved
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: {
            self.tableView.selectRow(at: IndexPath.init(row: self.sortedKeys.index(of: self.selectedTone)!, section: 0), animated: true, scrollPosition: .none)
        })
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let audio = audioController.audioPlayer, audio.isPlaying {
            audio.stop()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Custom Methods
    func populateList(with path: String) {
        let directoryURL: URL = URL(fileURLWithPath: path, isDirectory: true)
        
        do {
            var URLs: [URL]?
            URLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey], options: FileManager.DirectoryEnumerationOptions())
            var urlIsaDirectory: ObjCBool = ObjCBool(false)
            for url in URLs! {
                fileManager.fileExists(atPath: url.path, isDirectory: &urlIsaDirectory)
                if !urlIsaDirectory.boolValue {
                    //Get filename by discard extention
                    var fileName = (url.lastPathComponent.components(separatedBy: CharacterSet.init(charactersIn: "."))).first
                    //Capitalize first letter of each word
                    var componentsList: [String] = []
                    fileName?.components(separatedBy: CharacterSet(charactersIn: "_-")).forEach({ component in
                        componentsList.append(component.capitalizingFirstLetter())
                    })
                    
                    fileName = componentsList.joined(separator: " ")
                    selectionList[fileName!] = url.lastPathComponent// Key = File name to be display, Value = Original file name with extention
                }
            }
        } catch {
            debugPrint("\(error)")
        }
        
        sortAllKeys()
        
    }
    
    //Sort all keys
    func sortAllKeys() {
        sortedKeys = selectionList.keys.sorted()
        if let defaultIndex = sortedKeys.index(of: "ReachMe") { // rearranging default element to first postion
            let element = sortedKeys.remove(at: defaultIndex)
            sortedKeys.insert(element, at: 0)
        }
    }
    
}

// MARK: - TableView Datasource
extension SingleSelectionTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectionList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: SingleSelctionTableCell.identifier, for: indexPath) as! SingleSelctionTableCell
        cell.textLabel?.text = sortedKeys[indexPath.row]
        
        return cell
    }
}

// MARK: - TableView Delegate
extension SingleSelectionTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var filePath: String?
        
        switch listSelectionType {
        case .ringTone:
            filePath = selectionList[sortedKeys[indexPath.row]]!
            
        case .notificationTone:
            if indexPath.row != 0 {
                filePath = "/System/Library/Audio/UISounds"
                filePath = (filePath as NSString?)?.appendingPathComponent((selectionList[sortedKeys[indexPath.row]])!)
            } else {
                filePath = selectionList[sortedKeys[indexPath.row]]!
            }
        }
        
        if indexPath.row == 0 {
            if let audio = audioController.audioPlayer, audio.isPlaying {
                audio.stop()
                return
            }
            let fileURL: URL = URL(fileURLWithPath: filePath!)
            do {
                audioController.audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                audioController.audioPlayer?.play()
            } catch {
                debugPrint("\(error)")
            }
        } else {
            if let audio = audioController.audioPlayer, audio.isPlaying {
                audio.stop()
            }
        }
        
        //Save
        switch listSelectionType {
        case .ringTone:
            if indexPath.row == 0 {
                Defaults[.isRingtoneSet] = false
            } else if indexPath.row == 1 {
                Defaults[.isRingtoneSet] = true
            }
            //Constants.appDelegate.setRingTone()
            delegate?.onSelection!(.ringTone)
            
        case .notificationTone:
            //let info: [String: String] = [sortedKeys[indexPath.row]: filePath!]
            //Constants.appDelegate.confgReader.setNotificationSound(info)
            delegate?.onSelection!(.notificationTone)
        }
        
    }
    
}

// MARK: - Table Cell
final class SingleSelctionTableCell: UITableViewCell {
    
    static let identifier = String(describing: SingleSelctionTableCell.self)
    
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

// MARK: - AudioController Class
final class AudioController: NSObject {
    var audioPlayer: AVAudioPlayer?
    class func sharedInstance() -> AudioController {
        return appControllerSingletonGlobal
    }
}
///Model singleton so that we can refer to this from throughout the app.
let appControllerSingletonGlobal = AudioController()
