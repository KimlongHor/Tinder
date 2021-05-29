//
//  User.swift
//  Tinder
//
//  Created by horkimlong on 19/5/21.
//

import UIKit

struct User: ProducesCardViewModel {
    let name: String?
    let age: Int?
    let profession: String?
    let imageUrl1: String?
    let uid: String?
    
    init(dictionary: [String: Any]) {
        self.name = dictionary["fullName"] as? String ?? ""
        self.imageUrl1 = dictionary["imageUrl1"] as? String ?? ""
        self.uid = dictionary["uid"] as? String ?? ""
        self.age = dictionary["age"] as? Int
        self.profession = dictionary["profession"] as? String
    }
    
    func toCardViewModel() -> CardViewModel {
        let attributedText = NSMutableAttributedString(string: name ?? "", attributes: [.font: UIFont.systemFont(ofSize: 32, weight: .heavy)])
        
        let ageString = age != nil ? "\(age!)" : "N\\A"
        
        attributedText.append(NSAttributedString(string: " \(ageString)", attributes: [.font: UIFont.systemFont(ofSize: 24, weight: .regular)]))
        
        let professionString = profession != nil ? profession! : "Not available"
        attributedText.append(NSAttributedString(string: " \n\(professionString)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .regular)]))
        
        return CardViewModel(imageNames: [imageUrl1 ?? ""], attributedString: attributedText, textAlignment: .left)
    }
}
