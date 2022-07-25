//
//  VJUIWindowExt.swift
//  PlayerDemo
//
//  Created by Ethan on 2022/7/19.
//

import Foundation
import UIKit

internal extension UIWindow {
    
    static func isLandscape() -> Bool {
        if #available(iOS 13, *) {

            let windowScene = UIApplication.shared.connectedScenes
                .compactMap{$0 as? UIWindowScene}
                .filter{$0.activationState == .foregroundActive}
                .first
            if let window = windowScene {
                return window.interfaceOrientation.isLandscape
            }
            return false
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

// UIImage的扩展
internal extension UIImage {
    
    static func resource(_ name : String , Dir dir : String? = nil) -> UIImage?{

        let bundlePath = Bundle.pathForResource(name, Dir: dir)
        guard  let image = UIImage(contentsOfFile: bundlePath) else {
            print("-----找不到您要找的图片 \(bundlePath)----【imageName:@\"\(name)\"】")
            return nil
        }
        
        return image
    }
    
    static func imageWithASName(_ nameStr : String , SubPath subPath : String = "resource", ImageType imageType : String = "png", BundleName bundleName : String = "Resource") -> UIImage?{

        
        
        guard let bundlePath = Bundle.main.path(forResource: bundleName, ofType: "bundle") else {
            print("bundle 不存在！！！")
            return nil
        }
    
        let imagePath = "\(bundlePath)/\(subPath)/\(nameStr).\(imageType)"
        
        return UIImage.init(named: imagePath)
    }
    
    static func imageWithASName(_ nameStr : String , SubPath subPath : String = "resource", ImageType imageType : String = "png") -> UIImage?{
        return UIImage.imageWithASName(nameStr, SubPath: subPath, ImageType: imageType, BundleName: "Resource")
    }
    
    
    static func imageWithASName(_ nameStr : String ) -> UIImage?{
        return UIImage.imageWithASName(nameStr, SubPath: "resource", ImageType: "png", BundleName: "Resource")
    }
    
}

internal extension Bundle{
    private static let bundleName = "Resource"
    
    static func userBundle() -> String{
        return Bundle.main.path(forResource: bundleName, ofType: "bundle")!
    }
    
    static func pathForResource(_ name : String , Dir dir : String? = nil) -> String{
        
        guard let dirStr = dir else {
            if name.hasSuffix(".jpg"){
                return Bundle.userBundle().appending("/\(name)")
            }
            return Bundle.userBundle().appending("/\(name).png")
        }
        if name.hasSuffix(".jpg"){
            return Bundle.userBundle().appending("/\(dirStr)/\(name)")
        }
        return Bundle.userBundle().appending("/\(dirStr)/\(name).png")
    }
}
