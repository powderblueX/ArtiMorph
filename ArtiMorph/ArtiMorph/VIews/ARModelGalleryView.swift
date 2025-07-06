// ARModelGalleryView.swift (保持不变)
//
//  ARModelGalleryView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/28.
//

import SwiftUI
import RealityKit
import UniformTypeIdentifiers

struct ARModelGalleryView: View {
    @StateObject private var viewModel = ARModelGalleryViewModel()
    @State private var selectedModel: ARModel?
    var onSelect: ((ARModel) -> Void)?

    init(onSelect: ((ARModel) -> Void)? = nil) {
        self.onSelect = onSelect
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            // 背景视图
            FlowingGradientBackgroundView(
                Color_1: Color.blue.opacity(0.5),
                Color_2: Color.mint.opacity(0.7),
                duration: 1
            )
            .edgesIgnoringSafeArea(.all)
            
            // 主内容
            mainContent
                .navigationTitle("3D模型库")
                .toolbar { toolbarContent }
                .fileImporter(
                    isPresented: $viewModel.showingFileImporter,
                    allowedContentTypes: [UTType.usdz],
                    allowsMultipleSelection: false
                ) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let urls):
                            guard let url = urls.first else { return }
                            
                            // 获取安全访问权限
                            let accessed = url.startAccessingSecurityScopedResource()
                            defer {
                                if accessed {
                                    url.stopAccessingSecurityScopedResource()
                                }
                            }
                            
                            if accessed {
                                viewModel.handleFileImport(url: url)
                            } else {
                                viewModel.errorMessage = "无法获取文件访问权限"
                                viewModel.isLoading = false
                            }
                            
                        case .failure(let error):
                            viewModel.errorMessage = "导入失败: \(error.localizedDescription)"
                            viewModel.isLoading = false
                        }
                    }
                }
                .fullScreenCover(item: $selectedModel) { model in
                    ARModelPreviewView(model: model)
                }
                .alert(
                    "错误",
                    isPresented: Binding<Bool>(
                        get: { viewModel.errorMessage != nil },
                        set: { if !$0 { viewModel.errorMessage = nil } }
                    )
                ) {
                    Button("确定", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "未知错误")
                }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading && viewModel.models.isEmpty {
            ProgressView("加载模型中...")
                .scaleEffect(1.5)
        } else if viewModel.models.isEmpty {
            EmptyGalleryView()
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.models) { model in
                        ModelCardView(model: model)
                            .onTapGesture {
                                if let onSelect = onSelect {
                                    onSelect(model)
                                } else {
                                    selectedModel = model
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteModel(model)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding()
            }
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: viewModel.importModel) {
                Image(systemName: "plus")
                    .font(.title2)
            }
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // 获取安全访问权限
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            if accessed {
                viewModel.handleFileImport(url: url)
            } else {
                viewModel.errorMessage = "无法获取文件访问权限"
            }
            
        case .failure(let error):
            viewModel.errorMessage = "导入失败: \(error.localizedDescription)"
        }
    }
}
