//
//  Message.swift
//  Tinder
//
//  Created by horkimlong on 9/7/21.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct Message {
    let text: String
    let isFromCurrentLoggedUser: Bool
    let fromId: String
    let toId: String
    let timestamp: Timestamp
    
    init(dictionary: [String: Any]) {
        self.text = dictionary["text"] as? String ?? ""
        self.fromId = dictionary["fromId"] as? String ?? ""
        self.toId = dictionary["toId"] as? String ?? ""
        self.timestamp = dictionary["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        self.isFromCurrentLoggedUser = Auth.auth().currentUser?.uid == self.fromId
    }
    
}
