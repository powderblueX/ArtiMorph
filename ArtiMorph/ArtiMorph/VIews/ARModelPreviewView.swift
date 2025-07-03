// ARModelPreviewView.swift (改进错误提示)
//
//  ARModelPreviewView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/29.
//

import SwiftUI
import RealityKit

struct ARModelPreviewView: View {
    let model: ARModel
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Group {
                if let error = errorMessage {
                    ErrorView(error: error)
                } else {
                    USDZView(modelFile: model.url)
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(2)
                }
            }
            .navigationTitle(model.name)
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(2)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isLoading = false
                }
            }
            
            // 返回按钮
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        dismiss() // 调用 dismiss 关闭全屏模态
                    }) {
                        Image(systemName: "chevron.backward")
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

private struct ErrorView: View {
    let error: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            VStack(spacing: 10) {
                Text("模型加载失败")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundColor(.white)
                
                #if targetEnvironment(simulator)
                Divider()
                    .padding(.vertical, 8)
                Text("模拟器仅支持基础预览")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                #endif
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
