//
//  StorageManager.swift
//  chatWithFBAppSample
//
//  Created by anies1212 on 2022/03/23.
//

import Foundation
import FirebaseStorage
///Allows you to get fetch and upload files to firebase storage
final class StorageManager {
    static let shared = StorageManager()
    private init(){}
    private let storage = Storage.storage().reference()
    public typealias uploadPictureCompletion = (Result<String, Error>) -> Void
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping uploadPictureCompletion){
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard let strongSelf = self else {return}
            guard error == nil else{
                print("failed to upload picture to FB Storage")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            strongSelf.storage.child("images/\(fileName)").downloadURL(completion:{ url, error in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                let urlString = url.absoluteString
                print("download URL returned:\(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping uploadPictureCompletion){
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: {[weak self] metadata, error in
            guard let strongSelf = self else {return}
            guard error == nil else{
                print("failed to upload picture to FB Storage")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            strongSelf.storage.child("message_images/\(fileName)").downloadURL(completion:{ url, error in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                let urlString = url.absoluteString
                print("download URL returned:\(urlString)")
                completion(.success(urlString))
            })
        })
    }
    //Upload Video
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping uploadPictureCompletion){
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: {[weak self] metadata, error in
            guard error == nil else{
                print("failed to upload video to FB Storage")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion:{ url, error in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                let urlString = url.absoluteString
                print("download URL returned:\(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public enum StorageErrors: Error{
        case failedToUpload
        case failedToGetDownloadURL
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void){
        let refrence = storage.child(path)
        refrence.downloadURL { url, error in
            guard let url = url, error == nil else{
                completion(.failure(StorageErrors.failedToGetDownloadURL))
                return
            }
            completion(.success(url))
        }
        
    }
}
