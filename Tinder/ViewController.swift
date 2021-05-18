//
//  ViewController.swift
//  Tinder
//
//  Created by horkimlong on 18/5/21.
//

import UIKit

class ViewController: UIViewController {

    let topStackView = TopNavigationStackView()
    let blueView = UIView()
    let buttonsStackView = HomeBottomControlsStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        blueView.backgroundColor = .blue
        setupLayout()
    }
    
    
    // MARK:- Fileprivate
    
    fileprivate func setupLayout() {
        let overallStackView = VerticalStackView(arrangedSubviews: [
            topStackView,
            blueView,
            buttonsStackView
        ])
        
        view.addSubview(overallStackView)
        overallStackView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
    }
}
