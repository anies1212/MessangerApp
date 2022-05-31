//
//  ProfileViewModels.swift
//  chatWithFBAppSample
//
//  Created by anies1212 on 2022/04/02.
//

import Foundation


enum ProfileViewModelType {
    case info,logout
    
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() ->Void)?
}
