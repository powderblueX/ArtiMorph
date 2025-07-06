//
//  ModelCardView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/29.
//

import SwiftUI

struct ModelCardView: View {
    let model: ARModel
    @State private var thumbnail: UIImage?
    private static var thumbnailCache = [URL: UIImage]()
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .aspectRatio(1, contentMode: .fit)
                
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: .infinity)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: .infinity)
                        .foregroundColor(.gray)
                }
            }
            
            Text(model.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            loadThumbnail()
        }
    }
    
    
    private func loadThumbnail() {
        // 检查缓存
        if let cachedImage = Self.thumbnailCache[model.url] {
            self.thumbnail = cachedImage
            return
        }
        
        print("正在加载缩略图: \(model.url.path)")
        
        DispatchQueue.global().async {
            if let image = ThumbnailGenerator.generateThumbnail(for: self.model.url, size: CGSize(width: 300, height: 300)) {
                // 缓存并更新UI
                Self.thumbnailCache[self.model.url] = image
                
                DispatchQueue.main.async {
                    self.thumbnail = image
                    print("✅ 缩略图加载成功")
                }
            } else {
                print("❌ 缩略图生成失败")
            }
        }
    }
}
