//
//  ChatTableCells.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 4/10/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import Foundation
import UIKit
import SwipeCellKit

class ChatsGeneralCell: SwipeTableViewCell {
    
    static let identifier = String(describing: ChatsGeneralCell.self)
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var chatMessageLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    var indicatorView = IndicatorView(frame: .zero)
    var animator: Any?

    var unread = false {
        didSet {
            indicatorView.transform = unread ? CGAffineTransform.identity : CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        }
    }
    
    override func awakeFromNib() {
        setupIndicatorView()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupIndicatorView() {
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.color = tintColor
        indicatorView.backgroundColor = .clear
        contentView.addSubview(indicatorView)
        
        let size: CGFloat = 14
        indicatorView.widthAnchor.constraint(equalToConstant: size).isActive = true
        indicatorView.heightAnchor.constraint(equalTo: indicatorView.widthAnchor).isActive = true
        indicatorView.centerXAnchor.constraint(equalTo: dataLabel.rightAnchor, constant: -8).isActive = true
        indicatorView.centerYAnchor.constraint(equalTo: dataLabel.centerYAnchor, constant: 23).isActive = true
    }
    
    func setUnread(_ unread: Bool, animated: Bool) {
        let closure = {
            self.unread = unread
        }
        
        var localAnimator = self.animator as? UIViewPropertyAnimator
        localAnimator?.stopAnimation(true)
        
        localAnimator = unread ? UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.4) : UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1.0)
        localAnimator?.addAnimations(closure)
        localAnimator?.startAnimation()
        
        self.animator = localAnimator
    }
}


class IndicatorView: UIView {
    var color = UIColor.clear {
        didSet { setNeedsDisplay() }
    }
    
    override func draw(_ rect: CGRect) {
        color.set()
        UIBezierPath(ovalIn: rect).fill()
    }
}

enum ActionDescriptor {
    case read, unread, close, block
    
    var title: String {
        switch self {
        case .read: return "Read"
        case .unread: return "Unread"
        case .close: return "Close"
        case .block: return "Block"
        }
    }
    
    var color: UIColor {
        switch self {
        case .read, .unread: return #colorLiteral(red: 0, green: 0.4577052593, blue: 1, alpha: 1)
        case .close: return #colorLiteral(red: 1, green: 0.2352941176, blue: 0.1882352941, alpha: 1)
        case .block: return #colorLiteral(red: 0.7803494334, green: 0.7761332393, blue: 0.7967314124, alpha: 1)
        }
    }
}

enum ButtonStyle {
    case backgroundColor, circular
}
