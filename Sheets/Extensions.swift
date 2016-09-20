//
//  Extensions.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 21.08.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation

extension UIApplication {
    class func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}

extension String {
    /** Removes all of the leading and ending whitespaces from a string. */
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func stringByDeletingPathExtension() -> String {
        return (self as NSString).deletingPathExtension
    }
    
}
