//
//  ARViewContainer.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/5.
//

import SwiftUI
import Combine
import RealityKit
import ARKit
import simd
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    @Binding var arView: ARView

    func makeUIView(context: Context) -> ARView {
        arView.automaticallyConfigureSession = false // 禁用自动配置
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        config.isLightEstimationEnabled = true
        
        // 启用调试选项
        arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        
        // 重置并运行会话
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

