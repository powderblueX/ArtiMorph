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
        
        // 1. 先同步配置AR会话
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        arView.session.run(config)
        
        // 2. 安全加载模型
        loadModelAsync(arView: arView)
        
        return arView
    }

    private func loadModelAsync(arView: ARView) {
        // 使用专门的内存队列处理资源加载
        let modelLoadingQueue = DispatchQueue(label: "com.artimorph.modelLoading", qos: .userInitiated)
        
        modelLoadingQueue.async {
            // 检查是否在模拟器环境
            #if targetEnvironment(simulator)
            DispatchQueue.main.async {
                self.errorMessage = "模拟器不支持3D模型加载\n请使用真机体验AR功能"
            }
            return
            #else
            do {
                // 3. 使用安全加载方式
                let asset = try Entity.load(contentsOf: self.modelURL)
                
                // 4. 确保材质操作在Metal兼容线程
                if let modelEntity = asset as? ModelEntity {
                    DispatchQueue.main.async {
                        var material = SimpleMaterial()
                        material.color = SimpleMaterial.BaseColor()
                        modelEntity.model?.materials = [material]
                    }
                }
                
                // 5. 主线程添加锚点
                DispatchQueue.main.async {
                    let anchor = AnchorEntity(world: [0, 0, -1])
                    anchor.children.append(asset) // 使用线程安全的添加方式
                    
                    // 延迟0.5秒确保场景就绪
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        arView.scene.addAnchor(anchor)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("模型加载致命错误: \(error)")
                    // 安全处理错误
                    arView.session.pause()
                    self.errorMessage = "模型加载失败，请尝试其他文件"
            }
        }
        #endif
    }
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
