//
//  WMHBOTools.swift
//  WMHPhotoSDK
//
//  Created by Archer on 2020/10/12.
//

import Foundation
import UIKit

struct WMHBOTools {
    private init() {
        // Do nothing.
    }

    static let bundle: Bundle = {
        let raw = Bundle(for: WMHPhotoTool.self)
        let path = raw.path(forResource: "WMHPhotoAssets", ofType: "bundle")
        return path.flatMap(Bundle.init(path:)) ?? raw
    }()

    static func bundledImage(name: String) -> UIImage? {
        UIImage(named: name, in: bundle, compatibleWith: nil) ?? UIImage(named: name)
    }

    static func bundledXib(name: String) -> UINib {
        UINib(nibName: name, bundle: bundle)
    }
}
