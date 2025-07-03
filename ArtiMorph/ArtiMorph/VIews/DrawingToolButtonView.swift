import SwiftUI

/// 通用绘图工具按钮视图
/// 可通过配置参数创建不同类型的绘图工具按钮
struct DrawingToolButtonView: View {
    @ObservedObject var drawingTool: DrawingTool
    var toolType: DrawingToolType
    var setTool: (DrawingToolType) -> Void
    
    private var configuration: ToolButtonConfiguration {
        ToolButtonConfiguration(
            icon: toolType.iconName,
            title: toolType.name,
            isSelected: { self.drawingTool.selectedToolType == self.toolType }
        )
    }
    
    var body: some View {
        ToolButton(
            configuration: configuration,
            action: { setTool(toolType) }
        )
    }
}
