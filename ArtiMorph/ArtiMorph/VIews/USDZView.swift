//
//  USDZView.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/3.
//

import SwiftUI
import RealityKit
import QuickLook
import ARKit

struct USDZView: UIViewControllerRepresentable {
    let modelFile: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> USDZViewCoordinator {
        USDZViewCoordinator(self)
    }
}
