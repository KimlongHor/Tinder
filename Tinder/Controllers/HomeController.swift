//
//  HomeController.swift
//  Tinder
//
//  Created by horkimlong on 18/5/21.
//

import UIKit
import Firebase
import JGProgressHUD

extension HomeController: CardViewDelegate {
    func didRemoveCard(cardView: CardView) {
        self.topCardView?.removeFromSuperview()
        self.topCardView = self.topCardView?.nextCardView
    }
    
    func didTapMoreInfo(cardViewModel: CardViewModel) {
        let userDetailsController = UserDetailsController()
        userDetailsController.cardViewModel = cardViewModel
        userDetailsController.modalPresentationStyle = .fullScreen
        present(userDetailsController, animated: true)
    }
}

extension HomeController: LoginControllerDelegate {
    func didFinishLoggingIn() {
        fetchCurrentUser()
    }
}

class HomeController: UIViewController, SettingsControllerDelegate {
    
    let topStackView = TopNavigationStackView()
    let cardsDeckView = UIView()
    let bottomControls = HomeBottomControlsStackView()
    
    var cardViewModels = [CardViewModel]()
    var lastFetchedUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bottomControls.refreshButton.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        bottomControls.likeButton.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        bottomControls.dislikeButton.addTarget(self, action: #selector(handleDislike), for: .touchUpInside)
        
        
        topStackView.settingsButton.addTarget(self, action: #selector(handleSettings), for: .touchUpInside)
        setupLayout()
        
        fetchCurrentUser()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if Auth.auth().currentUser == nil {
            let loginController = LoginController()
            loginController.delegate = self
            let navController = UINavigationController(rootViewController: loginController)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
    
    fileprivate var user: User?
    let hud = JGProgressHUD(style: .dark)
    
    fileprivate func fetchCurrentUser() {
        
        hud.textLabel.text = "Fetching Users"
        hud.show(in: view)
        Firestore.firestore().fetchCurrentUser { (user, error) in
            if let error = error {
                print("Failed fetching current user: ", error)
                self.hud.dismiss()
                return
            }
            self.user = user
            self.fetchUserFromFirestore()
        }
    }
    
    var topCardView: CardView?
    
    // MARK:- Fileprivate
    
    fileprivate func performSwipeAnimation(translation: CGFloat, andle: CGFloat) {
        // Create animation
        let translationAnimation = CABasicAnimation(keyPath: "position.x")
        translationAnimation.toValue = 700
        translationAnimation.duration = 0.5
        translationAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        translationAnimation.fillMode = .forwards
        translationAnimation.isRemovedOnCompletion = false
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = 15 * CGFloat.pi / 180
        rotationAnimation.duration = 1
        
        let cardView = topCardView
        topCardView = cardView?.nextCardView
        
        CATransaction.setCompletionBlock {
            self.topCardView?.removeFromSuperview()
            cardView?.removeFromSuperview()
        }
        
        // Apply animation to the view
        cardView?.layer.add(translationAnimation, forKey: "translation")
        cardView?.layer.add(rotationAnimation, forKey: "rotation")
        
        CATransaction.commit()
    }
    
    @objc fileprivate func handleDislike() {
        performSwipeAnimation(translation: -700, andle: -15)
    }
    
    @objc fileprivate func handleLike() {
        performSwipeAnimation(translation: 700, andle: 15)
    }
    
    @objc fileprivate func handleRefresh() {
        fetchUserFromFirestore()
    }
    
    fileprivate func fetchUserFromFirestore() {
        
        let minAge = user?.minSeekingAge ?? SettingsController.defaultMinSeekingAge
        let maxAge = user?.maxSeekingAge ?? SettingsController.defaultMaxSeekingAge
        
        let query = Firestore.firestore().collection("users").whereField("age", isGreaterThanOrEqualTo: minAge).whereField("age", isLessThanOrEqualTo: maxAge)
        
        topCardView = nil
        
        query.getDocuments { [self] (snapshot, error) in
            self.hud.dismiss()
            if let error = error {
                print("Failed to fetch users: ", error)
                return
            }
            
            var previousCardView: CardView?
            
            snapshot?.documents.forEach({ (documentSnapshot) in
                let userDictionary = documentSnapshot.data()
                let user = User(dictionary: userDictionary)
                if user.uid != Auth.auth().currentUser?.uid {
                    let cardView = self.setupCardFromUser(user: user)
                    
                    previousCardView?.nextCardView = cardView
                    previousCardView = cardView
                    
                    if self.topCardView == nil {
                        self.topCardView = cardView
                    }
                }
            })
        }
    }
    
    fileprivate func setupCardFromUser(user: User) -> CardView{
        let cardView = CardView(frame: .zero)
        cardView.cardViewModel = user.toCardViewModel()
        cardView.delegate = self
        cardsDeckView.addSubview(cardView)
        
        // Prevent the card from flashing
        cardsDeckView.sendSubviewToBack(cardView)
        
        cardView.fillSuperview()
        return cardView
    }
    
    @objc fileprivate func handleSettings() {
        let settingsController = SettingsController()
        settingsController.delegate = self
        let navController = UINavigationController(rootViewController: settingsController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    func didSaveSettings() {
        fetchCurrentUser()
    }
    
    fileprivate func setupFirestoreUserCards() {
        cardViewModels.forEach { (cardVM) in
            let cardView = CardView()
            cardView.cardViewModel = cardVM
            cardsDeckView.addSubview(cardView)
            cardView.fillSuperview()
        }
    }
    
    fileprivate func setupLayout() {
        view.backgroundColor = .white
        let overallStackView = VerticalStackView(arrangedSubviews: [
            topStackView,
            cardsDeckView,
            bottomControls
        ])
        
        view.addSubview(overallStackView)
        overallStackView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
        
        overallStackView.isLayoutMarginsRelativeArrangement = true
        overallStackView.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)
        
        overallStackView.bringSubviewToFront(cardsDeckView)
    }
}
