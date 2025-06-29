import Foundation
import PencilKit
import SwiftUI

/// 绘图工具类型
enum DrawingToolType: Equatable {
    static func == (lhs: DrawingToolType, rhs: DrawingToolType) -> Bool {
        switch (lhs, rhs) {
        case (.pen, .pen), (.pencil, .pencil), (.marker, .marker), (.monoline, .monoline), (.fountainPen, .fountainPen), (.watercolor, .watercolor), (.crayon, .crayon), (.lasso, .lasso):
            return true
        case (.eraser(let lhsMode), .eraser(let rhsMode)):
            return lhsMode == rhsMode
        default:
            return false
        }
    }
    case pen      // 钢笔
    case pencil   // 铅笔
    case marker   // 马克笔
    case monoline // 单线笔
    case fountainPen // 墨水笔
    case watercolor // 水彩
    case crayon // 蜡笔
    case eraser(EraserMode)  // 橡皮擦
    case lasso // 选择工具
    
    var isDrawingTool: Bool {
        switch self {
        case .pen, .pencil, .marker, .monoline, .fountainPen, .watercolor, .crayon:
            return true
        default:
            return false
        }
    }
    
    var iconName: String {
        switch self {
        case .pen:
            return "pencil.tip"
        case .pencil:
            return "pencil"
        case .marker:
            return "highlighter"
        case .monoline:
            return "pencil.line"
        case .fountainPen:
            return "pencil.and.outline"
        case .watercolor:
            return "paintbrush"
        case .crayon:
            return "scribble.variable"
        case .eraser:
            return "eraser"
        case .lasso:
            return "lasso"
        }
    }
    
    var name: String {
        switch self {
        case .pen:
            return "钢笔"
        case .pencil:
            return "铅笔"
        case .marker:
            return "马克笔"
        case .monoline:
            return "单线笔"
        case .fountainPen:
            return "墨水笔"
        case .watercolor:
            return "水彩"
        case .crayon:
            return "蜡笔"
        case .eraser:
            return "橡皮擦"
        case .lasso:
            return "索套"
        }
    }
}

/// 橡皮擦模式
enum EraserMode: Equatable {
    case pixel    // 像素擦除
    case stroke   // 整笔擦除
}

/// 绘图工具
/// 负责管理绘图工具的状态和配置
class DrawingTool: ObservableObject {
    // MARK: - 发布属性
    
    /// 当前选中的工具类型
    @Published var selectedToolType: DrawingToolType = .pen
    /// 当前颜色
    @Published var color: Color = .black
    /// 当前线宽
    @Published var width: CGFloat = 5
    /// 当前橡皮擦模式
    @Published var eraserMode: EraserMode = .pixel
    /// 当前工具（发布属性，确保视图能收到更新）
    @Published var currentTool: PKTool

    // MARK: - 初始化
    init() {
        currentTool = DrawingTool.createTool(for: .pen, color: .black, width: 5, eraserMode: .pixel)
    }

    // MARK: - 计算属性
    
    /// 创建工具实例
    private static func createTool(for type: DrawingToolType, color: Color, width: CGFloat, eraserMode: EraserMode) -> PKTool {
        switch type {
        case .pen:
            return PKInkingTool(.pen, color: UIColor(color), width: width)
        case .pencil:
            return PKInkingTool(.pencil, color: UIColor(color), width: width)
        case .marker:
            return PKInkingTool(.marker, color: UIColor(color).withAlphaComponent(0.3), width: width)
        case .monoline:
            return PKInkingTool(.monoline, color: UIColor(color), width: width)
        case .fountainPen:
            return PKInkingTool(.fountainPen, color: UIColor(color), width: width)
        case .watercolor:
            return PKInkingTool(.watercolor, color: UIColor(color), width: width)
        case .crayon:
            return PKInkingTool(.crayon, color: UIColor(color), width: width)
        case .eraser(let mode):
            switch mode {
            case .pixel:
                return PKEraserTool(.bitmap, width: width)
            case .stroke:
                return PKEraserTool(.vector, width: width)
            }
        case .lasso:
            return PKLassoTool()
        }
    }

    /// 更新工具
    private func updateCurrentTool() {
        currentTool = DrawingTool.createTool(for: selectedToolType, color: color, width: width, eraserMode: eraserMode)
    }

    // MARK: - 方法
    
    /// 设置工具类型
    /// - Parameter type: 新的工具类型
    // 更新工具设置方法
    func setToolType(_ type: DrawingToolType) {
        // 只有当新工具类型与当前工具类型不同时才进行更新
        // 这样可以避免不必要的UI刷新，并确保工具状态的正确性
        if selectedToolType != type {
            selectedToolType = type
            updateCurrentTool()
        }
    }

    /// 设置橡皮擦模式
    /// - Parameter mode: 新的橡皮擦模式
    func setEraserMode(_ mode: EraserMode) {
        eraserMode = mode
        // 如果当前是橡皮擦，更新工具类型
        if case .eraser = selectedToolType {
            selectedToolType = .eraser(mode)
            updateCurrentTool()
        }
    }

    /// 设置颜色
    /// - Parameter newColor: 新的颜色
    func setColor(_ newColor: Color) {
        color = newColor
        // 如果当前工具不是绘图工具，自动切换到钢笔
        if !selectedToolType.isDrawingTool {
            setToolType(.pen)
        }
        updateCurrentTool()
    }

    /// 设置线宽
    /// - Parameter newWidth: 新的线宽
    func setWidth(_ newWidth: CGFloat) {
        width = newWidth
        updateCurrentTool()
    }
}
