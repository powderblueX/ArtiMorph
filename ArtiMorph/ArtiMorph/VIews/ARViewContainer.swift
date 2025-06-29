// ARViewContainer.swift (核心修复)
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
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        Task { await loadModelAsync(arView: arView) }
        return arView
    }
    
    private func loadModelAsync(arView: ARView) async {
        do {
            let model = try await ModelEntity(contentsOf: modelURL)
            await MainActor.run {
                configureScene(arView: arView, model: model)
            }
        } catch {
            await MainActor.run {
                errorMessage = "模型加载失败: \(error.localizedDescription)"
            }
        }
    }
    
    @MainActor
    private func configureScene(arView: ARView, model: ModelEntity) {
        model.scale = [0.5, 0.5, 0.5]
        let anchor = AnchorEntity()
        anchor.addChild(model)
        
        #if targetEnvironment(simulator)
        configureSimulatorScene(arView: arView, anchor: anchor, model: model)
        #else
        configureDeviceScene(arView: arView, anchor: anchor, model: model)
        #endif
    }
    
    @MainActor
    private func configureSimulatorScene(arView: ARView, anchor: AnchorEntity, model: ModelEntity) {
        // 1. 创建带碰撞组件的相机控制实体
        let cameraControl = ModelEntity()
        cameraControl.components[CollisionComponent.self] = CollisionComponent(
            shapes: [.generateBox(size: [0.1, 0.1, 0.1])]
        )
        
        // 2. 添加相机到实体
        let camera = PerspectiveCamera()
        cameraControl.addChild(camera)
        
        // 3. 定位控制点
        let cameraPivot = AnchorEntity(world: .zero)
        cameraPivot.addChild(cameraControl)
        arView.scene.addAnchor(cameraPivot)
        
        // 4. 初始相机位置
        cameraControl.position = [0, 0, 2]
        camera.look(at: [0, 0, 0], from: [0, 0, 2], relativeTo: nil)
        
        // 5. 添加相机控制手势
        arView.installGestures(
            [.rotation, .translation],
            for: cameraControl
        )
        
        // 6. 配置模型交互 (关键部分)
        model.generateCollisionShapes(recursive: true)
        arView.installGestures(
            [.rotation, .translation, .scale],
            for: model
        )
        
        // 7. 添加模型
        arView.scene.addAnchor(anchor)
        arView.cameraMode = .nonAR
        
        // 8. 调试信息（可选）
        print("模拟器场景配置完成")
        //print("模型手势已启用: \(model.hasCollision)")
    }
    
    @MainActor
    private func configureDeviceScene(arView: ARView, anchor: AnchorEntity, model: ModelEntity) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        arView.session.run(config)
        
        model.generateCollisionShapes(recursive: true)
        arView.installGestures([.all], for: model)
        arView.scene.addAnchor(anchor)
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
