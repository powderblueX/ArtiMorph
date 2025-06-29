//
//  ARViewContainer.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/29.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    let modelURL: URL
    @Binding var errorMessage: String?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        context.coordinator.arView = arView
        
        // 禁用所有高级渲染特性
        arView.renderOptions = [
            .disablePersonOcclusion,
            .disableDepthOfField,
            .disableMotionBlur
        ]
        
        // 基础配置
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.environmentTexturing = .none
        config.isLightEstimationEnabled = false
        
        // 异步加载模型
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let entity = try Entity.load(contentsOf: self.modelURL)
                
                // 强制使用简单材质
                if let modelEntity = entity as? ModelEntity {
                    let material = SimpleMaterial(color: .white, isMetallic: false)
                    modelEntity.model?.materials = [material]
                }
                
                DispatchQueue.main.async {
                    let anchor = AnchorEntity(world: [0, 0, -1]) // 固定位置
                    anchor.addChild(entity)
                    arView.scene.addAnchor(anchor)
                    
                    // 延迟启动AR会话
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        arView.session.run(config, options: [.resetTracking])
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "模型加载失败: \(error.localizedDescription)"
                    print("‼️ 详细错误: \(error)")
                }
            }
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        weak var arView: ARView?
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("AR Session Failed: \(error)")
        }
    }
}
