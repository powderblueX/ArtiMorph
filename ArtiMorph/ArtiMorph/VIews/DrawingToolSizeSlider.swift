import SwiftUI

/// 绘画工具大小滑块视图
/// 用于调整绘画工具的大小
struct DrawingToolSizeSlider: View {
    @ObservedObject var drawingTool: DrawingTool
    var setDrawingToolSize: (CGFloat) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 显示当前工具名称和大小调节滑块
//            if drawingTool.selectedToolType.isDrawingTool {
//                Text(drawingTool.selectedToolType.name)
//                    .font(.headline)
//                    .foregroundColor(.primary)
//            }
            
            // 大小调节滑块
            HStack {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.blue)
                
                Slider(
                    value: Binding(
                        get: { self.drawingTool.width },
                        set: { self.setDrawingToolSize($0) }
                    ),
                    in: 1...20,
                    step: 0.5
                )
                .accentColor(.blue)
                
                Image(systemName: "circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            // 大小预览和数值显示
            HStack {
                Circle()
                    .fill(drawingTool.color)
                    .frame(width: drawingTool.width, height: drawingTool.width)
                
                Text(String(format: "%.1f", drawingTool.width))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}
