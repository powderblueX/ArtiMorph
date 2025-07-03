//
//  ARQuickLookView.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/3.
//

import SwiftUI
import RealityKit
import ARKit

struct ARModeView: UIViewRepresentable {
    let modelFile: URL
    @Binding var isModelPlaced: Bool
    @Binding var showRetryButton: Bool
    var onRetry: (() -> Void)? // 回调
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        
        // 启用环境光遮蔽和动态阴影
        arView.environment.sceneUnderstanding.options = [
            .occlusion,
            .receivesLighting
        ]
        
        arView.renderOptions = [
            .disableMotionBlur,
            .disableDepthOfField,
            .disableHDR
        ]
        
        // 添加AR引导视图
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.frame = arView.bounds
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.delegate = context.coordinator
        
        arView.addSubview(coachingOverlay)
        
        // 配置AR会话
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical] // 同时检测水平和垂直面
        config.environmentTexturing = .automatic // 自动环境纹理
        config.isAutoFocusEnabled = true
        
        arView.session.run(config)
        
        
        // 增强光照系统
        //setupEnhancedLighting(for: arView)
        
        // 添加所有手势识别器
        addGestureRecognizers(to: arView, context: context)
        
        context.coordinator.arView = arView
        
        // 异步加载模型
        Task {
            await context.coordinator.loadModel(from: modelFile)
        }
        
        return arView
    }
    
    private func setupEnhancedLighting(for arView: ARView) {
        // 1. 主定向光源（产生阴影）
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 2000
        directionalLight.light.color = .white
        
        if #available(iOS 15.0, *) {
            directionalLight.shadow = DirectionalLightComponent.Shadow(
                maximumDistance: 3.0,
                depthBias: 2.0
            )
        }
        
        directionalLight.orientation = simd_quatf(angle: -.pi/4, axis: [1, 0, 0])
        
        // 3. 将光源添加到场景
        let lightAnchor = AnchorEntity(world: .zero)
        lightAnchor.addChild(directionalLight)
        arView.scene.addAnchor(lightAnchor)
        
        // 4. 加载环境贴图（增强反射效果）
        if let envResource = try? EnvironmentResource.load(named: "studio") {
            arView.environment.lighting.resource = envResource
        }
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> ARModeCoordinator {
        ARModeCoordinator(self)
    }
    
    // 添加手势识别器
    private func addGestureRecognizers(to arView: ARView, context: Context) {
        // 1. 点击手势（放置/选中模型）
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // 2. 拖动手势（单指移动）
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(panGesture)
        
        // 3. 捏合手势（双指缩放）
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        // 4. 旋转手势（双指旋转）
        let rotationGesture = UIRotationGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)
        
        // 设置手势代理
        tapGesture.delegate = context.coordinator
        panGesture.delegate = context.coordinator
        pinchGesture.delegate = context.coordinator
        rotationGesture.delegate = context.coordinator
    }
}
