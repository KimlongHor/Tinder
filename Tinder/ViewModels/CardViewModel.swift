//
//  CardViewModel.swift
//  Tinder
//
//  Created by horkimlong on 20/5/21.
//

import UIKit

protocol ProducesCardViewModel {
    func toCardViewModel() -> CardViewModel
}

// View Model is supposed to represent the state of our view
class CardViewModel {
    let imageUrls: [String]
    let attributedString: NSAttributedString
    let textAlignment: NSTextAlignment
    
    init(imageNames: [String], attributedString: NSAttributedString, textAlignment: NSTextAlignment) {
        self.imageUrls = imageNames
        self.attributedString = attributedString
        self.textAlignment = textAlignment
    }
    
    fileprivate var imageIndex = 0 {
        didSet {
            let imageUrl = imageUrls[imageIndex]
            imageIndexObserver?(imageIndex, imageUrl)
        }
    }
    
    // Reactive Programming: we want to expose a property in CardViewModel obj such that we can notify an external class about the changes inside the view state. In this case, we want to let the external class know that imageIndex is changed.
    var imageIndexObserver: ((Int, String?) -> ())?
    
    func advanceToNextPhoto() {
        imageIndex = min(imageIndex + 1, imageUrls.count - 1)
    }
    
    func goToPrevious() {
        imageIndex = max(0, imageIndex - 1)
    }
}
