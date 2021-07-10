//
//  LoginController.swift
//  Tinder
//
//  Created by horkimlong on 10/6/21.
//

import Foundation
import UIKit
import JGProgressHUD

protocol LoginControllerDelegate {
    func didFinishLoggingIn()
}

class LoginController: UIViewController {
    
    var delegate: LoginControllerDelegate?
    
    let loginViewModel = LoginViewModel()
    
    let gradientLayer = CAGradientLayer()
    
    let emailTextField: CustomTextField = {
        let tf = CustomTextField(padding: 24)
        tf.placeholder = "Enter email"
        tf.backgroundColor = .white
        tf.addTarget(self, action: #selector(handleTextChange), for: .editingChanged)
        return tf
    }()
    
    let passwordTextField: CustomTextField = {
        let tf = CustomTextField(padding: 24)
        tf.placeholder = "Enter password"
        tf.backgroundColor = .white
        tf.addTarget(self, action: #selector(handleTextChange), for: .editingChanged)
        return tf
    }()
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        button.layer.cornerRadius = 22
        button.backgroundColor = .lightGray
        button.setTitleColor(.darkGray, for: .disabled)
        button.isEnabled = false
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        return button
    }()
    
    let loginHUD = JGProgressHUD()

    let goBackButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Go back", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        button.addTarget(self, action: #selector(handleGoBack), for: .touchUpInside)
        return button
    }()
    
    lazy var overallStackView = VerticalStackView(arrangedSubviews: [
        emailTextField,
        passwordTextField,
        loginButton
    ], spacing: 8)
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // we call this func here because the gradientLayer will layout properly when the phone is in landscape.
        gradientLayer.frame = view.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientLayer()
        setupLayout()
        setupBindables()
        setupNotificationObservers()
    }
    
    fileprivate func setupLayout() {
        navigationController?.isNavigationBarHidden = true
        overallStackView.distribution = .fillEqually
        
        view.addSubview(overallStackView)
        overallStackView.anchor(top: nil, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 50, bottom: 0, right: 50))
        overallStackView.centerYInSuperview()
        
        view.addSubview(goBackButton)
        goBackButton.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
    }
    
    fileprivate func setupGradientLayer() {
        
        let topColor = #colorLiteral(red: 0.9921568627, green: 0.3568627451, blue: 0.3725490196, alpha: 1)
        let bottomColor = #colorLiteral(red: 0.8980392157, green: 0, blue: 0.4470588235, alpha: 1)
        
        // make sure to user cgColor
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer.locations = [0, 1]
        view.layer.addSublayer(gradientLayer)
        gradientLayer.frame = view.bounds
    }
    
    
    fileprivate func setupBindables() {
        loginViewModel.isLogginIn.bind { [unowned self] (isRegistering) in
            if isRegistering == true {
                self.loginHUD.textLabel.text = "Register"
                self.loginHUD.show(in: self.view)
            } else {
                self.loginHUD.dismiss()
            }
        }
        
        loginViewModel.isFormValid.bind{ [unowned self] (isFormValid) in
            guard let isFormValid = isFormValid else { return }
            self.loginButton.isEnabled = isFormValid
            self.loginButton.backgroundColor = isFormValid ? #colorLiteral(red: 0.8242503482, green: 0, blue: 0.2313725501, alpha: 1) : .lightGray
            self.loginButton.setTitleColor(isFormValid ? .white : .darkGray, for: .normal)
        }
    }
    
    fileprivate func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc fileprivate func handleKeyboardHide() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut) {
            self.view.transform = .identity
        }
    }
    
    @objc fileprivate func handleKeyboardShow(notification: Notification) {
        // get how tall the keyboard is
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        let keyboardFrame = value.cgRectValue
        
        // get how tall the gap is from the register button to the bottom of the screen
        let bottomSpace = view.frame.height - overallStackView.frame.origin.y - overallStackView.frame.height
        let difference = keyboardFrame.height - bottomSpace
        
        self.view.transform = CGAffineTransform(translationX: 0, y: -difference - 8)
    }
    
    @objc fileprivate func handleTextChange(textField: UITextField) {
        if textField == emailTextField {
            loginViewModel.email = emailTextField.text
        } else {
            loginViewModel.password = passwordTextField.text
        }
    }
    
    @objc fileprivate func handleGoBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc fileprivate func handleLogin() {
        loginViewModel.performLogin { (error) in
            self.loginHUD.dismiss()
            if let error = error {
                print("Failed to log in:", error)
                return
            }
            self.dismiss(animated: true) {
                self.delegate?.didFinishLoggingIn()
            }
        }
    }
}
