import SwiftUI
import PencilKit

/// PKCanvasView 的协调器
/// 负责处理 UIKit 相关的事件和代理方法
class PKCanvasViewCoordinator: NSObject, PKCanvasViewDelegate, UIGestureRecognizerDelegate {
    // MARK: - 属性
    
    /// 画布视图
    private let canvasView: PKCanvasView
    /// 主视图模型
    private let mainViewModel: CanvasViewModel
    /// 位置更新回调
    private let onLocationUpdate: PKCanvasViewWrapper.LocationUpdateHandler
    /// 触摸结束回调
    private let onTouchEnded: PKCanvasViewWrapper.TouchEndedHandler
    /// 上次触摸时间
    private var lastTouchTime: Date?
    /// 长按手势识别器
    private var longPressGesture: UILongPressGestureRecognizer?
    /// 选择完成后的清除定时器
    private var selectionClearTimer: Timer?
    
    // MARK: - 初始化方法
    
    /// 初始化协调器
    /// - Parameters:
    ///   - canvasView: 画布视图
    ///   - mainViewModel: 主视图模型
    ///   - onLocationUpdate: 位置更新回调
    ///   - onTouchEnded: 触摸结束回调
    init(
        canvasView: PKCanvasView,
        mainViewModel: CanvasViewModel,
        onLocationUpdate: @escaping PKCanvasViewWrapper.LocationUpdateHandler,
        onTouchEnded: @escaping PKCanvasViewWrapper.TouchEndedHandler
    ) {
        self.canvasView = canvasView
        self.mainViewModel = mainViewModel
        self.onLocationUpdate = onLocationUpdate
        self.onTouchEnded = onTouchEnded
        super.init()
        
        setupGesture()
    }
    
    // MARK: - 私有方法
    
    /// 设置手势识别器
    private func setupGesture() {
        // 平移手势（单指或双指）
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        canvasView.addGestureRecognizer(panGesture)
        
        // 缩放手势
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        canvasView.addGestureRecognizer(pinchGesture)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.numberOfTouches == 2 else { return }
        
        switch gesture.state {
        case .began:
            mainViewModel.currentGesture = .zoom
            mainViewModel.lastScale = mainViewModel.scale
        case .changed:
            let newScale = mainViewModel.lastScale * gesture.scale
            mainViewModel.scale = min(max(newScale, 0.5), 5.0) // 限制缩放范围
        case .ended, .cancelled:
            mainViewModel.currentGesture = .none
        default: break
        }
    }
    
    // MARK: - 手势处理方法

    /// 处理平移手势
    /// - Parameter gesture: 平移手势识别器
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        // 情况1：双指拖动 → 画布平移
        if gesture.numberOfTouches == 2 {
            switch gesture.state {
            case .began:
                mainViewModel.currentGesture = .pan
                mainViewModel.lastOffset = mainViewModel.offset
            case .changed:
                let translation = gesture.translation(in: canvasView)
                mainViewModel.offset = CGSize(
                    width: mainViewModel.lastOffset.width + translation.x,
                    height: mainViewModel.lastOffset.height + translation.y
                )
            case .ended, .cancelled:
                mainViewModel.currentGesture = .none
                mainViewModel.lastOffset = mainViewModel.offset
            default: break
            }
            return
        }
        
        // 情况2：单指 + 橡皮擦工具 → 位置跟踪
        if gesture.numberOfTouches == 1,
           case .eraser = mainViewModel.drawingTool.selectedToolType {
            let location = gesture.location(in: canvasView)
            switch gesture.state {
            case .began, .changed:
                onLocationUpdate(location)
            case .ended, .cancelled:
                onTouchEnded()
            default: break
            }
        }
    }
    
    // MARK: - PKCanvasViewDelegate
    
    
    // MARK: - UIGestureRecognizerDelegate
    
    /// 允许手势识别器与其他手势共存
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                          shouldReceive touch: UITouch) -> Bool {
        return true
    }
}
