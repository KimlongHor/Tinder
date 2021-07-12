//
//  MatchesHeaderCell.swift
//  Tinder
//
//  Created by horkimlong on 12/7/21.
//

import LBTATools
import UIKit

class MatchesHeader: UICollectionReusableView {
    
    let newMatchesLabel = UILabel(text: "New Matches", font: .boldSystemFont(ofSize: 16), textColor: #colorLiteral(red: 1, green: 0.4293031394, blue: 0.5105444789, alpha: 1))
    
    let matchesHorizontalController = MatchesHorizontalController()
    
    let messageLabel = UILabel(text: "Messages", font: .boldSystemFont(ofSize: 16), textColor: #colorLiteral(red: 1, green: 0.4293031394, blue: 0.5105444789, alpha: 1))
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        stack(stack(newMatchesLabel).padLeft(20),
              matchesHorizontalController.view,
              stack(messageLabel).padLeft(20),
              spacing: 20).withMargins(.init(top: 20, left: 0, bottom: 8, right: 0))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
