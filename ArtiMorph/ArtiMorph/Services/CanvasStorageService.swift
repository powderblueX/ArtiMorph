import Foundation
import PencilKit
import UIKit
import SwiftData

class CanvasStorageService {
    static let shared = CanvasStorageService()
    private let container: ModelContainer
    private let context: ModelContext
    
    private init() {
        do {
            container = try ModelContainer(for: CanvasData.self)
            context = ModelContext(container)
        } catch {
            fatalError("Could not initialize SwiftData container: \(error)")
        }
    }
    
    // 保存画布数据
    func saveCanvas(_ canvas: CanvasData) throws {
        context.insert(canvas)
        try context.save()
    }
    
    // 获取所有画布
    func getAllCanvases() throws -> [CanvasData] {
        let fetchDescriptor = FetchDescriptor<CanvasData>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return try context.fetch(fetchDescriptor)
    }
    
    // 加载特定画布
    func loadCanvas(id: UUID) throws -> CanvasData? {
        let fetchDescriptor = FetchDescriptor<CanvasData>(predicate: #Predicate { $0.id == id })
        let results = try context.fetch(fetchDescriptor)
        return results.first
    }
    
    // 删除画布
    func deleteCanvas(id: UUID) throws {
        guard let canvas = try loadCanvas(id: id) else { return }
        context.delete(canvas)
        try context.save()
    }
    
    // 创建新画布
    func createNewCanvas(name: String) -> CanvasData {
        let canvas = CanvasData(name: name, drawing: PKDrawing())
        context.insert(canvas)
        try? context.save()
        return canvas
    }
    
    // 更新画布内容
    func updateCanvas(_ canvas: CanvasData) throws {
        try context.save()
    }

    // 检查画布名称是否唯一
    func isCanvasNameUnique(_ name: String, excludingId id: UUID? = nil) throws -> Bool {
        let excludedId = id ?? UUID()
        let fetchDescriptor = FetchDescriptor<CanvasData>(
            predicate: #Predicate { 
                $0.name == name && $0.id != excludedId
            }
        )
        let count = try context.fetchCount(fetchDescriptor)
        return count == 0
    }
}