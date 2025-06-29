//
//  SelectionFrameViewModel.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/28.
//

import Foundation

class SelectionFrameViewModel: ObservableObject {
    // 发布状态，供 View 监听
    @Published var state: SelectionFrameState
    
    // 初始化
    init(frame: CGRect, isActive: Bool) {
        self.state = SelectionFrameState(frame: frame, isActive: isActive)
    }
    
    // 拖动选择框
    func dragFrame(translation: CGSize, initialFrame: CGRect) {
        state.frame = CGRect(
            x: initialFrame.origin.x + translation.width,
            y: initialFrame.origin.y + translation.height,
            width: initialFrame.width,
            height: initialFrame.height
        )
    }
    
    // 调整大小
    func resizeFrame(corner: SelectionCorner, translation: CGSize, initialFrame: CGRect) {
        var newFrame = initialFrame
        
        switch corner {
        case .topLeading:
            newFrame.origin.x = initialFrame.origin.x + translation.width
            newFrame.origin.y = initialFrame.origin.y + translation.height
            newFrame.size.width = max(state.minSize, initialFrame.width - translation.width)
            newFrame.size.height = max(state.minSize, initialFrame.height - translation.height)
        case .topTrailing:
            newFrame.origin.y = initialFrame.origin.y + translation.height
            newFrame.size.width = max(state.minSize, initialFrame.width + translation.width)
            newFrame.size.height = max(state.minSize, initialFrame.height - translation.height)
        case .bottomLeading:
            newFrame.origin.x = initialFrame.origin.x + translation.width
            newFrame.size.width = max(state.minSize, initialFrame.width - translation.width)
            newFrame.size.height = max(state.minSize, initialFrame.height + translation.height)
        case .bottomTrailing:
            newFrame.size.width = max(state.minSize, initialFrame.width + translation.width)
            newFrame.size.height = max(state.minSize, initialFrame.height + translation.height)
        }
        
        state.frame = newFrame
    }
}
