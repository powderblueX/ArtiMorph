//
//  ARModelGalleryViewModel.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/28.
//

import SwiftUI
import RealityKit
import Combine
import UniformTypeIdentifiers

class ARModelGalleryViewModel: ObservableObject {
    /// 本地USDZ模型列表
    @Published var models: [ARModel] = []
    /// 当前选中的模型
    @Published var selectedModel: ARModel?
    /// 是否显示模型详情
    @Published var showingModelDetail = false
    /// 是否显示文件选择器
    @Published var showingFileImporter = false
    /// 错误信息
    @Published var errorMessage: String?
    /// 加载状态
    @Published var isLoading = false
    /// AR 预览错误信息
    @Published var arErrorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    private let modelsDirectory: URL

    init() {
        // 获取应用文档目录
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("无法访问文档目录")
        }
        
        // 创建模型存储目录
        modelsDirectory = documentsDirectory.appendingPathComponent("ARModels")
        try? fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        
        // 加载本地模型
        loadLocalModels()
    }

    /// 加载本地USDZ模型
    func loadLocalModels() {
        isLoading = true
        
        DispatchQueue.global().async {
            do {
                let fileURLs = try self.fileManager.contentsOfDirectory(at: self.modelsDirectory,
                                                                       includingPropertiesForKeys: [.contentModificationDateKey],
                                                                       options: .skipsHiddenFiles)
                
                let usdzFiles = fileURLs.filter { $0.pathExtension.lowercased() == "usdz" }
                let models = usdzFiles.compactMap { url -> ARModel? in
                    let name = url.deletingPathExtension().lastPathComponent
                    return ARModel(id: UUID(), name: name, url: url)
                }
                
                // 按修改日期排序（最新的在前）
                let sortedModels = models.sorted { $0.modificationDate > $1.modificationDate }
                
                DispatchQueue.main.async {
                    self.models = sortedModels
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "加载模型失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    /// 导入新模型
    func importModel() {
        showingFileImporter = true
    }

    /// 处理导入的文件
    func handleFileImport(url: URL) {
        let validation = validateUSDZFile(url)
        guard validation.isValid else {
            errorMessage = validation.error ?? "未知错误"
            return
        }

        isLoading = true
        
        DispatchQueue.global().async {
            do {
                // 复制文件到应用沙盒
                let destinationURL = self.modelsDirectory.appendingPathComponent(url.lastPathComponent)
                
                if self.fileManager.fileExists(atPath: destinationURL.path) {
                    // 如果文件已存在，添加时间戳
                    let timestamp = Date().timeIntervalSince1970
                    let fileName = url.deletingPathExtension().lastPathComponent
                    let newFileName = "\(fileName)_\(timestamp).usdz"
                    let destinationURL = self.modelsDirectory.appendingPathComponent(newFileName)
                    try self.fileManager.copyItem(at: url, to: destinationURL)
                } else {
                    try self.fileManager.copyItem(at: url, to: destinationURL)
                }
                
                DispatchQueue.main.async {
                    self.loadLocalModels() // 重新加载模型列表
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "导入模型失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    /// 删除模型
    func deleteModel(_ model: ARModel) {
        isLoading = true
        
        DispatchQueue.global().async {
            do {
                try self.fileManager.removeItem(at: model.url)
                
                DispatchQueue.main.async {
                    self.models.removeAll { $0.id == model.id }
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "删除模型失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    /// 选择模型
    func selectModel(_ model: ARModel) {
        selectedModel = model
        showingModelDetail = true
    }
    
    /// 验证 USDZ 文件有效性
    func validateUSDZFile(_ url: URL) -> (isValid: Bool, error: String?) {
        // 1. 基础文件检查
        guard url.pathExtension.lowercased() == "usdz",
              let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              fileSize > 1024 else {
            return (false, "文件不是有效的USDZ格式")
        }
        
        // 2. 深度验证
        do {
            let scene = try Entity.load(contentsOf: url)
            
            // 检查多边形数量 - 使用更兼容的方式
            if let modelEntity = scene as? ModelEntity,
               let mesh = modelEntity.model?.mesh {
                var totalTriangles = 0
                
                for model in mesh.contents.models {
                    for part in model.parts {
                        // 安全解包 triangleIndices
                        if let triangleIndices = part.triangleIndices {
                            totalTriangles += triangleIndices.count / 3
                        }
                        // 如果 triangleIndices 为 nil，可以在这里处理错误或跳过
                    }
                }
                
                if totalTriangles > 50000 {
                    return (false, "模型过于复杂（超过5万面）")
                }
            }
            
            return (true, nil)
        } catch {
            return (false, "模型验证失败: \(error.localizedDescription)")
        }
    }
}

