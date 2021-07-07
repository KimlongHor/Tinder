//
//  HomeController.swift
//  Tinder
//
//  Created by horkimlong on 18/5/21.
//

import UIKit
import Firebase
import JGProgressHUD
import FirebaseAuth
import FirebaseFirestore

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
        
        navigationController?.navigationBar.isHidden = true
        
        bottomControls.refreshButton.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        bottomControls.likeButton.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        bottomControls.dislikeButton.addTarget(self, action: #selector(handleDislike), for: .touchUpInside)
        
        
        topStackView.settingsButton.addTarget(self, action: #selector(handleSettings), for: .touchUpInside)
        topStackView.messageButton.addTarget(self, action: #selector(handleMessages), for: .touchUpInside)
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
            
            self.fetchSwipes()
        }
    }
    
    var swipes = [String: Int]()
    
    fileprivate func fetchSwipes() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("swipes").document(uid).getDocument { (snapshot, error) in
            if let error = error {
                print("Failed to fetch swipes info for currently logged in user:", error)
                return
            }
            
            guard let data = snapshot?.data() as? [String: Int] else { return }
            self.swipes = data
            self.fetchUserFromFirestore()
        }
    }
    
    var topCardView: CardView?
    
    // MARK:- Fileprivate
    
    fileprivate func performSwipeAnimation(translation: CGFloat, angle: CGFloat) {
        // Create animation
        let translationAnimation = CABasicAnimation(keyPath: "position.x")
        translationAnimation.toValue = translation
        translationAnimation.duration = 0.5
        translationAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        translationAnimation.fillMode = .forwards
        translationAnimation.isRemovedOnCompletion = false
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = angle * CGFloat.pi / 180
        rotationAnimation.duration = 1
        
        let cardView = topCardView
        topCardView = cardView?.nextCardView
        
        CATransaction.setCompletionBlock {
            cardView?.removeFromSuperview()
        }
        
        // Apply animation to the view
        cardView?.layer.add(translationAnimation, forKey: "translation")
        cardView?.layer.add(rotationAnimation, forKey: "rotation")
        
        CATransaction.commit()
    }
    
    @objc fileprivate func handleDislike() {
        saveSwipeToFirestore(didLike: 0)
        performSwipeAnimation(translation: -700, angle: -15)
    }
    
    @objc fileprivate func handleLike() {
        saveSwipeToFirestore(didLike: 1)
        performSwipeAnimation(translation: 700, angle: 15)
    }
    
    @objc fileprivate func handleMessages() {
        let matchesMessagesController = MatchesMessagesController()
        navigationController?.pushViewController(matchesMessagesController, animated: true)
    }
    
    fileprivate func saveSwipeToFirestore(didLike: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        guard let cardUID = topCardView?.cardViewModel?.uid else { return }
        
        let documentData = [cardUID: didLike]
        
        Firestore.firestore().collection("swipes").document(uid).getDocument { (snapshot, error) in
            if let error = error {
                print("Failed to fetch swipe data", error)
                return
            }
            
            // we cannot update the document unless we have set the document before.
            if snapshot?.exists == true {
                Firestore.firestore().collection("swipes").document(uid).updateData(documentData) { (error) in
                    if let error = error {
                        print("Failed to save swipe data", error)
                        return
                    }
                    
                    print("Successfully saved swiped")
                    if didLike == 1 {
                        self.checkIfMatchExists(cardUid: cardUID)
                    }
                }
            } else {
                Firestore.firestore().collection("swipes").document(uid).setData(documentData) { (error) in
                    if let error = error {
                        print("Failed to save swipe data", error)
                        return
                    }
                    
                    print("Successfully saved swiped")
                    if didLike == 1 {
                        self.checkIfMatchExists(cardUid: cardUID)
                    }
                }
            }
        }
    }
    
    fileprivate func checkIfMatchExists(cardUid: String) {
        Firestore.firestore().collection("swipes").document(cardUid).getDocument { (snapshot, error) in
            if let error = error {
                print("Failed to fetch document for card user", error)
                return
            }
            
            guard let data = snapshot?.data() else { return }
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            let hasMatched = data[uid] as? Int == 1
            if hasMatched {
                self.presentMatchView(cardUid: cardUid)
                
                guard let cardUser = self.users[cardUid] else { return }
                
                let data = ["name": cardUser.name ?? "", "profileImageUrl": cardUser.imageUrl1 ?? "", "uid": cardUid, "timestamp": Timestamp(date: Date())] as [String : Any]
                
                Firestore.firestore().collection("matches_messages").document(uid).collection("matches").document(cardUid).setData(data) { (error) in
                    if let error = error {
                        print("Failed to save match info:", error)
                    }
                }
                
                guard let currentUser = self.user else { return }
                
                let otherMatchData = ["name": currentUser.name ?? "", "profileImageUrl": currentUser.imageUrl1 ?? "", "uid": cardUid, "timestamp": Timestamp(date: Date())] as [String : Any]
                
                Firestore.firestore().collection("matches_messages").document(cardUid).collection("matches").document(uid).setData(otherMatchData) { (error) in
                    if let error = error {
                        print("Failed to save match info:", error)
                    }
                }
            }
        }
    }
    
    fileprivate func presentMatchView(cardUid: String) {
        let matchView = MatchView()
        matchView.cardUID = cardUid
        matchView.currentUser = self.user
        view.addSubview(matchView)
        matchView.fillSuperview()
    }
    
    @objc fileprivate func handleRefresh() {
        cardsDeckView.subviews.forEach({$0.removeFromSuperview()})
        fetchUserFromFirestore()
    }
    
    fileprivate func fetchUserFromFirestore() {
        
        let minAge = user?.minSeekingAge ?? SettingsController.defaultMinSeekingAge
        let maxAge = user?.maxSeekingAge ?? SettingsController.defaultMaxSeekingAge
        
        let query = Firestore.firestore().collection("users").whereField("age", isGreaterThanOrEqualTo: minAge).whereField("age", isLessThanOrEqualTo: maxAge).limit(to: 10)
        
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
                
                self.users[user.uid ?? ""] = user
                
                let isNotCurrentUser = user.uid != Auth.auth().currentUser?.uid
                
//                let hasNotSwipedBefore = self.swipes[user.uid!] == nil
                
                let hasNotSwipedBefore = true
                
                if isNotCurrentUser && hasNotSwipedBefore{
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
    
    var users = [String: User]()
    
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
    
    func didLogout() {
        cardsDeckView.subviews.forEach({$0.removeFromSuperview()})
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
