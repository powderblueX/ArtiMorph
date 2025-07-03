import SwiftUI
import PencilKit
import Combine

class CanvasViewModel: ObservableObject {
    // 核心画布属性
    @Published var canvasView = PKCanvasView()
    @Published var drawingTool = DrawingTool()
    @Published var showSelectionAlert = false
    @Published var isDraw = true // 新增绘图状态属性
    @Published var canvasData: CanvasData
    private var originalDrawing: PKDrawing?
    
    @Published var selectionFrameVM = SelectionFrameViewModel(
            frame: CGRect(x: 100, y: 100, width: 300, height: 300),
            isActive: false
        )
    
    private let storageService = CanvasStorageService.shared
    private var cancellables = Set<AnyCancellable>()
    private var saveTimer: Timer?
    
    // 缩放平移属性
    @Published var scale: CGFloat = 1.0
    @Published var lastScale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var lastOffset: CGSize = .zero
    
    // 手势状态
    @Published var currentGesture: GestureType = .none

    init(canvasData: CanvasData) {
        self.canvasData = canvasData
        self.originalDrawing = nil
        
        // 加载绘图数据
        if let drawing = canvasData.getDrawing() {
            self.canvasView.drawing = drawing
            self.originalDrawing = self.canvasView.drawing
        } else {
            self.originalDrawing = nil
        }
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // 订阅工具变化以更新画布
        drawingTool.$currentTool
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTool in
                guard let self = self else { return }
                self.canvasView.tool = newTool
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // 监听绘图变化，实现自动保存
        NotificationCenter.default.publisher(for: NSNotification.Name("PKCanvasViewDrawingDidChange"))
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink {
                [weak self] _ in
                guard let self = self else { return }
                self.saveCanvas()
            }
            .store(in: &cancellables)
        
        // 初始设置工具
        canvasView.tool = drawingTool.currentTool
    }
    

    @Published var colors: [Color] = [.black, .blue, .red, .green, .yellow, .purple, .orange, .pink, .brown, .cyan, .mint, .primary, .indigo, .teal, .secondary, .gray]
    
    func setColor(_ color: Color) {
        drawingTool.setColor(color)
    }
    
    func setEraserSize(_ size: CGFloat) {
        drawingTool.setWidth(size)
    }
    
    func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }
    
    func undo() {
        canvasView.undoManager?.undo()
    }
    
    func redo() {
        canvasView.undoManager?.redo()
    }
    
    // 同步方法：将 selectionFrameVM 的状态映射到外部（如需）
    var selectionFrame: CGRect {
        get { selectionFrameVM.state.frame }
        set { selectionFrameVM.state.frame = newValue }
    }
        
    var isSelectionActive: Bool {
        get { selectionFrameVM.state.isActive }
        set { selectionFrameVM.state.isActive = newValue }
    }
    
    // 2D转3D处理方法
    func convert2DTo3D() {
        // 此处为2D转3D的空实现
        print("开始2D转3D处理")
        isSelectionActive = false
    }
    
    // 保存画布数据
    func saveCanvas() {
        // 检查绘图是否有实际变化
        let hasChanges: Bool
        if let original = originalDrawing {
            hasChanges = original.dataRepresentation() != canvasView.drawing.dataRepresentation()
        } else {
            // 处理新建画布无初始绘图的情况
            hasChanges = !canvasView.drawing.strokes.isEmpty
        }
        guard hasChanges else {
            // 绘图无变化，不保存
            return
        }
        
        let updatedCanvas = canvasData
        updatedCanvas.updateDrawing(canvasView.drawing)
        
        // 生成缩略图
        let thumbnail = canvasView.drawing.image(from: canvasView.bounds, scale: 0.2)
        updatedCanvas.updateThumbnail(thumbnail)
        
        do {
            try storageService.updateCanvas(updatedCanvas)
            self.canvasData = updatedCanvas
            self.originalDrawing = canvasView.drawing
            print("画布自动保存成功")
        } catch {
            print("画布保存失败: \(error.localizedDescription)")
        }
    }
}

