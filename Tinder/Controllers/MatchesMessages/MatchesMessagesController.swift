//
//  MatchesMessagesController.swift
//  Tinder
//
//  Created by horkimlong on 28/6/21.
//

import UIKit
import LBTATools
import FirebaseFirestore
import FirebaseAuth

struct RecentMessage {
    let text: String
    let uid: String
    let name: String
    let profileImageUrl: String
    let timestamp: Timestamp
    
    init(dictionary: [String: Any]) {
        self.text = dictionary["text"] as? String ?? ""
        self.uid = dictionary["uid"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? ""
        self.timestamp = dictionary["timestamp"] as? Timestamp ?? Timestamp(date: Date())
    }
}

class RecentMessageCell: LBTAListCell<RecentMessage> {
    
    let userProfileImageView = UIImageView(image: #imageLiteral(resourceName: "jane1"), contentMode: .scaleAspectFill)
    let usernameLabel = UILabel(text: "Username", font: .boldSystemFont(ofSize: 18))
    let messageTextLabel = UILabel(text: "Some long line of text that should span 2 lines", font: .systemFont(ofSize: 16), numberOfLines: 2)
    
    override var item: RecentMessage! {
        didSet {
            usernameLabel.text = item.name
            messageTextLabel.text = item.text
            userProfileImageView.sd_setImage(with: URL(string: item.profileImageUrl))
        }
    }
    
    override func setupViews() {
        super.setupViews()
        
        userProfileImageView.layer.cornerRadius = 94 / 2
        
        hstack(userProfileImageView.withWidth(94).withHeight(94),
               stack(usernameLabel, messageTextLabel, spacing: 2),
               spacing: 20,
               alignment: .center
        ).padLeft(20).padRight(20)
        
        addSeparatorView(leadingAnchor: usernameLabel.leadingAnchor)
    }
}

class MatchesMessagesController: LBTAListHeaderController<RecentMessageCell, RecentMessage, MatchesHeader>, UICollectionViewDelegateFlowLayout {
    
    let customNavBar = MatchesNavBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        items = [
//            .init(text: "Some random messages that I'll use for each recent message cell", uid: "Black", name: "Big burger", profileImageUrl: "https://firebasestorage.googleapis.com/v0/b/tinder-2be8f.appspot.com/o/images%2F12CBE4B1-3376-4AF1-870F-09929E39BB73?alt=media&token=8e6733f7-56f8-4b31-814a-d0414f6269cc", timestamp: .init(date: Date())),
//            .init(text: "Some random messages that I'll use for each recent message cell", uid: "Black", name: "Big burger", profileImageUrl: "https://firebasestorage.googleapis.com/v0/b/tinder-2be8f.appspot.com/o/images%2F12CBE4B1-3376-4AF1-870F-09929E39BB73?alt=media&token=8e6733f7-56f8-4b31-814a-d0414f6269cc", timestamp: .init(date: Date())),
//            .init(text: "Some random messages that I'll use for each recent message cell", uid: "Black", name: "Big burger", profileImageUrl: "https://firebasestorage.googleapis.com/v0/b/tinder-2be8f.appspot.com/o/images%2F12CBE4B1-3376-4AF1-870F-09929E39BB73?alt=media&token=8e6733f7-56f8-4b31-814a-d0414f6269cc", timestamp: .init(date: Date()))
//        ]
        setupUI()
        fetchRencentMessages()
    }
    
    var recentMessagesDictionary = [String: RecentMessage]()
    
    fileprivate func fetchRencentMessages() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("matches_messages").document(currentUserId).collection("recent_messages").addSnapshotListener { (querySnaphot, error) in
            if let error = error {
                print("Failed to fetch recent messages", error)
                return
            }
            
            querySnaphot?.documentChanges.forEach({ (change) in
                
                if change.type == .added || change.type == .modified {
                    let dictionary = change.document.data()
                    let recentMessage = RecentMessage(dictionary: dictionary)
                    self.recentMessagesDictionary[recentMessage.uid] = recentMessage
                }
            })
            
            self.resetItems()
        }
    }
    
    fileprivate func resetItems() {
        let values = Array(recentMessagesDictionary.values)
        items = values.sorted(by: { (rm1, rm2) -> Bool in
            return rm1.timestamp.compare(rm2.timestamp) == .orderedDescending
        })
        collectionView.reloadData()
    }
    
    fileprivate func setupUI() {
        collectionView.backgroundColor = .white
        
        customNavBar.backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        view.addSubview(customNavBar)
        customNavBar.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, size: .init(width: 0, height: 150))
        
        collectionView.contentInset.top = 150
        
        // for indicator bar to start from that position
        collectionView.scrollIndicatorInsets.top = 150
        
        let statusBarCover = UIView(backgroundColor: .white)
        view.addSubview(statusBarCover)
        
        statusBarCover.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, trailing: view.trailingAnchor)
    }
    
    @objc fileprivate func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: 0, bottom: 16, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width, height: 130)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func setupHeader(_ header: MatchesHeader) {
        header.matchesHorizontalController.rootMatchesController = self
    }
    
    func didSelectMatchFromHeader(match: Match) {
        let chatLogController = ChatLogController(match: match)
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .init(width: view.frame.width, height: 250)
    }
}
