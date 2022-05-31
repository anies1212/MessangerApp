//
//  AppDelegate.swift
//  chatWithFBAppSample
//
//  Created by anies1212 on 2022/03/20.
//

// AppDelegate.swift
import UIKit
import FBSDKCoreKit
import Firebase
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(    _ application: UIApplication,didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        
        return true
    }
    
    
    
    func application(_ app: UIApplication,open url: URL,options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        return GIDSignIn.sharedInstance().handle(url)
    }
    
}

//MARK: -GIDSignInDelegate

extension AppDelegate: GIDSignInDelegate {
    //追記部分(デリゲートメソッド)エラー来た時
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error{
                print("Failed to sign In with Google:\(error)")
            }
            return
        }
        
        guard let user = user else {return}
        print("google user:\(user)")
        guard let email = user.profile.email,
              let userName = user.profile.name else {
                  return
              }
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set(userName, forKey: "name")
        DatabaseManager.shared.userExists(with: email) { exists in
            if !exists {
                let chatUser = ChatAppUser(userName: userName, emailAdress: email, birthDay: "")
                DatabaseManager.shared.insertUser(with: chatUser) { success in
                    if success {
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {return}
                            URLSession.shared.dataTask(with: url) { data, _, _ in
                                guard let data = data else {return}
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                    switch result {
                                    case .success(let downloadURL):
                                        UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                        print(downloadURL)
                                    case .failure(let error):
                                        print("Storage manager error:\(error)")
                                    }
                                }
                            }.resume()
                        }
                        
                    }
                }
            }
        }
        
        guard let authentication = user.authentication else {
            print("Missing auth of google")
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        FirebaseAuth.Auth.auth().signIn(with: credential) { authResult, error in
            guard error == nil, authResult != nil else{
                print("google login error")
                return
            }
            print("successfully sign in with email")
            NotificationCenter.default.post(name: .didLoginNotification, object: nil)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user was disconnected")
    }
}
