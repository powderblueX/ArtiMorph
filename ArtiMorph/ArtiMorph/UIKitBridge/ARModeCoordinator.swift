//
//  ARModeCoordinator.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/3.
//

import Foundation
import ARKit
import RealityKit

class ARModeCoordinator: NSObject, ARCoachingOverlayViewDelegate, UIGestureRecognizerDelegate {
    var parent: ARModeView
    weak var arView: ARView?
    var modelEntity: ModelEntity?
    var anchor: AnchorEntity?
    var currentModel: ModelEntity?  // 当前操作的模型
    var isModelAnchored = false // 标记模型是否已固定
    
    // 手势交互临时状态
    var initialModelPosition: SIMD3<Float>?
    var lastPanLocation: simd_float4? // 改为存储世界坐标位置
    
    init(_ parent: ARModeView) {
        self.parent = parent
    }
    
    // ✅ 正确的异步加载方式
    func loadModel(from url: URL) async {
        do {
            let model = try await ModelEntity(contentsOf: url)
            await MainActor.run {
                model.scale = [0.5, 0.5, 0.5]
                self.modelEntity = model
                print("✅ 模型加载成功: \(url.lastPathComponent)")
            }
        } catch {
            print("❌ 模型加载失败: \(error)")
        }
    }
    
    // AR引导完成回调
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        print("平面检测完成，可以放置模型")
        coachingOverlayView.removeFromSuperview()
        
        guard let arView = arView,
              let model = modelEntity,
              let raycastResult = arView.raycast(from: arView.center,
                                                 allowing: .estimatedPlane,
                                                 alignment: .horizontal).first else {
            print("⚠️ 自动放置失败：未检测到平面或模型未加载")
            parent.showRetryButton = true
            return
        }

        // 移除旧锚点
        anchor?.removeFromParent()

        // 放置模型到检测到的平面
        let newAnchor = AnchorEntity(world: raycastResult.worldTransform)
        let modelClone = model.clone(recursive: true)
        modelClone.scale = [0.5, 0.5, 0.5]
        newAnchor.addChild(modelClone)

        arView.scene.addAnchor(newAnchor)
        self.anchor = newAnchor
        self.currentModel = modelClone
        parent.isModelPlaced = true
        parent.showRetryButton = false

        print("✅ 自动放置模型成功")
    }
    
    func retryPlaneDetection() {
        guard let arView = arView else { return }
        
        // 重新添加CoachingOverlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.frame = arView.bounds
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.delegate = self
        arView.addSubview(coachingOverlay)
        
        // 重置AR会话
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        config.isLightEstimationEnabled = true
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        parent.showRetryButton = false
        (parent).onRetry?() // 触发回调
    }

    // MARK: - 手势处理
    // 点击手势处理
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView,
              let _ = modelEntity else { return }
        
        let location = gesture.location(in: arView)
        
        // 检测平面
        let results = arView.raycast(from: location,
                                     allowing: .estimatedPlane,
                                     alignment: .horizontal)
        
        if let firstResult = results.first {
            placeModel(at: firstResult.worldTransform, in: arView)
        }
    }
    
    // 放置模型的通用方法
    private func placeModel(at transform: simd_float4x4, in arView: ARView) {
        guard let model = modelEntity else { return }
        
        // 移除旧锚点
        anchor?.removeFromParent()
        
        // 创建带物理特性的锚点
        let newAnchor = AnchorEntity(world: transform)
        newAnchor.anchoring = AnchoringComponent(AnchoringComponent.Target.plane(
            .horizontal,
            classification: .any,
            minimumBounds: [0.5, 0.5]
        ))
        
        let modelClone = model.clone(recursive: true)
        modelClone.scale = [0.5, 0.5, 0.5]
        
        // 高级物理设置
        let meshBounds = modelClone.visualBounds(relativeTo: nil)
        let shape = ShapeResource.generateBox(size: meshBounds.extents).offsetBy(
            translation: meshBounds.center
        )
        
        modelClone.components.set(PhysicsBodyComponent(
            shapes: [shape],
            mass: 1, // 微小质量比0更好
            material: .generate(friction: 1.0, restitution: 0.01),
            mode: .kinematic // 改为kinematic模式
        ))
        
        modelClone.components.set(CollisionComponent(
            shapes: [shape],
            mode: .default,
            filter: .default
        ))
        
        // 添加阴影接收器
        if #available(iOS 15.0, *) {
            modelClone.components.set(GroundingShadowComponent(castsShadow: true))
        }
        
        newAnchor.addChild(modelClone)
        arView.scene.addAnchor(newAnchor)
        
        // 添加平面可视化（调试用）
//        if let meshResource = try? MeshResource.generatePlane(width: 1, depth: 1) {
//            let planeMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.2), isMetallic: false)
//            let planeEntity = ModelEntity(
//                mesh: meshResource,
//                materials: [planeMaterial]
//            )
//            planeEntity.components[PhysicsBodyComponent.self] = nil
//            planeEntity.components[CollisionComponent.self] = nil
//            newAnchor.addChild(planeEntity)
//        }
        
        self.anchor = newAnchor
        self.currentModel = modelClone
        parent.isModelPlaced = true
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isModelAnchored, let arView = arView, let model = currentModel else { return }
        
        let location = gesture.location(in: arView)
        
        switch gesture.state {
        case .began:
            // 使用raycast获取初始位置
            if let result = arView.raycast(from: location,
                                          allowing: .estimatedPlane,
                                          alignment: .horizontal).first {
                initialModelPosition = model.position(relativeTo: nil)
                lastPanLocation = result.worldTransform.columns.3
            }
            
        case .changed:
            guard let initialPos = initialModelPosition,
                  let lastWorldPos = lastPanLocation else { return }
            
            // 使用raycast获取当前3D位置
            let results = arView.raycast(from: location,
                                       allowing: .estimatedPlane,
                                       alignment: .horizontal)
            
            if let firstResult = results.first {
                let currentWorldPos = firstResult.worldTransform.columns.3
                let delta = simd_make_float3(currentWorldPos) - simd_make_float3(lastWorldPos)
                
                // 应用平滑移动
                let newPosition = initialPos + delta
                model.setPosition(newPosition, relativeTo: nil)
                
                // 更新最后位置
                lastPanLocation = currentWorldPos
            }
            
        default:
            // 重置状态
            initialModelPosition = nil
            lastPanLocation = nil
        }
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let model = currentModel else { return }
        
        switch gesture.state {
        case .changed:
            // 应用缩放（限制在0.1-5.0倍之间）
            let newScale = model.scale * Float(gesture.scale)
            let clampedScale = simd_clamp(newScale, [0.1, 0.1, 0.1], [5.0, 5.0, 5.0])
            model.scale = clampedScale
            gesture.scale = 1.0  // 重置scale值
        default:
            break
        }
    }
    
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let model = currentModel else { return }
        
        switch gesture.state {
        case .changed:
            // 绕Y轴旋转
            let rotation = simd_quatf(angle: Float(gesture.rotation),
                                    axis: [0, 1, 0])
            model.orientation = rotation * model.orientation
            gesture.rotation = 0  // 重置rotation值
        default:
            break
        }
    }
    
    // MARK: - 手势冲突处理
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 允许旋转和缩放手势同时进行
        return (gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) ||
               (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer)
    }
}
