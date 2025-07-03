//
//  ObjectModeCoordinator.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/4.
//

import Foundation
import RealityKit
import QuickLook
import ARKit

class ObjectModeCoordinator: NSObject, QLPreviewControllerDataSource {
    let parent: ObjectModeView
    
    init(_ parent: ObjectModeView) {
        self.parent = parent
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        // 使用 ARQuickLookPreviewItem
        return ARQuickLookPreviewItem(fileAt: parent.modelFile)
    }
}
