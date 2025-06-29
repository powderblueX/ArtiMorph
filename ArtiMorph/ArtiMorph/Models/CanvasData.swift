import Foundation
import PencilKit

import SwiftData

@Model
class CanvasData: Identifiable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var drawingData: Data // 存储PKDrawing数据
    var thumbnailData: Data? // 存储缩略图
    
    init(name: String, drawing: PKDrawing) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.drawingData = drawing.dataRepresentation()
        self.thumbnailData = nil
    }
    
    // 从数据加载绘图
    func getDrawing() -> PKDrawing? {
        try? PKDrawing(data: drawingData)
    }
    
    // 更新绘图数据
    func updateDrawing(_ drawing: PKDrawing) {
        self.drawingData = drawing.dataRepresentation()
        self.updatedAt = Date()
    }
    
    // 更新缩略图
    func updateThumbnail(_ image: UIImage) {
        self.thumbnailData = image.pngData()
    }
}