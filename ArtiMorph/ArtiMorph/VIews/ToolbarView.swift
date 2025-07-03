import SwiftUI

/// 工具栏视图
/// 显示所有可用的绘图工具按钮
struct ToolbarView: View {
    // MARK: - 属性
    
    /// 视图模型
    @ObservedObject var viewModel: CanvasViewModel
    /// 绘图工具
    @ObservedObject var drawingTool: DrawingTool
    
    init(viewModel: CanvasViewModel) {
        self.viewModel = viewModel
        self.drawingTool = viewModel.drawingTool
    }
    
    // MARK: - 视图主体
    
    var body: some View {
        HStack(spacing: 5) {
            // 绘图工具按钮组
            DrawingToolButtonView(drawingTool: drawingTool, toolType: .pen, setTool: { viewModel.drawingTool.setToolType($0) })
            DrawingToolButtonView(drawingTool: drawingTool, toolType: .pencil, setTool: { viewModel.drawingTool.setToolType($0) })
            DrawingToolButtonView(drawingTool: drawingTool, toolType: .marker, setTool: { viewModel.drawingTool.setToolType($0) })
            DrawingToolButtonView(drawingTool: drawingTool, toolType: .monoline, setTool: { viewModel.drawingTool.setToolType($0) })
            DrawingToolButtonView(drawingTool: drawingTool, toolType: .fountainPen, setTool: { viewModel.drawingTool.setToolType($0) })
            DrawingToolButtonView(drawingTool: drawingTool, toolType: .watercolor, setTool: { viewModel.drawingTool.setToolType($0) })
            DrawingToolButtonView(drawingTool: drawingTool, toolType: .crayon, setTool: { viewModel.drawingTool.setToolType($0) })
            DrawingToolButtonView(drawingTool: drawingTool, toolType: .lasso, setTool: { viewModel.drawingTool.setToolType($0) })
            
            // 橡皮擦工具
            EraserToolView(drawingTool: drawingTool) { newType in
                viewModel.drawingTool.setToolType(newType)
            }
        }
        .padding(.horizontal, 5)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
