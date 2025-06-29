import SwiftUI

/// 工具按钮视图
/// 用于显示工具栏中的单个工具按钮
struct ToolButton: View {
    // MARK: - 属性
    
    /// 按钮配置
    let configuration: ToolButtonConfiguration
    /// 点击动作
    let action: () -> Void
    
    // MARK: - 视图主体
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: configuration.icon)
                    .font(.system(size: 24))
                    .foregroundColor(configuration.isSelected() ? .blue : .gray)
                
                Text(configuration.title)
                    .font(.caption)
                    .foregroundColor(configuration.isSelected() ? .blue : .gray)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(configuration.isSelected() ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
    }
}