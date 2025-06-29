//
//  OnboardingContentView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/28.
//

import Foundation
import SwiftUI

struct OnboardingContentView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // 原有引导内容（标题、副标题、功能介绍等）...
            
            NavigationLink {
                CanvasListView()
            } label: {
                Text("开始创作")
                    // ...（原有样式）
            }
            .simultaneousGesture(TapGesture().onEnded {
                onComplete() // 点击时标记为已完成
            })
        }
        .padding(.vertical, 50)
    }
}
