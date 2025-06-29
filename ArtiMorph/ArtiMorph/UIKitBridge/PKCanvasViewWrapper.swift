import SwiftUI
import PencilKit

/// PKCanvasView 的 SwiftUI 包装器
/// 负责将 UIKit 的 PKCanvasView 包装为 SwiftUI 视图
struct PKCanvasViewWrapper: UIViewRepresentable {
    // MARK: - 类型定义
    
    /// 触摸位置更新回调类型
    typealias LocationUpdateHandler = (CGPoint) -> Void
    /// 触摸结束回调类型
    typealias TouchEndedHandler = () -> Void
    
    // MARK: - 属性
    
    /// 画布视图绑定
    @Binding var canvasView: PKCanvasView
    /// 是否可绘制状态绑定
    @Binding var isDraw: Bool
    /// 主视图模型
    let viewModel: CanvasViewModel
    /// 位置更新回调
    let onLocationUpdate: LocationUpdateHandler
    /// 触摸结束回调
    let onTouchEnded: TouchEndedHandler
    
    // MARK: - UIViewRepresentable
    
    /// 创建并返回 UIView
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = self.canvasView
        canvasView.backgroundColor = .white
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        canvasView.tool = viewModel.drawingTool.currentTool // 设置初始工具
        
        // 添加缩放手势识别器
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(PKCanvasViewCoordinator.handlePinch(_:))
        )
        pinchGesture.delegate = context.coordinator
        canvasView.addGestureRecognizer(pinchGesture)
        
        // 添加平移手势（双指）
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(PKCanvasViewCoordinator.handlePan(_:))
        )
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = context.coordinator
        canvasView.addGestureRecognizer(panGesture)
                
        return canvasView
    }
    
    /// 更新 UIView
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.isUserInteractionEnabled = isDraw
        
        // 更新工具
        uiView.tool = viewModel.drawingTool.currentTool
    }
    
    /// 创建协调器
    func makeCoordinator() -> PKCanvasViewCoordinator {
        PKCanvasViewCoordinator(
            canvasView: canvasView,
            mainViewModel: viewModel,
            onLocationUpdate: onLocationUpdate,
            onTouchEnded: onTouchEnded
        )
    }
} 
