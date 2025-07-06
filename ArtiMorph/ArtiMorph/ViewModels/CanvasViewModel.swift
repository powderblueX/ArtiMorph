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
    
    private let storageService = CanvasStorageService.shared
    private var cancellables = Set<AnyCancellable>()
    private var saveTimer: Timer?
    
    // 添加安全区域存储
    var safeAreaInsets: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    
    @Published var showNetworkErrorAlert = false
    @Published var networkErrorDescription = ""
    
    // 缩放平移属性
    @Published var scale: CGFloat = 1.0
    @Published var lastScale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var lastOffset: CGSize = .zero
    
    // 2D转3D
    @Published var show3DViewer = false
    @Published var current3DModelURL: URL?
    
    // 手势状态
    @Published var currentGesture: GestureType = .none
    
    // 转换状态指示器
    @Published var isConverting = false
    
    // converterClient 属性
    private let converterClient: ImageTo3DConverterClient

    init(canvasData: CanvasData) {
        self.canvasData = canvasData
        self.originalDrawing = nil
        
        // 初始化转换客户端
        self.converterClient = ImageTo3DConverterClient(apiKey: "tsk_5mzICqEC1QIjY8eMs1l_H05DoMBL3-31qEXXm2Od56W")
        
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
    // 保存整个画布为图片
    func saveFullCanvasImage(completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.main.async {
            // 方法1：直接从PKCanvasView获取绘图
            let image = self.canvasView.drawing.image(
                from: self.canvasView.bounds,
                scale: UIScreen.main.scale
            )
            completion(image)
            
            // 或者方法2：如果需要包含背景等其他元素
            /*
             let renderer = UIGraphicsImageRenderer(size: self.canvasView.bounds.size)
             let image = renderer.image { context in
             self.canvasView.drawHierarchy(in: self.canvasView.bounds, afterScreenUpdates: true)
             }
             completion(image)
             */
        }
    }

    // 保存图片到相册
    func saveImageToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    // 显示提示（确保在主线程）
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            // 这里可以使用你项目中已有的提示方式
            // 例如使用SwiftUI的alert或者自定义弹窗
            print("\(title): \(message)")
            
            // 如果你使用SwiftUI的alert，可以这样：
            // self.alertTitle = title
            // self.alertMessage = message
            // self.showAlert = true
        }
    }
    
    // 2D图片展示
    // 控制2D预览sheet显示
    @Published var show2DSheet = false
    // 存储整个画布的图片
    var fullCanvasImage: UIImage?

    // 显示整个画布的图片
    func show2D() {
        saveFullCanvasImage { [weak self] image in
            guard let self = self, let image = image else {
                self?.showAlert(title: "错误", message: "无法获取画布图像")
                return
            }
            self.fullCanvasImage = image
            DispatchQueue.main.async {
                self.show2DSheet = true
            }
        }
        
    }
    
    // 2D转3D处理方法
    func convert2DTo3D() {
        print("开始2D转3D处理")
        
        guard let selectedImage = fullCanvasImage else {
            print("错误：无法获取画布图像")
            showAlert(title: "错误", message: "无法获取画布图像")
            return
        }
        
        isConverting = true
        showNetworkErrorAlert = false
        networkErrorDescription = ""
        
        // 监听转换进度
        converterClient.conversionProgress
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isConverting = false
                    
                    switch completion {
                    case .finished:
                        print("转换和下载完成")
                        // 这里不需要额外操作，因为下载完成事件已处理
                    case .failure(let error as ImageTo3DConverterClient.ConversionError):
                        let errorMessage = error.localizedDescription
                        print("转换失败: \(errorMessage)")
                        // 处理网络错误
                        if errorMessage.contains("offline") {
                            self.networkErrorDescription = "网络连接已断开，请检查您的网络设置后重试"
                        } else {
                            self.networkErrorDescription = errorMessage
                        }
                        self.showNetworkErrorAlert = true
                    case .failure(let error):
                        print("未知错误: \(error.localizedDescription)")
                        self.showAlert(title: "错误", message: error.localizedDescription)
                        self.showNetworkErrorAlert = true
                    }
                },
                receiveValue: { [weak self] progress in
                    guard let self = self else { return }
                    print("转换进度: \(progress.progress)%, 状态: \(progress.status)")
                    
                    // 更新UI状态
                    if progress.status == "success" {
                        print("3D模型生成成功")
                        
                        // 获取模型下载链接，并触发下载
                        if let modelURL = progress.modelURL {
                            print("模型下载链接: \(modelURL.path)")
                            self.converterClient.downloadModel(from: modelURL) // 触发下载操作
                            
                            // 停止轮询
                            self.isConverting = false
                        }
                    }
                    
                    // 当模型下载完成时
                    if progress.status == "download_complete", let modelURL = progress.modelURL {
                        print("下载完成: \(modelURL.path)")
                        self.current3DModelURL = modelURL
                        self.show3DViewer = true
                        self.converterClient.conversionProgress.send(ImageTo3DConverterClient.ConversionProgress(progress: 100, status: "download_complete", modelURL: modelURL))
                        // 重置转换状态
                        self.isConverting = false
                    }
                }
            )
            .store(in: &cancellables)
        
        // 开始转换
        converterClient.convertImageTo3D(selectedImage)
    }
    
    // 在 cleanupTempFiles 方法中添加
    func cleanupTempFiles() {
        if let url = current3DModelURL {
            try? FileManager.default.removeItem(at: url)
            current3DModelURL = nil
        }
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
    
    func shareUSDZFile(url: URL) {
        // 获取当前活跃的场景
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            print("无法获取当前窗口场景")
            return
        }
        
        // 获取当前关键窗口
        guard let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("无法获取关键窗口")
            return
        }
        
        // 获取根视图控制器
        guard let rootViewController = keyWindow.rootViewController else {
            print("无法获取根视图控制器")
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // 适配 iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                        y: rootViewController.view.bounds.midY,
                                        width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityVC, animated: true)
    }
}

extension View {
    func snapshot(scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
