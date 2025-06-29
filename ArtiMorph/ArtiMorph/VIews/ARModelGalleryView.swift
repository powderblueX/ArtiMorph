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
    @State private var showARView = false
    
    // 网格布局
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            FlowingGradientBackgroundView(
                Color_1: Color.blue.opacity(0.5),
                Color_2: Color.mint.opacity(0.7),
                duration: 1
            )
            .edgesIgnoringSafeArea(.all)
            
            mainContent
                .navigationTitle("3D模型库")
                .toolbar { toolbarContent }
                .fileImporter(
                    isPresented: $viewModel.showingFileImporter,
                    allowedContentTypes: [UTType.usdz],
                    allowsMultipleSelection: false
                ) { handleFileImport(result: $0) }
                .sheet(item: $selectedModel) { model in
                    ARModelPreviewView(model: model)
                }
                .alert(
                    "错误",
                    isPresented: Binding<Bool>(
                        get: { viewModel.errorMessage != nil },
                        set: { if !$0 { viewModel.errorMessage = nil } }
                    )
                ) {
                    Button("确定") {}
                } message: {
                    Text(viewModel.errorMessage ?? "")
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
                                selectedModel = model
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
            viewModel.handleFileImport(url: url)
        case .failure(let error):
            viewModel.errorMessage = "导入失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - 模型预览视图


#Preview {
    ARModelGalleryView()
}
