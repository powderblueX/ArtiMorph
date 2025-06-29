//
//  ZoomHintView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/28.
//

import SwiftUI

// 新增缩放提示视图
struct ZoomHintView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("画布缩放提示")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: "hand.point.up.left.fill")
                    .foregroundColor(.white)
                Text("双指捏合: 缩放画布")
                    .foregroundColor(.white)
            }
            
            HStack {
                Image(systemName: "hand.point.up.left.and.hand.point.up.right.fill")
                    .foregroundColor(.white)
                Text("双指拖动: 平移画布")
                    .foregroundColor(.white)
            }
            
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.white)
                Text("点击重置按钮: 恢复原始视图")
                    .foregroundColor(.white)
            }
        }
        .padding()
    }
}
