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
                    VStack {
                        Text("AR预览不可用")
                            .font(.title)
                        Text(error)
                            .padding()
                        
                        Button("使用真机测试") {
                            if let url = URL(string: "https://developer.apple.com/documentation/arkit") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    isLoading = false
                    #if targetEnvironment(simulator)
                    errorMessage = """
                    模拟器AR功能受限！
                    请使用真机测试完整AR体验。
                    当前模型: \(model.name)
                    """
                    #endif
                }
            }
        }
    }
}

//struct ARModelPreviewView: View {
//    let model: ARModel
//    @State private var arError: String?
//    @State private var isLoading = true
//    @Environment(\.dismiss) var dismiss
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                // 主AR视图
//                ARViewContainer(modelURL: model.url, errorMessage: $arError)
//                    .edgesIgnoringSafeArea(.all)
//                
//                // 加载指示器
//                if isLoading {
//                    ProgressView()
//                        .scaleEffect(2)
//                }
//                
//                // 错误显示
//                if let error = arError {
//                    VStack {
//                        Text("AR预览错误")
//                            .font(.headline)
//                        Text(error)
//                            .padding()
//                            .background(Material.ultraThinMaterial)
//                            .cornerRadius(10)
//                        
//                        Button("重试") {
//                            isLoading = true
//                            arError = nil
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                isLoading = false
//                            }
//                        }
//                        .buttonStyle(.borderedProminent)
//                        
//                        Spacer()
//                    }
//                    .padding()
//                }
//            }
//            .navigationTitle(model.name)
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("关闭") { dismiss() }
//                }
//            }
//            .onAppear {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                    isLoading = false
//                }
//            }
//        }
//    }
//}

// 在预览中使用Apple官方模型
#Preview {
    ARModelPreviewView(model: ARModel(
        id: UUID(),
        name: "测试模型",
        url: Bundle.main.url(forResource: "toy_car", withExtension: "usdz")!
    ))
}
