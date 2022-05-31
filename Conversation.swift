//
//  Conversation.swift
//  chatWithFBAppSample
//
//  Created by anies1212 on 2022/03/24.
//

import Foundation


struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}
struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
    
}
