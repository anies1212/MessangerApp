//
//  DatabaseManager.swift
//  chatWithFBAppSample
//
//  Created by anies1212 on 2022/03/21.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation
import MapKit

/// Manager Object to read in right data to real time firebase database.
final class DatabaseManager{
    ///Shared Instance of Class.
    public static let shared = DatabaseManager()
    private let database = Database.database().reference()
    private init(){}
    static func safeEmail(emailAdress: String) -> String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

//MARK: -Account Management
extension DatabaseManager{
    ///Checks if user exists for given email.
    ///Parameter
    ///-`email`:    Target email to be checked.
    ///-`completion`:    Async closure to return
    ///
    public func userExists(with email: String, completion: @escaping (Bool) -> Void){
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    ///Inserts New User to Database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "userName": user.userName,
            "birthDay":user.birthDay
        ]) {[weak self] error, _ in
            guard let strongSelf = self else {return}
            guard error == nil else{
                print("Failed to Write to DB.")
                completion(false)
                return
            }
            strongSelf.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String:String]] {
                    let newElement = [
                        ["name":user.userName, "email": user.safeEmail ]
                    ]
                    usersCollection.append(contentsOf: newElement)
                    
                    strongSelf.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                } else {
                    let newCollection: [[String:String]] = [
                        ["name":user.userName, "email": user.safeEmail ]
                    ]
                    strongSelf.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
            completion(true)
        }
    }
    ///Get all users from database.
    public func getAllUsers(completion: @escaping (Result<[[String:String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error{
        case failedToFetch

    }
    
}

extension DatabaseManager{
    ///Returns dictionary node at child path.
    public func getData(for path: String, completion: @escaping (Result<Any, Error>) -> Void){
        database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}


//MARK: -Sending Messages / Conversations
extension DatabaseManager {
    public func createNewConversations(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
        let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                print("User not found.")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationId = "conversation_\(firstMessage.messageId)"
            let newConversationData: [String:Any] = [
                "id": conversationId,
                "otherUserEmail": otherUserEmail,
                "latestMessage":[
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                    "name": name
                    
                ]
            ]
            
            let recipient_newConversationData: [String:Any] = [
                "id": conversationId,
                "otherUserEmail": safeEmail,
                "latestMessage":[
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                    "name": currentName
                    
                ]
            ]
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String:Any]] {
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }
            
            if let conversations = userNode["conversations"] as? [String:Any] {
                print("conversations:\(conversations)")
                userNode["conversations"] = newConversationData
                ref.setValue(userNode) {[weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationId: conversationId,name: name, firstMessage: firstMessage, completion: completion)
                }
            } else {
                userNode["conversations"] = [newConversationData]
                ref.setValue(userNode) {[weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationId: conversationId,name: name, firstMessage: firstMessage, completion: completion)
                }
            }
        }
    }
    
    private func finishCreatingConversation(conversationId: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
        
        let collectionMessage: [String:Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "senderEmail":currentUserEmail,
            "read":false,
            "name": name
        ]
        
        let value: [String:Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        database.child("\(conversationId)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }

    public func getAllConversations(for email:String, completion: @escaping (Result<[Conversation], Error>) -> Void){
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String, let otherUserEmail = dictionary["otherUserEmail"] as? String, let latestMessage = dictionary["latestMessage"] as? [String: Any], let date = latestMessage["date"] as? String, let isRead = latestMessage["is_read"] as? Bool, let message = latestMessage["message"] as? String, let name = latestMessage["name"] as? String else {
                    print("Still wrong")
                    return nil
                }
                let latestMessageObject = LatestMessage.init(date: date, text: message, isRead: isRead)
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            }
            completion(.success(conversations))
        }
    }
    
    public func getAllMessagesForConversations(with id: String, completion: @escaping (Result<[Message], Error>) -> Void){
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                print("12345")
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap { dictionary in
                guard let content = dictionary["content"] as? String, let name = dictionary["name"] as? String, let isRead = dictionary["read"] as? Bool,
                      let dateString = dictionary["date"] as? String, let messageId = dictionary["id"] as? String, let senderEmail = dictionary["senderEmail"] as? String, let type = dictionary["type"] as? String, let date = ChatViewController.dateFormatter.date(from: dateString) else {
                          print("Failed to get message dictinary")
                          return nil
                      }
                var kind: MessageKind?
                if type == "video" {
                    guard let videoUrl = URL(string: content), let placeholder = UIImage(systemName: "plus") else {return nil}
                    let media = Media(url: videoUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                } else if type == "photo" {
                    guard let imageUrl = URL(string: content), let placeholder = UIImage(systemName: "plus") else {return nil}
                    let media = Media(url: imageUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "location"{
                    let locationComponents = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponents[0]) ,
                          let latitude = Double(locationComponents[1]) else {return nil}
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                } else {
                    kind = .text(content)
                }
                guard let finalKind = kind else {return nil}
                let sender = Sender(senderId: senderEmail, displayName: name, photoURL: "")
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
            }
            print("what's wrong here?:\(messages)")
                completion(.success(messages))
        }
    }
    
    public func sendMessage(to conversation: String, name: String, otherUserEmail: String, newMessage: Message, completion: @escaping (Bool) -> Void){
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {return}
        let currentEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) {[weak self] snapshot in
            guard let strongSelf = self else {return}
            guard var currentMessages = snapshot.value as? [[String:Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
            
            let newMessageEntry: [String:Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "senderEmail":currentUserEmail,
                "read":false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    var databaseEntryConversation = [[String: Any]]()
                    let updatedValue: [String: Any] = [
                        "date":dateString,
                        "message": message,
                        "is_read": false,
                        "name": name
                    ]
                    if var currentUserConversations = snapshot.value as? [[String:Any]]{
                        
                        ///Takes care when user dose not have any conversations
                        var targetConversation:[String:Any]?
                        var position = 0
                        for conversationDictionary in currentUserConversations {
                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        
                        ///If we found it.
                        if var targetConversation = targetConversation {
                            targetConversation["latestMessage"] = updatedValue
                            currentUserConversations[position] = targetConversation
                            databaseEntryConversation = currentUserConversations
                        } else {
                            ///if we did not found it.
                            let newConversationData: [String:Any] = [
                                "id": conversation,
                                "otherUserEmail": DatabaseManager.safeEmail(emailAdress: otherUserEmail),
                                "latestMessage":updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversation = currentUserConversations
                        }
                    } else {
                        
                        ///Takes care when user have conversations
                        let newConversationData: [String:Any] = [
                            "id": conversation,
                            "otherUserEmail": DatabaseManager.safeEmail(emailAdress: otherUserEmail),
                            "latestMessage":updatedValue
                        ]
                        databaseEntryConversation = [newConversationData]
                    }
                    
                    ///Other user email
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversation) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            let updatedValue: [String: Any] = [
                                "date":dateString,
                                "message": message,
                                "is_read": false,
                                "name": name
                            ]
                            var databaseEntryConversation = [[String: Any]]()
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {return}
                            if var otherUserConversations = snapshot.value as? [[String:Any]]  {
                                var targetConversation:[String:Any]?
                                var position = 0
                                for conversationDictionary in otherUserConversations {
                                    if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                if var targetConversation = targetConversation {
                                    targetConversation["latestMessage"] = updatedValue
                                    otherUserConversations[position] = targetConversation
                                    databaseEntryConversation = otherUserConversations
                                } else {
                                    ///failed to find in currect collection
                                    let newConversationData: [String:Any] = [
                                        "id": conversation,
                                        "otherUserEmail": DatabaseManager.safeEmail(emailAdress: currentEmail),
                                        "name": currentName,
                                        "latestMessage":updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversation = otherUserConversations
                                }
                            } else {
                                ///current collection does not exist
                                let newConversationData: [String:Any] = [
                                    "id": conversation,
                                    "otherUserEmail": DatabaseManager.safeEmail(emailAdress: currentEmail),
                                    "name": currentName,
                                    "latestMessage":updatedValue
                                ]
                                databaseEntryConversation = [newConversationData]
                            }
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversation) { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        print("deleting conversations with ID")
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) { snapshot in
            if var conversations = snapshot.value as? [[String:Any]]{
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conversationId {
                        print("Found Conversations to delete")
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations) { error, _ in
                    guard error == nil else {
                        print("Failed to Deleted Conversations")
                        completion(false)
                        return
                    }
                    print("Deleted Conversations")
                    completion(true)
                }
            }
        }
    }
    
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void){
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAdress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAdress: senderEmail)
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
            guard let collection = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["otherUserEmail"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
    }
}

struct ChatAppUser {
    let userName: String
    let emailAdress: String
    let birthDay: String

    var safeEmail: String{
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}



