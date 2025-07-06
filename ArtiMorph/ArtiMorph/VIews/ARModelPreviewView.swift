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
            }
            .navigationTitle(model.name)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isLoading = false
                }
            }
            
            // 返回按钮
            VStack {
                Spacer()
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title)
                            .padding()
                            .background(Color.white.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .padding()
                    Spacer()
                }
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
