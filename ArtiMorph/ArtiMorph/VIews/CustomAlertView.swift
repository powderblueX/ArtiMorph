import SwiftUI
import PencilKit

struct CustomAlertView: View {
    let configuration: AlertConfiguration
    
    init(configuration: AlertConfiguration) {
        self.configuration = configuration
    }
    
    init<Content: View>(
        title: String,
        message: String? = nil,
        primaryButtonTitle: String = "确定",
        secondaryButtonTitle: String = "取消",
        primaryAction: @escaping () -> Void,
        secondaryAction: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.configuration = AlertConfiguration(
            title: title,
            message: message,
            primaryButtonTitle: primaryButtonTitle,
            secondaryButtonTitle: secondaryButtonTitle,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            content: AnyView(content())
        )
    }
    
    // 无内容的初始化方法
    init(
        title: String,
        message: String? = nil,
        primaryButtonTitle: String = "确定",
        secondaryButtonTitle: String = "取消",
        primaryAction: @escaping () -> Void,
        secondaryAction: @escaping () -> Void
    ) {
        self.configuration = AlertConfiguration(
            title: title,
            message: message,
            primaryButtonTitle: primaryButtonTitle,
            secondaryButtonTitle: secondaryButtonTitle,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction
        )
    }
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            // 提示框
            VStack(spacing: 20) {
                // 标题
                Text(configuration.title)
                    .font(.headline)
                    .padding(.top)
                
                // 消息（如果有）
                if let message = configuration.message {
                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // 自定义内容（如果有）
                if let content = configuration.content {
                    content
                        .padding(.horizontal)
                }
                
                // 按钮
                if !configuration.primaryButtonTitle.isEmpty || !configuration.secondaryButtonTitle.isEmpty {
                    HStack(spacing: 20) {
                        if !configuration.secondaryButtonTitle.isEmpty {
                            Button(action: configuration.secondaryAction) {
                                Text(configuration.secondaryButtonTitle)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .foregroundColor(.red)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        
                        if !configuration.primaryButtonTitle.isEmpty {
                            Button(action: configuration.primaryAction) {
                                Text(configuration.primaryButtonTitle)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .foregroundColor(.blue)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .frame(maxWidth: min(UIScreen.main.bounds.width - 40, 300))
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 10)
        }
    }
}

// MARK: - 预览
struct CustomAlertView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white
            
            CustomAlertView(
                configuration: AlertConfiguration(
                    title: "预览",
                    message: "这是一个测试消息",
                    primaryButtonTitle: "确定",
                    secondaryButtonTitle: "取消",
                    primaryAction: {},
                    secondaryAction: {},
                    content: AnyView(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                            .frame(height: 100)
                    )
                )
            )
        }
    }
} 
 