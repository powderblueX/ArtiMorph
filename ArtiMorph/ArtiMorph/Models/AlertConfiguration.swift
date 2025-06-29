import SwiftUI

struct AlertConfiguration {
    let title: String
    let message: String?
    let primaryButtonTitle: String
    let secondaryButtonTitle: String
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    let content: AnyView?
    
    init(
        title: String,
        message: String? = nil,
        primaryButtonTitle: String = "确定",
        secondaryButtonTitle: String = "取消",
        primaryAction: @escaping () -> Void,
        secondaryAction: @escaping () -> Void,
        content: AnyView? = nil
    ) {
        self.title = title
        self.message = message
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.content = content
    }
} 