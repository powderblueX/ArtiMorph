//
//  OnboardingContentView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/28.
//

import SwiftUI

struct OnboardingContentView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            Text("神笔·绘境")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
            
            // 副标题
            Text("将你的创意变为现实")
                .font(.title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 功能介绍
            VStack(alignment: .leading, spacing: 15) {
                FeatureRowView(iconName: "pencil.and.outline", text: "自由绘制任何形状")
                FeatureRowView(iconName: "cube.fill", text: "一键转换为3D模型")
                FeatureRowView(iconName: "arkit", text: "在AR环境中交互")
                FeatureRowView(iconName: "square.and.arrow.up", text: "导出分享你的创作")
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(15)
            .padding(.horizontal)
            
            Spacer()
            
            // 开始按钮
            Button(action: {
                onComplete()
            }) {
                Text("开始创作")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    .padding(.horizontal, 40)
            }
            .padding(.horizontal, 40)
            .transition(.opacity)
        }
        .padding(.vertical, 50)
        .transition(.opacity)
    }
}
