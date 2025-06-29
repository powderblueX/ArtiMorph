import SwiftUI

struct SelectionFrameView: View {
    // 依赖注入 ViewModel
    @ObservedObject var viewModel: SelectionFrameViewModel
    
    // 回调函数
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    // 调整大小的状态（局部 UI 状态，不涉及业务逻辑）
    @State private var currentCorner: SelectionCorner?
    @State private var dragOffset: CGSize = .zero
    @State private var initialFrame: CGRect = .zero
    
    var body: some View {
        if viewModel.state.isActive {
            ZStack {
                // 半透明背景
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { onCancel() }
                
                // 选择框
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
                    .background(Color.white.opacity(0.1))
                    .frame(width: viewModel.state.frame.width, height: viewModel.state.frame.height)
                    .position(x: viewModel.state.frame.midX, y: viewModel.state.frame.midY)
                    .gesture(dragGesture)
                
                // 控制点
                VStack {
                    HStack {
                        cornerControl(.topLeading)
                        Spacer()
                        cornerControl(.topTrailing)
                    }
                    Spacer()
                    HStack {
                        cornerControl(.bottomLeading)
                        Spacer()
                        cornerControl(.bottomTrailing)
                    }
                }
                .frame(width: viewModel.state.frame.width, height: viewModel.state.frame.height)
                .position(x: viewModel.state.frame.midX, y: viewModel.state.frame.midY)
                
                // 取消按钮
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                        .font(.system(size: 24))
                }
                .position(x: viewModel.state.frame.minX - 15, y: viewModel.state.frame.minY - 15)
                
                // 确认按钮
                Button(action: onConfirm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.mint)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                        .font(.system(size: 24))
                }
                .position(x: viewModel.state.frame.maxX + 15, y: viewModel.state.frame.minY - 15)
            }
        }
    }
    
    // MARK: - UI 组件
    private func cornerControl(_ corner: SelectionCorner) -> some View {
        Circle()
            .frame(width: 20, height: 20)
            .foregroundColor(.white)
            .border(Color.blue, width: 2)
            .gesture(resizeGesture(for: corner))
    }
    
    // MARK: - 手势逻辑
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if initialFrame == .zero {
                    initialFrame = viewModel.state.frame
                }
                viewModel.dragFrame(translation: value.translation, initialFrame: initialFrame)
            }
            .onEnded { _ in
                initialFrame = .zero
            }
    }
    
    private func resizeGesture(for corner: SelectionCorner) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if initialFrame == .zero {
                    initialFrame = viewModel.state.frame
                    currentCorner = corner
                }
                viewModel.resizeFrame(
                    corner: corner,
                    translation: value.translation,
                    initialFrame: initialFrame
                )
            }
            .onEnded { _ in
                initialFrame = .zero
                currentCorner = nil
            }
    }
}
