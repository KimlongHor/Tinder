//
//  CardView.swift
//  Tinder
//
//  Created by horkimlong on 19/5/21.
//

import UIKit

class CardView: UIView {
    fileprivate let imageView = UIImageView(image: #imageLiteral(resourceName: "lady5c"))
    
    // Configuration
    fileprivate let threshold: CGFloat = 100
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 10
        clipsToBounds = true
        
        addSubview(imageView)
        imageView.fillSuperview()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGesture)
    }
    
    @objc fileprivate func handlePan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            handleChangedState(gesture)
        case .ended:
            handleEndedState(gesture)
        default:
            ()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func handleChangedState(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: nil)
        
        // rotation
        let degrees: CGFloat = translation.x / 20
        let angle = degrees * .pi / 180 // radian value
        let rotationalTransformation = CGAffineTransform(rotationAngle: angle)
        self.transform = rotationalTransformation.translatedBy(x: translation.x, y: translation.y)
    }
    
    fileprivate func handleEndedState(_ gesture: UIPanGestureRecognizer) {
        
        let translation = gesture.translation(in: nil)
        let shouldDismissCard = translation.x > threshold || translation.x < -threshold
        let draggingDirection: CGFloat = translation.x > 0 ? 1 : -1
        print(draggingDirection)
        
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
            if shouldDismissCard {
                self.center = CGPoint(x: 1000 * draggingDirection, y: 0)
            } else {
                self.transform = .identity
            }
        }, completion: {_ in
            self.transform = .identity
            self.frame = CGRect(x: 0, y: 0, width: self.superview!.frame.width, height: self.superview!.frame.height)
        })
    }
}
