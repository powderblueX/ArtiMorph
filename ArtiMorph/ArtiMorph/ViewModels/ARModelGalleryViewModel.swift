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
        // 确保目录存在
        if !fileManager.fileExists(atPath: modelsDirectory.path) {
            try? fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        }
        showingFileImporter = true
    }

    func handleFileImport(url: URL) {
        // 1. 获取安全访问权限
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard accessed else {
            DispatchQueue.main.async {
                self.errorMessage = "无法获取文件访问权限"
                self.isLoading = false
            }
            return
        }
        
        // 2. 检查是否是iCloud文件
        if url.path.contains("com~apple~CloudDocs") {
            handleiCloudFile(url: url)
        } else {
            processLocalFile(url: url)
        }
    }
    
    private func handleiCloudFile(url: URL) {
        // 1. 检查下载状态
        var isDownloaded: AnyObject?
        do {
            try (url as NSURL).getResourceValue(&isDownloaded, forKey: .ubiquitousItemDownloadingStatusKey)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "无法检查iCloud文件状态: \(error.localizedDescription)"
                self.isLoading = false
            }
            return
        }
        
        // 2. 处理不同状态
        if let status = isDownloaded as? URLUbiquitousItemDownloadingStatus {
            switch status {
            case .current:
                processLocalFile(url: url)
            case .notDownloaded:
                downloadiCloudFile(url: url)
            default:
                DispatchQueue.main.async {
                    self.errorMessage = "未知的iCloud文件状态"
                    self.isLoading = false
                }
            }
        } else {
            processLocalFile(url: url)
        }
    }
    
    private func downloadiCloudFile(url: URL) {
        DispatchQueue.main.async {
            self.errorMessage = "正在从iCloud下载文件..."
            self.isLoading = true
        }
        
        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: url)
            monitoriCloudDownload(url: url)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "下载失败: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func monitoriCloudDownload(url: URL) {
        DispatchQueue.global().async {
            var retryCount = 0
            let maxRetry = 10
            
            while retryCount < maxRetry {
                Thread.sleep(forTimeInterval: 1.0)
                
                var isDownloaded: AnyObject?
                do {
                    try (url as NSURL).getResourceValue(&isDownloaded, forKey: .ubiquitousItemDownloadingStatusKey)
                    
                    if let status = isDownloaded as? URLUbiquitousItemDownloadingStatus,
                       status == .current {
                        DispatchQueue.main.async {
                            self.processLocalFile(url: url)
                        }
                        return
                    }
                } catch {
                    print("下载状态检查失败: \(error)")
                }
                
                retryCount += 1
                
                DispatchQueue.main.async {
                    self.errorMessage = "下载中...(\(retryCount * 10)%)"
                }
            }
            
            DispatchQueue.main.async {
                self.errorMessage = "iCloud文件下载超时"
                self.isLoading = false
            }
        }
    }
    
    private func processLocalFile(url: URL) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 1. 获取安全访问权限
                let accessed = url.startAccessingSecurityScopedResource()
                defer {
                    if accessed {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                guard accessed else {
                    throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError, userInfo: nil)
                }
                
                // 2. 准备目标路径
                let destinationURL = self.generateUniqueDestinationURL(for: url)
                
                // 3. 使用文件协调器复制
                var coordinationError: NSError?
                var copyError: Error?
                
                let coordinator = NSFileCoordinator()
                coordinator.coordinate(readingItemAt: url,
                                      options: [.withoutChanges, .resolvesSymbolicLink],
                                      writingItemAt: destinationURL,
                                      options: [.forReplacing],
                                      error: &coordinationError) { (readURL, writeURL) in
                    do {
                        if self.fileManager.fileExists(atPath: writeURL.path) {
                            try self.fileManager.removeItem(at: writeURL)
                        }
                        try self.fileManager.copyItem(at: readURL, to: writeURL)
                    } catch {
                        copyError = error
                    }
                }
                
                if let error = coordinationError ?? copyError {
                    throw error
                }
                
                // 4. 验证结果
                guard self.fileManager.fileExists(atPath: destinationURL.path) else {
                    throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
                }
                
                DispatchQueue.main.async {
                    self.loadLocalModels()
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    print("❌ 复制失败: \(error)")
                    self.errorMessage = "文件处理失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func generateUniqueDestinationURL(for url: URL) -> URL {
        let originalDestination = modelsDirectory.appendingPathComponent(url.lastPathComponent)
        
        if !fileManager.fileExists(atPath: originalDestination.path) {
            return originalDestination
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = url.deletingPathExtension().lastPathComponent
        let newFileName = "\(fileName)_\(timestamp).usdz"
        return modelsDirectory.appendingPathComponent(newFileName)
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
    
    func validateUSDZFile(_ url: URL) -> (isValid: Bool, error: String?) {
        guard fileManager.fileExists(atPath: url.path) else {
            return (false, "文件不存在")
        }
        
        guard url.pathExtension.lowercased() == "usdz" else {
            return (false, "文件扩展名不是usdz")
        }
        
        guard let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              fileSize > 1024 else {
            return (false, "文件太小或无法读取文件大小")
        }
        
        do {
            let modelEntity = try Entity.loadModel(contentsOf: url)
            
            // 直接访问模型属性，无需条件转换
            guard modelEntity.model?.mesh.contents.models.isEmpty == false else {
                return (false, "模型不包含有效几何体")
            }
            
            return (true, nil)
        } catch {
            return (false, "模型验证失败: \(error.localizedDescription)")
        }
    }
}
