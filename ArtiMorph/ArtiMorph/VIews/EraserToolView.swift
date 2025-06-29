import SwiftUI

/// 橡皮擦工具视图
/// 显示橡皮擦工具按钮和模式选择菜单
struct EraserToolView: View {
    @ObservedObject var drawingTool: DrawingTool
    var setTool: (DrawingToolType) -> Void
    
    var body: some View {
        Menu {
            Button(action: {
                setTool(.eraser(.pixel))
            }) {
                Label("像素擦除", systemImage: "square")
            }
            
            Button(action: {
                setTool(.eraser(.stroke))
            }) {
                Label("整笔擦除", systemImage: "scribble")
            }
        } label: {
            ToolButton(
                configuration: ToolButtonConfiguration(
                    icon: "eraser",
                    title: "橡皮擦",
                    isSelected: { return self.drawingTool.selectedToolType == .eraser(.pixel) || self.drawingTool.selectedToolType == .eraser(.stroke) }
                ),
                action: {
                    if case .eraser = drawingTool.selectedToolType {
                        setTool(.eraser(drawingTool.eraserMode))
                    } else {
                        setTool(.eraser(.pixel))
                    }
                }
            )
        }
    }
}