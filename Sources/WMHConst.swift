//
//  WMHConst.swift
//  WMHPhotoSDK
//
//  Created by Archer on 2020/10/12.
//

import Foundation
import UIKit

//正常字号
func WMHFont(fontSize: CGFloat) -> UIFont {
    return UIFont.systemFont(ofSize: fontSize)
}

//加粗字号
func WMHBoldFont(fontSize: CGFloat) -> UIFont {
    return UIFont.boldSystemFont(ofSize: fontSize)
}

var isFullScreen: Bool {
    if #available(iOS 11, *) {
        guard let w = UIApplication.shared.delegate?.window, let unwrapedWindow = w else {
            return false
        }

        if unwrapedWindow.safeAreaInsets.left > 0 || unwrapedWindow.safeAreaInsets.bottom > 0 {
#if DEBUG
            print(unwrapedWindow.safeAreaInsets)
#endif
            return true
        }
    }
    return false
}

let WMHScreenWidth: CGFloat = UIScreen.main.bounds.size.width
let WMHScreenHeight: CGFloat = UIScreen.main.bounds.size.height
let WMHStatusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
let WMHNavigationBarHeight: CGFloat = isFullScreen == true ? 88.0 : 64.0
let WMHSafeAreaBottomHeight: CGFloat = isFullScreen == true ? 34.0 : 0.0


