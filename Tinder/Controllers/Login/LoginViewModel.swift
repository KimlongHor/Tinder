//
//  LoginViewModel.swift
//  Tinder
//
//  Created by horkimlong on 10/6/21.
//

import UIKit
import Firebase

class LoginViewModel {
    
    var email: String? {didSet {checkForValidity()}}
    var password: String? {didSet {checkForValidity()}}
    
    var isLogginIn = Bindable<Bool>()
    var isFormValid = Bindable<Bool>()

    
    fileprivate func checkForValidity() {
        let isValid = email?.isEmpty == false && password?.isEmpty == false
        
        isFormValid.value = isValid
    }

    func performLogin(completion: @escaping (Error?) -> ()) {
        guard let email = email, let password = password else { return }
        isLogginIn.value = true
        Auth.auth().signIn(withEmail: email, password: password) { (res, error) in
            completion(error)
        }
    }
}
