//
//  Simple3DViewer.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/5.
//

import SwiftUI
import SceneKit
import QuickLook

struct Simple3DViewer: UIViewControllerRepresentable {
    let modelURL: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: Simple3DViewer
        
        init(_ parent: Simple3DViewer) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.modelURL as QLPreviewItem
        }
        
        func previewController(_ controller: QLPreviewController, shouldOpen url: URL, for item: QLPreviewItem) -> Bool {
            return true
        }
    }
}
