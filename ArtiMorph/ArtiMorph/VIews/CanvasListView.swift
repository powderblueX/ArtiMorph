import SwiftUI
import Combine
import PencilKit

struct CanvasListView: View {
    @StateObject private var viewModel = CanvasListViewModel()
    @State private var showingNewCanvasSheet = false
    @State private var newCanvasName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingRenameAlert = false
    @State private var currentCanvas: CanvasData?
    @State private var renameCanvasName = ""
    @State private var showingCustomRenameAlert = false
    
    // 分页相关状态
    @State private var currentPage = 0
    private let itemsPerPage = 12
    private let columns = [GridItem(.adaptive(minimum: 250), spacing: 100)]
    
    var pagedCanvases: [CanvasData] {
        let start = currentPage * itemsPerPage
        let end = min(start + itemsPerPage, viewModel.canvases.count)
        return Array(viewModel.canvases[start..<end])
    }
    
    var body: some View {
        ZStack{
            // 背景
            FlowingGradientBackgroundView(Color_1: Color.white.opacity(0.5), Color_2: Color.gray.opacity(0.7), duration: 5)
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.isLoading {
                    ProgressView("加载画布中...")
                } else if viewModel.canvases.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("暂无保存的画布")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("点击右上角+创建新画布开始创作")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(pagedCanvases) { canvas in
                                VStack {
                                    NavigationLink(destination: CanvasView(canvas: canvas)) {
                                        if let thumbnailData = canvas.thumbnailData,
                                           let image = UIImage(data: thumbnailData) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 250, height: 250)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10) // 确保边框与背景圆角匹配
                                                        .stroke(Color.mint, lineWidth: 2) // 添加边框
                                                )
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.mint, lineWidth: 2)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 250, height: 250)
                                                .overlay(Image(systemName: "doc.text")
                                                    .foregroundColor(.secondary)
                                                    .font(.system(size: 30)))
                                        }
                                    }
                                    VStack(spacing: 4) {
                                        Text(canvas.name)
                                            .font(.headline)
                                        Text(canvas.updatedAt.formatted())
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 10)
                                }
                                .contextMenu {
                                    Button(action: {
                                        currentCanvas = canvas
                                        renameCanvasName = canvas.name
                                        showingCustomRenameAlert = true
                                    }) {
                                        Label("重命名", systemImage: "pencil")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // 分页按钮
                    HStack {
                        Button("上一页") {
                            if currentPage > 0 { currentPage -= 1 }
                        }
                        .disabled(currentPage == 0)
                        
                        Spacer()
                        
                        Text("第 \(currentPage + 1) 页 / 共 \(max(1, (viewModel.canvases.count + itemsPerPage - 1) / itemsPerPage)) 页")
                            .transition(.opacity)
                        
                        Spacer()
                        
                        Button("下一页") {
                            if (currentPage + 1) * itemsPerPage < viewModel.canvases.count {
                                currentPage += 1
                            }
                        }
                        .disabled((currentPage + 1) * itemsPerPage >= viewModel.canvases.count)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("我的画布")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewCanvasSheet = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewCanvasSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        TextField("输入画布名称", text: $newCanvasName)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                            .navigationTitle("新建画布")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("取消") {
                                        showingNewCanvasSheet = false
                                        newCanvasName = ""
                                    }
                                }
                                ToolbarItem(placement: .primaryAction) {
                                    Button("创建") {
                                        if !newCanvasName.isEmpty {
                                            viewModel.createNewCanvas(name: newCanvasName)
                                            showingNewCanvasSheet = false
                                            newCanvasName = ""
                                        } else {
                                            errorMessage = "请输入画布名称"
                                            showingError = true
                                        }
                                    }
                                    .disabled(newCanvasName.isEmpty || viewModel.isLoading)
                                }
                            }
                    }
                    .presentationDetents([.height(200)])
                }
            }
            .alert(isPresented: $showingError) {
                Alert(title: Text("错误"), message: Text(errorMessage), dismissButton: .default(Text("确定")))
            }
            .sheet(isPresented: $showingCustomRenameAlert) {
                CustomAlertView(
                    title: "重命名画布",
                    primaryButtonTitle: "重命名",
                    secondaryButtonTitle: "取消",
                    primaryAction: {
                        guard let canvas = currentCanvas, !renameCanvasName.isEmpty else { return }
                        viewModel.renameCanvas(canvas, to: renameCanvasName)
                        showingCustomRenameAlert = false
                    },
                    secondaryAction: {
                        showingCustomRenameAlert = false
                    },
                    content: {
                        TextField("请输入名称", text: $renameCanvasName)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                    }
                )
                .frame(width: 300)
                .presentationBackground(.clear)
                .background(Color.white)
                .ignoresSafeArea()
                .presentationDetents([.height(200)])
            }
        }
        .onAppear {
            viewModel.loadCanvases()
        }
        .onReceive(viewModel.$error) {
            error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// 日期格式化扩展
extension Date {
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
