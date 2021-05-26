//
//  RegistrationViewModel.swift
//  Tinder
//
//  Created by horkimlong on 25/5/21.
//

import UIKit

class RegistrationViewModel {
    var fullName: String? {
        didSet {
            checkFormValidity()
        }
    }
    var email: String? {
        didSet {
            checkFormValidity()
        }
    }
    var password: String? {
        didSet {
            checkFormValidity()
        }
    }
    
    fileprivate func checkFormValidity() {
        let isFormValid = fullName?.isEmpty == false && email?.isEmpty == false && password?.isEmpty == false
        
        isFormValidObserver?(isFormValid)
        
        
    }
    
    // Reactive programming
    var isFormValidObserver: ((Bool) -> ())?
}
