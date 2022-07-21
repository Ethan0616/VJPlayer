//
//  VJUIWindowExt.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/19.
//

import Foundation
import UIKit

extension UIWindow {
    
    static func isLandscape() -> Bool {
        if #available(iOS 13, *) {

            let windowScene = UIApplication.shared.connectedScenes
                .compactMap{$0 as? UIWindowScene}
                .filter{$0.activationState == .foregroundActive}
                .first
            return windowScene!.interfaceOrientation.isLandscape
        } else {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
    
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            let keyWindow : UIWindow  = UIApplication.shared.connectedScenes
                .map{$0 as? UIWindowScene}
                .compactMap{$0}
                .first?.windows.first ?? UIWindow(frame: UIScreen.main.bounds)
//            return UIApplication.shared.windows.first { $0.isKeyWindow }
            return keyWindow
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    
    static func isBangsScreen() ->Bool {
        let keyWindow = UIWindow.key
        return keyWindow!.safeAreaInsets.bottom > 0
    }
    
    static var safeBottom : CGFloat {
        return key?.safeAreaInsets.bottom ?? 0
    }
}
