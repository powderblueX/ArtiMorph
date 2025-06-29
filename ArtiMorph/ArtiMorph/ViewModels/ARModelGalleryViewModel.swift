// ARModelGalleryViewModel.swift (优化验证逻辑)
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
    @Published var models: [ARModel] = []
    @Published var selectedModel: ARModel?
    @Published var showingModelDetail = false
    @Published var showingFileImporter = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var arErrorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    private let modelsDirectory: URL

    init() {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("无法访问文档目录")
        }
        
        modelsDirectory = documentsDirectory.appendingPathComponent("ARModels")
        try? fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        loadLocalModels()
    }

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

    func importModel() {
        showingFileImporter = true
    }

    func handleFileImport(url: URL) {
        let validation = validateUSDZFile(url)
        guard validation.isValid else {
            errorMessage = validation.error ?? "未知错误"
            return
        }

        isLoading = true
        
        DispatchQueue.global().async {
            do {
                let destinationURL = self.modelsDirectory.appendingPathComponent(url.lastPathComponent)
                
                if self.fileManager.fileExists(atPath: destinationURL.path) {
                    let timestamp = Date().timeIntervalSince1970
                    let fileName = url.deletingPathExtension().lastPathComponent
                    let newFileName = "\(fileName)_\(timestamp).usdz"
                    let destinationURL = self.modelsDirectory.appendingPathComponent(newFileName)
                    try self.fileManager.copyItem(at: url, to: destinationURL)
                } else {
                    try self.fileManager.copyItem(at: url, to: destinationURL)
                }
                
                DispatchQueue.main.async {
                    self.loadLocalModels()
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

    func selectModel(_ model: ARModel) {
        selectedModel = model
        showingModelDetail = true
    }
    
    // 优化后的模型验证方法
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
            
            // 更健壮的多边形计数
            if let modelEntity = scene as? ModelEntity {
                var totalTriangles = 0
                
                // 使用更可靠的遍历方法
                for model in modelEntity.model?.mesh.contents.models ?? [] {
                    for part in model.parts {
                        if let indices = part.triangleIndices {
                            totalTriangles += indices.count / 3
                        }
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
