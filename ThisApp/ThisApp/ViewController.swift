//
//  ViewController.swift
//  ThisApp
//
//  Created by Alex Johnson on 17/10/2016.
//  Copyright © 2016 scn. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class ViewController: UIViewController, FBSDKLoginButtonDelegate {
    


    
    let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let loginButton: FBSDKLoginButton = {
        let button = FBSDKLoginButton()
        button.readPermissions = ["email"]
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let showFriendsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Show Friends", for: UIControlState())
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        button.setTitleColor(UIColor.black, for: UIControlState())
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        navigationController?.navigationBar.isTranslucent = false
        
        view.backgroundColor = UIColor.white
        navigationItem.title = "Facebook Login"
        
        
        setupSubviews()
        
        if let _ = FBSDKAccessToken.current() {
            showFriendsButton.isHidden = false
            fetchProfile()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupSubviews() {
        view.addSubview(loginButton)
        view.addSubview(userImageView)
        view.addSubview(nameLabel)
        view.addSubview(showFriendsButton)
        showFriendsButton.isHidden = true
        
        showFriendsButton.addTarget(self, action: #selector(ViewController.showFriends), for: .touchUpInside)
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": userImageView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nameLabel]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-80-[v0]-80-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": showFriendsButton]))
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-80-[v0]-80-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": loginButton]))
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[v0(100)]-8-[v1(30)]-8-[v2(50)]-8-[v3(44)]", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": userImageView, "v1": nameLabel, "v2": loginButton, "v3": showFriendsButton]))
        
        loginButton.delegate = self
    }
    
    func showFriends() {
        let parameters = ["fields": "name,picture.type(normal),gender"]
        FBSDKGraphRequest(graphPath: "me/taggable_friends", parameters: parameters).start(completionHandler: { (connection, user, requestError) -> Void in
            if requestError != nil {
                print(requestError)
                return
            }
            
            var friends = [Friend]()
            let userDictionary = user as! [String: Any]
            for friendDictionary in userDictionary["data"] as! [[String:Any]] {
                let name = friendDictionary["name"] as? String
                var pictureDictionary = friendDictionary["picture"] as? [String : Any]
                var pictureData = pictureDictionary?["data"] as? [String : Any]
                if let picture = pictureData?["url"] as? String{
                    let friend = Friend(name: name, picture: picture)
                    friends.append(friend)
                }
            }
            
            let friendsController = FriendsController(collectionViewLayout: UICollectionViewFlowLayout())
            friendsController.friends = friends
            self.navigationController?.pushViewController(friendsController, animated: true)
            self.navigationController?.navigationBar.tintColor = UIColor.white
        })
    }
    
   
    func fetchProfile() {
        let parameters = ["fields": "email, first_name, last_name, picture.type(large)"]
        FBSDKGraphRequest(graphPath: "me", parameters: parameters).start(completionHandler: { (connection, user, requestError) -> Void in
            
            if requestError != nil {
                print(requestError)
                return
            }
            
            let userDictionary = user as! [String: Any]
            var _ = userDictionary["email"] as? String
            let firstName = userDictionary["first_name"] as! String
            let lastName = userDictionary["last_name"] as! String
            
            self.nameLabel.text = "\(firstName) \(lastName)"
            
            var pictureUrl = ""
            
            if let picture = userDictionary["picture"] as? NSDictionary, let data = picture["data"] as? NSDictionary, let url = data["url"] as? String {
                pictureUrl = url
            }
            
            let url = URL(string: pictureUrl)
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) -> Void in
                if error != nil {
                    print(error)
                    return
                }
                
                let image = UIImage(data: data!)
                DispatchQueue.main.async(execute: { () -> Void in
                    self.userImageView.image = image
                })
                
            }).resume()
            
        })
    }
    
    
    /*!
     @abstract Sent to the delegate when the button was used to login.
     @param loginButton the sender
     @param result The results of the login
     @param error The error (if any) from the login
     */
    public func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if ((error) != nil)
        {
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
                showFriendsButton.isHidden = false
                fetchProfile()
            }
        }

    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        showFriendsButton.isHidden = true
    }
}

struct Friend {
    var name, picture: String?
}

extension UIView {
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
    }
}

