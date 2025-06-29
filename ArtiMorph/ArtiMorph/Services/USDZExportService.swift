////
////  USDZExportService.swift
////  ArtiMorph
////
////  Created by admin on 2025/6/20.
////
//
//import Foundation
//import SceneKit
//import ARKit
//import ModelIO
//
///// USDZ导出服务
///// 负责将3D模型导出为USDZ格式
//class USDZExportService {
//    // MARK: - 单例
//    
//    static let shared = USDZExportService()
//    
//    private init() {}
//    
//    // MARK: - 公开方法
//    
//    /// 将SCNNode导出为USDZ文件
//    /// - Parameters:
//    ///   - node: 要导出的节点
//    ///   - filename: 文件名（不包含扩展名）
//    ///   - completion: 完成回调，返回导出的URL或错误
//    func exportToUSDZ(
//        node: SCNNode,
//        filename: String,
//        completion: @escaping (Result<URL, Error>) -> Void
//    ) {
//        // 在后台线程处理导出
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                // 1. 创建临时目录URL
//                let temporaryDirectoryURL = FileManager.default.temporaryDirectory
//                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
//                
//                try FileManager.default.createDirectory(
//                    at: temporaryDirectoryURL,
//                    withIntermediateDirectories: true,
//                    attributes: nil
//                )
//                
//                // 2. 创建导出URL
//                let exportURL = temporaryDirectoryURL.appendingPathComponent("\(filename).usdz")
//                
//                // 3. 创建SCNScene并添加节点
//                let scene = SCNScene()
//                
//                // 克隆节点以避免修改原始节点
//                let exportNode = node.clone()
//                scene.rootNode.addChildNode(exportNode)
//                
//                // 4. 导出为USDZ
//                try self.exportSceneToUSDZ(scene: scene, url: exportURL)
//                
//                // 5. 在主线程返回结果
//                DispatchQueue.main.async {
//                    completion(.success(exportURL))
//                }
//            } catch {
//                // 在主线程返回错误
//                DispatchQueue.main.async {
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
//    
//    // MARK: - 私有方法
//    
//    /// 将SCNScene导出为USDZ文件
//    /// - Parameters:
//    ///   - scene: 要导出的场景
//    ///   - url: 导出的URL
//    private func exportSceneToUSDZ(scene: SCNScene, url: URL) throws {
//        // 将SCNScene保存为临时文件，然后从文件创建MDLAsset
//        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_scene.scn")
//        scene.write(to: tempURL, options: nil, delegate: nil)
//        
//        // 从文件创建MDLAsset
//        let asset = MDLAsset(url: tempURL)
//        
//        // 导出为USDZ
//        try asset.export(to: url)
//        
//        // 删除临时文件
//        try? FileManager.default.removeItem(at: tempURL)
//        
//        // 导出已在上面完成
//    }
//    
//    /// 分享USDZ文件
//    /// - Parameters:
//    ///   - url: USDZ文件的URL
//    ///   - viewController: 用于显示分享界面的视图控制器
//    func shareUSDZ(url: URL, from viewController: UIViewController) {
//        // 创建活动视图控制器
//        let activityViewController = UIActivityViewController(
//            activityItems: [url],
//            applicationActivities: nil
//        )
//        
//        // 在iPad上设置弹出位置
//        if let popoverController = activityViewController.popoverPresentationController {
//            popoverController.sourceView = viewController.view
//            popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
//            popoverController.permittedArrowDirections = []
//        }
//        
//        // 显示分享界面
//        viewController.present(activityViewController, animated: true)
//    }
//}
