import SwiftUI
import PencilKit

/// 启动页面
struct SplashView: View {
    // MARK: - 属性
    
    /// 是否显示动画
    @State private var showAnimation = true
    /// 是否显示主内容
    @State private var showMainContent = false

    /// 动画缩放
    @State private var size = 0.8
    /// 动画透明度
    @State private var opacity = 0.5
    
    /// 记录用户是否已看过引导（自动持久化到 UserDefaults）
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // MARK: - 视图主体
    
    var body: some View {
            ZStack {
                // 背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.red.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                if showAnimation {
                    // 动画内容
                    VStack {
                        Image(systemName: "pencil.and.ruler.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("神笔·绘境")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .scaleEffect(size)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.2)) {
                            self.size = 1.0
                            self.opacity = 1.0
                        }

                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                self.showAnimation = false
                                self.showMainContent = true
                            }
                        }
                    }
                }
                
                if showMainContent {
                    if !hasCompletedOnboarding {
                        OnboardingContentView {
                            hasCompletedOnboarding = true
                        }
                        .transition(.opacity)
                    } else {
                        MainTabView()
                            .transition(.opacity)
                    }
                }
            }
            .onAppear {
                if hasCompletedOnboarding {
                    // 如果已经完成引导，直接跳过动画
                    showAnimation = false
                    showMainContent = true
                }
            }
        .ignoresSafeArea()
    }
}
