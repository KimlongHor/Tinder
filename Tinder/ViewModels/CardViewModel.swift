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

struct CardViewModel {
    let imageName: String
    let attributedString: NSAttributedString
    let textAlignment: NSTextAlignment
}
