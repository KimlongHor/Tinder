//
//  ViewController.swift
//  Tinder
//
//  Created by horkimlong on 18/5/21.
//

import UIKit

class ViewController: UIViewController {

    let topStackView = TopNavigationStackView()
    let cardsDeckView = UIView()
    let buttonsStackView = HomeBottomControlsStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupDummyCards()
    }
    
    // MARK:- Fileprivate
    
    fileprivate func setupDummyCards() {
        let cardView = CardView()
        cardsDeckView.addSubview(cardView)
        cardView.fillSuperview()
    }
    
    fileprivate func setupLayout() {
        let overallStackView = VerticalStackView(arrangedSubviews: [
            topStackView,
            cardsDeckView,
            buttonsStackView
        ])
        
        view.addSubview(overallStackView)
        overallStackView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
        
        overallStackView.isLayoutMarginsRelativeArrangement = true
        overallStackView.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)
        
        overallStackView.bringSubviewToFront(cardsDeckView)
    }
}
