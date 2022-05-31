//
//  Extensions.swift
//  chatWithFBAppSample
//
//  Created by anies1212 on 2022/03/20.
//

import Foundation
import UIKit

extension UIView {
    public var width : CGFloat{
        return frame.size.width
    }
    
    public var height : CGFloat{
        return frame.size.height
    }
    
    public var top : CGFloat{
        return frame.origin.y
    }
    
    public var bottom : CGFloat{
        return frame.size.height + frame.origin.y
    }
    
    public var left : CGFloat{
        return frame.origin.x
    }
    
    public var right : CGFloat{
        return frame.size.width + frame.origin.x
    }
}

extension UIColor {
    public var defaultColor: UIColor{
        return UIColor(red: 71/255, green: 154/255, blue: 200/255, alpha: 1)
    }
}

extension Notification.Name {
    ///Notification when user logs in. 
    static let didLoginNotification = Notification.Name("didLoginNotification")
}
