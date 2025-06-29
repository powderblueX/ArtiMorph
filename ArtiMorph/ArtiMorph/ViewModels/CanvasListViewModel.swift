import Foundation
import Combine

class CanvasListViewModel: ObservableObject {
    @Published var canvases: [CanvasData] = []
    @Published var isLoading = false
    @Published var error: Error?
    private let storageService = CanvasStorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadCanvases()
    }
    
    // 加载所有画布
    func loadCanvases() {
        isLoading = true
        DispatchQueue.global().async {
            do {
                let canvases = try self.storageService.getAllCanvases()
                DispatchQueue.main.async {
                    self.canvases = canvases
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    // 创建新画布
    func createNewCanvas(name: String) {
        isLoading = true
        DispatchQueue.global().async {
            do {
                // 检查名称唯一性
                let isUnique = try self.storageService.isCanvasNameUnique(name)
                guard isUnique else {
                    DispatchQueue.main.async {
                        self.error = NSError(domain: "CanvasError", code: 1, userInfo: [NSLocalizedDescriptionKey: "画布名称已存在"])
                        self.isLoading = false
                    }
                    return
                }
                // 创建新画布
                _ = self.storageService.createNewCanvas(name: name)
                DispatchQueue.main.async {
                    self.loadCanvases()
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }

    // 重命名画布
    func renameCanvas(_ canvas: CanvasData, to newName: String) {
        isLoading = true
        DispatchQueue.global().async {
            do {
                // 检查名称唯一性（排除当前画布ID）
                let isUnique = try self.storageService.isCanvasNameUnique(newName, excludingId: canvas.id)
                guard isUnique else {
                    DispatchQueue.main.async {
                        self.error = NSError(domain: "CanvasError", code: 1, userInfo: [NSLocalizedDescriptionKey: "画布名称已存在"])
                        self.isLoading = false
                    }
                    return
                }
                // 更新画布名称
                canvas.name = newName
                try self.storageService.updateCanvas(canvas)
                DispatchQueue.main.async {
                    self.loadCanvases()
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    // 删除画布
    func deleteCanvas(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let canvas = canvases[index]
        DispatchQueue.global().async {
            do {
                try self.storageService.deleteCanvas(id: canvas.id)
                DispatchQueue.main.async {
                    self.canvases.remove(at: index)
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                }
            }
        }
    }
}