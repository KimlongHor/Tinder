//
//  RegistrationViewModel.swift
//  Tinder
//
//  Created by horkimlong on 25/5/21.
//

import UIKit
import Firebase

class RegistrationViewModel {
    
//    var image: UIImage? {
//        didSet {
//            imageObserver?(image)
//        }
//    }
//
//    var imageObserver: ((UIImage?) -> ())?
    
    // We can simply use this one line of code instead of the above code.
    var bindableImage = Bindable<UIImage>()
    var bindableIsRegistering = Bindable<Bool>()
    
    var fullName: String? { didSet { checkFormValidity() } }
    var email: String? { didSet { checkFormValidity() } }
    var password: String? { didSet { checkFormValidity() } }
    
    func performRegistration(completion: @escaping (Error?) -> ()) {
        guard let email = email else { return }
        guard let password = password else { return }
        
        bindableIsRegistering.value = true
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                completion(error)
                return
            }
            
            self.saveImageToFirebase(completion: completion)
        }
    }
    
    fileprivate func saveImageToFirebase(completion: @escaping (Error?) -> ()) {
        let filename = UUID().uuidString
        let ref = Storage.storage().reference(withPath: "/images/\(filename)")
        let imageData = self.bindableImage.value?.jpegData(compressionQuality: 0.75) ?? Data()
        ref.putData(imageData, metadata: nil) { (_, error) in
            if let error = error {
                completion(error)
                return
            }
            
            print("Finished uploading image to storage")
            ref.downloadURL { (url, error) in
                if let error = error {
                    completion(error)
                    return
                }
                self.bindableIsRegistering.value = false
                let imageUrl = url?.absoluteString ?? ""
                
                self.saveInfoToFiresotre(imageUrl: imageUrl, completion: completion)
            }
        }
    }
    
    fileprivate func saveInfoToFiresotre(imageUrl:String, completion: @escaping (Error?) -> ()) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        let docData = [
            "fullName": fullName ?? "",
            "uid": uid,
            "imageUrl1" : imageUrl
        ]
        
        Firestore.firestore().collection("users").document(uid).setData(docData) { (error) in
            if let error = error {
                completion(error)
                return
            }
            
            completion(nil)
        }
    }
    
    fileprivate func checkFormValidity() {
        let isFormValid = fullName?.isEmpty == false && email?.isEmpty == false && password?.isEmpty == false
        
        isFormValidObserver?(isFormValid)
    }
    
    // Reactive programming
    var isFormValidObserver: ((Bool) -> ())?
}
