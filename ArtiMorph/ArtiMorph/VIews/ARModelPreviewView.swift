// ARModelPreviewView.swift (改进错误提示)
//
//  ARModelPreviewView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/29.
//

import SwiftUI

struct ARModelPreviewView: View {
    let model: ARModel
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let error = errorMessage {
                    ErrorView(error: error)
                } else {
                    ARViewContainer(modelURL: model.url, errorMessage: $errorMessage)
                        .edgesIgnoringSafeArea(.all)
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(2)
                }
            }
            .navigationTitle(model.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear {
                // 3秒后隐藏加载指示器（可根据实际加载时间调整）
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    isLoading = false
                }
            }
        }
    }
}

private struct ErrorView: View {
    let error: String
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .padding()
            
            Text("加载失败")
                .font(.title)
            
            Text(error)
                .padding()
                .multilineTextAlignment(.center)
            
            #if targetEnvironment(simulator)
            Text("模拟器仅支持基础预览")
                .foregroundColor(.secondary)
            #endif
        }
        .padding()
    }
}
