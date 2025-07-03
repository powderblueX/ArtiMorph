//
//  USDZView.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/3.
//

import SwiftUI

struct USDZView: View {
    let modelFile: URL
    @State private var mode: USDZViewMode = .ar
    @State private var isModelPlaced = false
    @State private var showRetryButton = false
    @State private var showARInstructions = true
    
    // 添加状态来触发AR视图刷新
    @State private var arViewId = UUID()
    
    var body: some View {
        ZStack {
            // 主内容
            VStack {
                Picker("模式", selection: $mode) {
                    Text("AR模式").tag(USDZViewMode.ar)
                    Text("对象模式").tag(USDZViewMode.object)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 20)
                
                Group {
                    switch mode {
                    case .ar:
                        ARModeView(modelFile: modelFile, isModelPlaced: $isModelPlaced, showRetryButton: $showRetryButton, onRetry: {
                                // 当重试回调被触发时
                                showRetryButton = false
                                // 通过改变id强制刷新AR视图
                                arViewId = UUID()
                            }
                        )
                        .id(arViewId) // 使用id来控制视图刷新
                        .edgesIgnoringSafeArea(.all)
                    case .object:
                        ObjectModeView(modelFile: modelFile)
                    }
                }
            }
            // 放置失败提示和刷新按钮
            if showRetryButton && mode == .ar {
                VStack {
                    Text("无法放置模型")
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .animation(.easeInOut, value: showRetryButton)
                    
                    Button(action: {
                        // 触发重试逻辑
                        showRetryButton = false
                        arViewId = UUID() // 强制刷新AR视图
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(Color.black.opacity(0.3))
            }
        }
        .onChange(of: mode) {
            showARInstructions = (mode == .ar)
        }
    }
}
