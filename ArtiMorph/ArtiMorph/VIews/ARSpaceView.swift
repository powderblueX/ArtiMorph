//
//  ARSpaceView.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/6.
//

import SwiftUI
import RealityKit

struct ARSpaceView: View {
    @StateObject var viewModel = ARSpaceViewModel()
    @State private var showGallery = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // AR View
            CustomARViewContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
            
            // 右侧控制按钮列
            VStack(spacing: 20) {
                // 选择模型按钮
                Button(action: {
                    viewModel.currentMode = .select
                    viewModel.deselectAllEntities()
                }) {
                    VStack {
                        Image(systemName: "cursorarrow")
                            .font(.title)
                        Text("选择")
                            .font(.caption)
                    }
                    .padding(10)
                    .background(viewModel.currentMode == .select ? Color.blue : Color.white.opacity(0.8))
                    .foregroundColor(viewModel.currentMode == .select ? .white : .black)
                    .cornerRadius(10)
                }
                
                // 删除模型按钮
                Button(action: {
                    viewModel.currentMode = .delete
                    viewModel.deselectAllEntities()
                }) {
                    VStack {
                        Image(systemName: "trash")
                            .font(.title)
                        Text("删除")
                            .font(.caption)
                    }
                    .padding(10)
                    .background(viewModel.currentMode == .delete ? Color.red : Color.white.opacity(0.8))
                    .foregroundColor(viewModel.currentMode == .delete ? .white : .black)
                    .cornerRadius(10)
                }
                
                // 放置模型按钮
                Button(action: {
                    viewModel.currentMode = .place
                    showGallery = true
                    viewModel.deselectAllEntities()
                }) {
                    VStack {
                        Image(systemName: "cube")
                            .font(.title)
                        Text("放置")
                            .font(.caption)
                    }
                    .padding(10)
                    .background(viewModel.currentMode == .place ? Color.green : Color.white.opacity(0.8))
                    .foregroundColor(viewModel.currentMode == .place ? .white : .black)
                    .cornerRadius(10)
                    .opacity(viewModel.currentMode == .place ? 1.0 : 0.8)
                }
                .disabled(viewModel.currentMode == .place)
            }
            .padding(.trailing, 20)
            .padding(.top, 50)
        }
        .sheet(isPresented: $showGallery) {
            ARModelGalleryView(onSelect: { model in
                viewModel.selectedModel = model
                showGallery = false
            })
        }
    }
}

struct CustomARViewContainer: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ARSpaceViewModel
    
    func makeUIViewController(context: Context) -> ARSpaceViewController {
        let vc = ARSpaceViewController()
        vc.viewModel = viewModel
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ARSpaceViewController, context: Context) {
        // 确保 ARView 尺寸正确
        uiViewController.arView.frame = uiViewController.view.bounds
    }
    
    // 添加协调器来处理更复杂的交互
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator {
        var parent: CustomARViewContainer
        
        init(_ parent: CustomARViewContainer) {
            self.parent = parent
        }
    }
}

class ARSpaceViewController: UIViewController {
    var viewModel: ARSpaceViewModel!
    var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.arView = ARView(frame: view.bounds)
        self.arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(self.arView)
        
        // 明确使用 self 捕获
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.viewModel.setupARView(self.arView)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.arView.frame = self.view.bounds
    }
}
