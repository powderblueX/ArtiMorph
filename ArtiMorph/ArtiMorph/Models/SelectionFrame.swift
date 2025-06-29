//
//  SelectionFrame.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/28.
//

import Foundation

// 选择框的角落类型
enum SelectionCorner {
    case topLeading, topTrailing, bottomLeading, bottomTrailing
}

// 选择框的状态模型
struct SelectionFrameState {
    var frame: CGRect
    var isActive: Bool
    var minSize: CGFloat = 100
}
