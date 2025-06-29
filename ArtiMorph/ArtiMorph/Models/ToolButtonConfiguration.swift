import SwiftUI

/// 工具按钮配置
/// 定义工具按钮的外观和状态
struct ToolButtonConfiguration {
    /// 图标名称
    let icon: String
    /// 按钮标题
    let title: String
    /// 是否选中
    var isSelected: () -> Bool
    
    init(
        icon: String,
        title: String,
        isSelected: @escaping () -> Bool
    ) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
    }
}
