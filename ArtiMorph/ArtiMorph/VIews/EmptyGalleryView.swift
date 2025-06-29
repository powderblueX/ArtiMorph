//
//  EmptyGalleryView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/29.
//

import SwiftUI

struct EmptyGalleryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无3D模型")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("点击右上角+按钮导入USDZ格式的3D模型")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#Preview {
    EmptyGalleryView()
}
