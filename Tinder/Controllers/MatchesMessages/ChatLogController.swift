//
//  ChatLogController.swift
//  Tinder
//
//  Created by horkimlong on 8/7/21.
//

import UIKit
import LBTATools
import FirebaseFirestore
import FirebaseAuth

class ChatLogController: LBTAListController<MessageCell, Message>, UICollectionViewDelegateFlowLayout {
    
    fileprivate lazy var customNavBar = MessagesNavBar(match: match)
    let navBarHeight: CGFloat = 120
    
    fileprivate let match: Match
    
    var currentUser: User?
    
    init(match: Match) {
        self.match = match
        super.init()
    }
    
    // input accessory view
    // -- start --
    
    lazy var customInputView: CustomInputAccessoryView = {
        let civ = CustomInputAccessoryView(frame: .init(x: 0, y: 0, width: view.frame.width, height: 50))
        civ.sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return civ
    }()
    
    @objc fileprivate func handleSend() {
        saveToFromMessages()
        saveToFromRecentMessages()
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return customInputView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // -- end --
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        
        collectionView.keyboardDismissMode = .interactive
        setupNavigationBar()
        setupUI()
        fetchMessages()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // tells you if it's being popped off the nav stack
        if isMovingToParent {
            listener?.remove()
        }
    }
    
    @objc fileprivate func handleKeyboardShow() {
        self.collectionView.scrollToItem(at: [0, items.count - 1], at: .bottom, animated: true)
    }
    
    var listener: ListenerRegistration?
    
    fileprivate func fetchMessages() {
        print("Fetching messages")
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let query = Firestore.firestore().collection("matches_messages").document(currentUserId).collection(match.uid).order(by: "timestamp")
        
        // Note: We use addSnapshotListener instead of getDocuments because we want to update collectionView whenever a new message get added to the firestore.
        
        // addSnapshotListener will be called whenever the data in firestore changed
        // getDocuments will be called once only
        
        listener = query.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Failed to fetch message:", error)
                return
            }
            
            querySnapshot?.documentChanges.forEach({ (change) in
                if change.type == .added {
                    let dictionary = change.document.data()
                    self.items.append(.init(dictionary: dictionary))
                }
            })
            
            self.collectionView.reloadData()
            self.collectionView.scrollToItem(at: [0, self.items.count - 1], at: .bottom, animated: true)
        }
        
//        query.getDocuments { (querySnapshot, error) in
//            if let error = error {
//                print("Failed to fetch message:", error)
//                return
//            }
//
//            querySnapshot?.documents.forEach({ (documentSnapshot) in
//                self.items.append(.init(dictionary: documentSnapshot.data()))
//            })
//
//            self.collectionView.reloadData()
//        }
    }
    
    fileprivate func setupUI() {
        collectionView.alwaysBounceVertical = true
        collectionView.scrollIndicatorInsets.top = navBarHeight
        customNavBar.backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        let statusBarCover = UIView(backgroundColor: .white)
        view.addSubview(statusBarCover)
        
        statusBarCover.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, trailing: view.trailingAnchor)
    }
    
    @objc fileprivate func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    fileprivate func saveToFromRecentMessages() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let data : [String: Any] = ["name": match.name,
                    "text": customInputView.textView.text ?? "",
                    "profileImageUrl": match.profileImageUrl,
                    "timestamp": Timestamp(date: Date()),
                    "uid": match.uid]
        
        Firestore.firestore().collection("matches_messages").document(currentUserId).collection("recent_messages").document(match.uid).setData(data) { (error) in
            if let error = error {
                print("Failed to save recent message:", error)
                return
            }
            
            print("Saved recent message")
        }
        
        // save the other direction
        
        guard let currentUser = currentUser else { return }
        let toData : [String: Any] = ["name": currentUser.name ?? "",
                                      "text": customInputView.textView.text ?? "",
                                      "profileImageUrl": currentUser.imageUrl1 ?? "",
                                      "timestamp": Timestamp(date: Date()),
                                      "uid": currentUser.uid ?? ""]
        
        Firestore.firestore().collection("matches_messages").document(match.uid).collection("recent_messages").document(currentUserId).setData(toData) { (error) in
            if let error = error {
                print("Failed to save recent message:", error)
                return
            }
            
            print("Saved recent message")
        }
    }
    
    fileprivate func saveToFromMessages() {
        guard let text = customInputView.textView.text else { return }
        if text != "" {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            
            let data = ["text": text,
                        "fromId": currentUserId,
                        "toId": match.uid,
                        "timestamp": Timestamp(date: Date())
            ] as [String: Any]
            
            let collection = Firestore.firestore().collection("matches_messages").document(currentUserId).collection(match.uid)
            
            collection.addDocument(data: data) { (error) in
                if let error = error {
                    print("Failed to save message:", error)
                    return
                }
                
                print("Succesfully saved msg into Firestore")
                self.customInputView.textView.text = nil
                self.customInputView.placeholderLabel.isHidden = false
            }
            
            let toCollection = Firestore.firestore().collection("matches_messages").document(match.uid).collection(currentUserId)
            
            toCollection.addDocument(data: data) { (error) in
                if let error = error {
                    print("Failed to save message:", error)
                    return
                }
                
                print("Succesfully saved msg into Firestore")
                self.customInputView.textView.text = nil
                self.customInputView.placeholderLabel.isHidden = false
            }
        }
    }
    
    fileprivate func setupNavigationBar() {
        view.addSubview(customNavBar)
        customNavBar.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, size: .init(width: 0, height: navBarHeight))
        
        collectionView.contentInset.top = navBarHeight
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 0, bottom: 16, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // estiated sizing
        let estimatedSizeCell = MessageCell(frame: .init(x: 0, y: 0, width: view.frame.width, height: 1000))
        estimatedSizeCell.item = self.items[indexPath.item]
        estimatedSizeCell.layoutIfNeeded()
        
        let estimatedSize = estimatedSizeCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 1000))
        
        return .init(width: view.frame.width, height: estimatedSize.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
