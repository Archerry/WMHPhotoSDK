//
//  UIColor.swift
//  WMHPhotoSDK
//
//  Created by Archer on 2020/12/15.
//

import UIKit

@inline(__always)
private func to(_ value: UInt32) -> CGFloat {
    CGFloat(value) / CGFloat(255.0)
}

extension UIColor {
    @objc
    public convenience init(argb: UInt32) {
        let value = argb < 0xFFFF_FFFF ? argb : 0xFFF_FFFFF
        let a: UInt32 = (value > 0x00FF_FFFF) ? ((value & 0xFF00_0000) >> 24) : 0xFF
        let r: UInt32 = (value & 0x00FF_0000) >> 16
        let g: UInt32 = (value & 0x0000_FF00) >> 8
        let b: UInt32 = (value & 0x0000_00FF)
        self.init(red: to(r), green: to(g), blue: to(b), alpha: to(a))
    }

    @objc
    public convenience init(rgb: UInt32, alpha: CGFloat) {
        let value = rgb < 0x00FF_0000 ? rgb : 0x00FF_0000
        let r: UInt32 = (value & 0x00FF_0000) >> 16
        let g: UInt32 = (value & 0x0000_FF00) >> 8
        let b: UInt32 = (value & 0x0000_00FF)
        self.init(red: to(r), green: to(g), blue: to(b), alpha: alpha)
    }

    @objc
    public convenience init(_ value: String) {
        let range = value.range(of: "#") ?? value.range(of: "0x") ??
            value.range(of: "0X")
        let raw: UInt32?
        if let r = range {
            raw = r.lowerBound == value.startIndex ?
                UInt32(value[r.upperBound...], radix: 16) :
                nil // 非开头，非法输入
        } else {
            raw = UInt32(value, radix: 16)
        }
        self.init(argb: raw ?? 0)
    }
}

