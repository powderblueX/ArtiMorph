//
//  CoordinateUtils.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/6.
//

import SwiftUI

extension CGRect {
    // 从屏幕坐标系转换到图像坐标系
    func toImageCoordinate(scale: CGFloat) -> CGRect {
        return CGRect(
            x: self.origin.x * scale,
            y: self.origin.y * scale,
            width: self.width * scale,
            height: self.height * scale
        )
    }
}

extension CGPoint {
    // 从视图坐标系转换到屏幕坐标系
    func toScreenCoordinate(in view: UIView) -> CGPoint {
        return view.convert(self, to: nil)
    }
}
