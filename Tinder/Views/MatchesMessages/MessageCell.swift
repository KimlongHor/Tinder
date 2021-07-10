//
//  MessageCell.swift
//  Tinder
//
//  Created by horkimlong on 9/7/21.
//

import UIKit
import LBTATools

class MessageCell: LBTAListCell<Message> {
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.font = .systemFont(ofSize: 20)
        tv.isScrollEnabled = false
        tv.isEditable = false
        return tv
    }()
    
    let bubbleContainer = UIView(backgroundColor: .lightGray)
    
    override var item: Message! {
        didSet {
            textView.text = item.text
            
            if item.isFromCurrentLoggedUser {
                // right edge
                anchoredConstraints.trailing?.isActive = true
                anchoredConstraints.leading?.isActive = false
                bubbleContainer.backgroundColor = #colorLiteral(red: 0.1780910113, green: 0.8093084336, blue: 0.9512503268, alpha: 1)
                textView.textColor = .white
            } else {
                // left edge
                anchoredConstraints.trailing?.isActive = false
                anchoredConstraints.leading?.isActive = true
                bubbleContainer.backgroundColor = #colorLiteral(red: 0.8782195527, green: 0.8782195527, blue: 0.8782195527, alpha: 1)
                textView.textColor = .black
            }
        }
    }
    
    var anchoredConstraints: AnchoredConstraints!
    
    override func setupViews() {
        super.setupViews()
        addSubview(bubbleContainer)
        
        bubbleContainer.layer.cornerRadius = 12
        
        anchoredConstraints = bubbleContainer.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
        anchoredConstraints.leading?.constant = 20
        anchoredConstraints.trailing?.isActive = false
        anchoredConstraints.trailing?.constant = -20
        
        bubbleContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 250).isActive = true
        
        bubbleContainer.addSubview(textView)
        textView.fillSuperview(padding: .init(top: 4, left: 12, bottom: 4, right: 12))
    }
}

