import SwiftUI
import PencilKit
import SceneKit
import UIKit

/// 主画布视图
/// 负责组织和展示画布界面的各个组件
struct CanvasView: View {
    // MARK: - 属性
    
    /// 画布数据
    let canvas: CanvasData
    /// 画布视图模型
    @StateObject var viewModel: CanvasViewModel
    /// 是否显示橡皮擦指示器
    @State private var showEraserIndicator = false
    /// 指示器位置
    @State private var indicatorPosition: CGPoint = .zero
    /// 是否显示清空确认对话框
    @State private var showClearConfirmation = false
    /// 是否显示缩放提示
    @State private var showZoomHint = false
    /// 新增状态控制展开/收起
    @State private var showSizeSlider = false
    @State private var showColorPicker = false
    
    // MARK: - 视图主体
    
    init(canvas: CanvasData) {
        self.canvas = canvas
        self._viewModel = StateObject(wrappedValue: CanvasViewModel(canvasData: canvas))
    }
    
    var body: some View {
        ZStack {
            // 画布层
            PKCanvasViewWrapper(
                canvasView: $viewModel.canvasView,
                isDraw: $viewModel.isDraw,
                viewModel: viewModel,
                onLocationUpdate: { location in
                    if case .eraser = viewModel.drawingTool.selectedToolType {
                        indicatorPosition = location
                        showEraserIndicator = true
                    }
                },
                onTouchEnded: {
                    showEraserIndicator = false
                }
            )
            .scaleEffect(viewModel.scale)
            .offset(viewModel.offset)
            .edgesIgnoringSafeArea(.all)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        guard viewModel.drawingTool.selectedToolType == .lasso else { return }
                        viewModel.scale = value
                    }
            )
            
            // 左上角操作按钮
            HStack(alignment: .center, spacing: 0) {
                // 第一组：操作按钮（左对齐）
                HStack(spacing: 15) {
                    Button(action: { viewModel.undo() }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .padding(1)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                    Button(action: { viewModel.redo() }) {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .padding(1)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                    Button(action: { showClearConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .padding(1)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                }
                
                Spacer()
                
                // 第二组：绘画工具（居中）
                HStack(spacing: 15) {
                    // 画笔选择器
                    ToolbarView(viewModel: viewModel)
                    
                    // 橡皮擦大小滑块
                    Button(action: {
                        withAnimation {
                            showSizeSlider.toggle()
                            // 确保颜色选择器关闭
                            showColorPicker = false
                        }
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .padding(1)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                    
                    // 颜色选择按钮（替换原来的颜色选择器）
                    Button(action: {
                        withAnimation {
                            showColorPicker.toggle()
                            // 确保大小滑块关闭
                            showSizeSlider = false
                        }
                    }) {
                        Image(systemName: "paintpalette")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .padding(1)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                }
                
                Spacer()
                
                // 第三组：3D转换（右对齐）
                HStack(spacing: 15) {
                    Button(action: { viewModel.isSelectionActive = true }) {
                        Image(systemName: "cube.transparent")
                            .font(.title)
                            .foregroundColor(.primary)
                            .padding(1)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // 在底部添加展开的面板
            VStack {
                Spacer()
                
                // 大小滑块面板
                if showSizeSlider {
                    VStack {
                        if case .eraser = viewModel.drawingTool.selectedToolType {
                            EraserSizeSlider(viewModel: viewModel)
                                .padding()
                        } else if viewModel.drawingTool.selectedToolType.isDrawingTool {
                            DrawingToolSizeSlider(drawingTool: viewModel.drawingTool) { size in
                                viewModel.drawingTool.setWidth(size)
                            }
                            .padding()
                        }
                    }
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .transition(.move(edge: .bottom))
                    .padding(.bottom, 20)
                }
                
                // 颜色选择器面板
                if showColorPicker {
                    ColorPickerView(
                        colors: viewModel.colors,
                        selectedColor: viewModel.drawingTool.color,
                        onColorSelected: { color in
                            viewModel.setColor(color)
                            // 可以选择自动关闭
                            // showColorPicker = false
                        }
                    )
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .transition(.move(edge: .bottom))
                    .padding(.bottom, 20)
                }
            }
            
            // 清空确认提示框
            if showClearConfirmation {
                CustomAlertView(
                    configuration: AlertConfiguration(
                        title: "确认清空",
                        message: "确定要清空当前画布吗？此操作不可撤销。",
                        primaryButtonTitle: "确定",
                        secondaryButtonTitle: "取消",
                        primaryAction: {
                            viewModel.clearCanvas()
                            showClearConfirmation = false
                        },
                        secondaryAction: {
                            showClearConfirmation = false
                        }
                    )
                )
            }
            
            // 橡皮擦指示器层
            if case .eraser(_) = viewModel.drawingTool.selectedToolType, showEraserIndicator {
                EraserIndicatorView(size: viewModel.drawingTool.width)
                    .position(indicatorPosition)
                    .allowsHitTesting(false)
            }
            
            // 2D->3D选择框
            SelectionFrameView(
                viewModel: viewModel.selectionFrameVM,
                onConfirm: viewModel.convert2DTo3D,
                onCancel: { viewModel.selectionFrameVM.state.isActive = false }
            )
            
            // 缩放提示
            if showZoomHint {
                ZoomHintView()
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(50)
                    .transition(.opacity)
            }
            
            if showClearConfirmation {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(10)
                
                CustomAlertView(
                    configuration: AlertConfiguration(
                        title: "清空画布",
                        message: "确定要清空当前画布吗？此操作不可撤销。",
                        primaryAction: {
                            viewModel.clearCanvas()
                            showClearConfirmation = false
                        },
                        secondaryAction: { showClearConfirmation = false }
                    )
                )
                .zIndex(20)
            }
        }
        .navigationBarTitle(canvas.name, displayMode: .inline)
        .onDisappear {
            viewModel.saveCanvas()
        }
    }
}

#Preview {
    CanvasView(canvas: CanvasData(name: "123", drawing: PKDrawing()))
}
