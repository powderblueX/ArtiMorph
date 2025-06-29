import SwiftUI

/// 橡皮擦大小指示器视图
/// 显示当前橡皮擦的大小和范围
struct EraserIndicatorView: View {
    // MARK: - 属性
    
    /// 橡皮擦大小
    let size: CGFloat
    
    // MARK: - 视图主体
    
    var body: some View {
        Circle()
            .stroke(Color.blue, lineWidth: 1)
            .frame(width: size, height: size)
    }
}

/// 橡皮擦大小滑块视图
/// 用于调整橡皮擦的大小
struct EraserSizeSlider: View {
    @ObservedObject var viewModel: CanvasViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // 显示当前模式
            if case .eraser(let mode) = viewModel.drawingTool.selectedToolType {
                Text(mode == .pixel ? "像素擦除" : "整笔擦除")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // 大小调节滑块
            HStack {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.blue)
                
                Slider(
                    value: Binding(
                        get: { self.viewModel.drawingTool.width },
                        set: { self.viewModel.setEraserSize($0) }
                    ),
                    in: 4...40,
                    step: 1.0
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
                    .stroke(Color.blue, lineWidth: 1)
                    .frame(width: viewModel.drawingTool.width, height: viewModel.drawingTool.width)
                
                Text("\(Int(viewModel.drawingTool.width))")
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

struct EraserModeView: View {
    @ObservedObject var drawingTool: DrawingTool
    
    var body: some View {
        VStack(spacing: 10) {
            Text("橡皮擦模式")
                .font(.headline)
            
            Button(action: {
                drawingTool.setEraserMode(.pixel)
            }) {
                VStack {
                    Image(systemName: "square")
                        .font(.system(size: 24))
                    Text("像素擦除")
                        .font(.caption)
                }
                .foregroundColor(drawingTool.eraserMode == .pixel ? .blue : .gray)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(drawingTool.eraserMode == .pixel ? Color.blue.opacity(0.2) : Color.clear)
                )
            }
            
            Button(action: {
                drawingTool.setEraserMode(.stroke)
            }) {
                VStack {
                    Image(systemName: "scribble")
                        .font(.system(size: 24))
                    Text("整笔擦除")
                        .font(.caption)
                }
                .foregroundColor(drawingTool.eraserMode == .stroke ? .blue : .gray)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(drawingTool.eraserMode == .stroke ? Color.blue.opacity(0.2) : Color.clear)
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
} 
