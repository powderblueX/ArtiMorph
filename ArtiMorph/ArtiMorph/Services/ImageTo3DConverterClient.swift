//
//  ImageTo3DConverterClient.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/5.
//

import Foundation
import UIKit
import Combine

class ImageTo3DConverterClient {
    private let apiKey: String
    private let baseURL = "https://api.tripo3d.ai/v2/openapi"
    private var cancellables = Set<AnyCancellable>()
    
    // 转换状态更新回调
    var conversionProgress = PassthroughSubject<ConversionProgress, Error>()
    
    // 错误枚举
    enum ConversionError: Error {
        case uploadFailed(String)
        case taskCreationFailed(String) // 新增
        case pollingFailed(String)
        case downloadFailed(String)
        case invalidResponse
        case taskTimeout
        case taskFailed(String)
        case unsupportedImageFormat
    }
    
    struct ConversionProgress {
        let progress: Int
        let status: String
        let modelURL: URL?
    }
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// 将图片转换为3D模型
    /// - Parameter image: 要转换的UIImage
    func convertImageTo3D(_ image: UIImage) {
        print("开始转换图片为3D模型...")
        print("图片尺寸: \(image.size)")
        
        // 1. 上传图片
        uploadImage(image)
            .flatMap { [weak self] (imageToken, fileType) -> AnyPublisher<String, Error> in
                guard let self = self else {
                    return Fail(error: ConversionError.uploadFailed("Self is nil")).eraseToAnyPublisher()
                }
                // 使用 image_token 和文件类型创建任务
                return self.createTask(imageToken: imageToken, fileType: fileType)
            }
            .flatMap { [weak self] taskId -> AnyPublisher<ConversionProgress, Error> in
                guard let self = self else {
                    return Fail(error: ConversionError.taskCreationFailed("Self is nil")).eraseToAnyPublisher()
                }
                // 使用 taskId 轮询状态
                return self.pollTaskStatus(taskId: taskId)
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        // 转换完成，无需额外处理
                        break
                    case .failure(let error):
                        // 发送错误到进度流
                        self?.conversionProgress.send(completion: .failure(error))
                    }
                },
                receiveValue: { [weak self] progress in
                    // 3. 发送进度更新
                    self?.conversionProgress.send(progress)
                    
                    // 4. 如果转换成功，下载模型
                    if progress.status == "success", let modelURL = progress.modelURL {
                        print(modelURL)
                        self?.downloadModel(from: modelURL)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 上传图片到API
    private func uploadImage(_ image: UIImage) -> AnyPublisher<(String, String), Error> {
        Future<(String, String), Error> { promise in
            print("开始上传图片...")
            
            // 检查图片大小
            print("图片尺寸: \(image.size)")
            
            // 确定文件类型
            let fileType: String
            var imageData: Data?
            
            // 优先尝试 JPEG
            if let jpegData = image.jpegData(compressionQuality: 0.9) {
                fileType = "jpg"
                imageData = jpegData
            }
            // 其次尝试 PNG
            else if let pngData = image.pngData() {
                fileType = "png"
                imageData = pngData
            }
            // 最后尝试其他格式
            else {
                print("错误：无法将图片转换为支持格式")
                promise(.failure(ConversionError.uploadFailed("无法将图片转换为JPEG或PNG格式")))
                return
            }
            
            guard let finalImageData = imageData else {
                print("错误：无法获取图片数据")
                promise(.failure(ConversionError.uploadFailed("无法获取图片数据")))
                return
            }
            
            print("图片大小: \(Double(finalImageData.count) / 1024.0) KB, 类型: \(fileType)")
            
            let url = URL(string: "\(self.baseURL)/upload/sts")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            // 添加文件数据
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.\(fileType)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/\(fileType)\r\n\r\n".data(using: .utf8)!)
            body.append(finalImageData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("上传错误: \(error.localizedDescription)")
                    promise(.failure(ConversionError.uploadFailed(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("错误：无效的响应类型")
                    promise(.failure(ConversionError.uploadFailed("无效的响应类型")))
                    return
                }
                
                print("上传HTTP状态码: \(httpResponse.statusCode)")
                
                // 处理非成功状态码
                if !(200...299).contains(httpResponse.statusCode) {
                    let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "无响应体"
                    print("错误响应体: \(body)")
                    promise(.failure(ConversionError.uploadFailed("HTTP \(httpResponse.statusCode): \(body)")))
                    return
                }
                
                // 确保有数据可供解析
                guard let responseData = data else {
                    print("错误：没有响应数据")
                    promise(.failure(ConversionError.uploadFailed("没有响应数据")))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                        print("上传完整API响应: \(json)")
                        
                        if let code = json["code"] as? Int, code != 0 {
                            let message = json["message"] as? String ?? "未知错误"
                            print("API返回错误代码: \(code), 消息: \(message)")
                            promise(.failure(ConversionError.uploadFailed("API错误 \(code): \(message)")))
                            return
                        }
                        
                        guard let dataDict = json["data"] as? [String: Any],
                              let imageToken = dataDict["image_token"] as? String else {
                            print("错误：缺少 image_token 字段")
                            promise(.failure(ConversionError.uploadFailed("响应缺少 image_token 字段")))
                            return
                        }
                        
                        print("成功获取 image_token: \(imageToken)")
                        promise(.success((imageToken, fileType))) // 返回元组 (token, type)
                    } else {
                        promise(.failure(ConversionError.uploadFailed("无法解析JSON响应")))
                    }
                } catch {
                    promise(.failure(ConversionError.uploadFailed("JSON解析错误: \(error.localizedDescription)")))
                }
            }
            
            task.resume()
        }
        .eraseToAnyPublisher()
    }
    
    /// 创建3D转换任务
    private func createTask(imageToken: String, fileType: String) -> AnyPublisher<String, Error> {
        Future<String, Error> { promise in
            print("创建3D转换任务，使用 image_token: \(imageToken)")
            
            guard let url = URL(string: "\(self.baseURL)/task") else {
                promise(.failure(ConversionError.taskCreationFailed("无效的URL")))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // 使用正确的请求格式
            let requestBody: [String: Any] = [
                "type": "image_to_model",
                "file": [
                    "type": fileType,  // 图片类型 (jpg, png, webp)
                    "file_token": imageToken
                ]
            ]
            
            print("创建任务请求体: \(requestBody)")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                
                // 打印完整的请求详情
                print("请求URL: \(url.absoluteString)")
                if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
                    print("请求体JSON: \(bodyString)")
                }
            } catch {
                print("JSON序列化错误: \(error)")
                promise(.failure(ConversionError.taskCreationFailed("创建请求体失败: \(error)")))
                return
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("请求错误: \(error.localizedDescription)")
                    promise(.failure(ConversionError.taskCreationFailed(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("错误：无效的响应类型")
                    promise(.failure(ConversionError.taskCreationFailed("无效的响应类型")))
                    return
                }
                
                print("创建任务HTTP状态码: \(httpResponse.statusCode)")
                
                // 确保有数据可供解析
                guard let responseData = data else {
                    print("错误：没有响应数据")
                    promise(.failure(ConversionError.taskCreationFailed("没有响应数据")))
                    return
                }
                
                // 打印原始响应用于调试
                if let responseString = String(data: responseData, encoding: .utf8) {
                    print("创建任务原始响应: \(responseString)")
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                        print("创建任务完整API响应: \(json)")
                        
                        // 检查API返回的错误代码
                        if let code = json["code"] as? Int, code != 0 {
                            let message = json["message"] as? String ?? "未知错误"
                            print("API返回错误代码: \(code), 消息: \(message)")
                            
                            // 添加详细的错误建议
                            var errorMessage = "API错误 \(code): \(message)"
                            if let suggestion = json["suggestion"] as? String {
                                errorMessage += "\n建议: \(suggestion)"
                            }
                            
                            promise(.failure(ConversionError.taskCreationFailed(errorMessage)))
                            return
                        }
                        
                        guard let dataDict = json["data"] as? [String: Any],
                              let taskId = dataDict["task_id"] as? String else {
                            print("错误：缺少 task_id 字段")
                            promise(.failure(ConversionError.taskCreationFailed("响应缺少 task_id 字段")))
                            return
                        }
                        
                        print("成功创建任务，task_id: \(taskId)")
                        promise(.success(taskId))
                    } else {
                        print("错误：无法解析JSON")
                        promise(.failure(ConversionError.taskCreationFailed("无法解析JSON响应")))
                    }
                } catch {
                    print("JSON解析错误: \(error.localizedDescription)")
                    promise(.failure(ConversionError.taskCreationFailed("JSON解析错误: \(error.localizedDescription)")))
                }
            }
            
            task.resume()
        }
        .eraseToAnyPublisher()
    }
    
    /// 轮询任务状态
    private func pollTaskStatus(taskId: String) -> AnyPublisher<ConversionProgress, Error> {
        let url = URL(string: "\(baseURL)/task/\(taskId)")!
        
        return Timer.publish(every: 5, on: .main, in: .default)
            .autoconnect()
            .flatMap { _ in
                Future<ConversionProgress, Error> { promise in
                    print("开始轮询任务状态: \(url.absoluteString)")
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
                    
                    let task = URLSession.shared.dataTask(with: request) { data, response, error in
                        if let error = error {
                            print("轮询错误: \(error.localizedDescription)")
                            promise(.failure(ConversionError.pollingFailed(error.localizedDescription)))
                            return
                        }
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            print("错误：无效的响应类型")
                            promise(.failure(ConversionError.pollingFailed("无效的响应类型")))
                            return
                        }
                        
                        print("轮询HTTP状态码: \(httpResponse.statusCode)")
                        
                        // 处理非成功状态码
                        if !(200...299).contains(httpResponse.statusCode) {
                            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "无响应体"
                            print("错误响应体: \(body)")
                            promise(.failure(ConversionError.pollingFailed("HTTP \(httpResponse.statusCode): \(body)")))
                            return
                        }
                        
                        // 确保有数据可供解析
                        guard let responseData = data else {
                            print("错误：没有响应数据")
                            promise(.failure(ConversionError.pollingFailed("没有响应数据")))
                            return
                        }
                        
                        // 打印原始响应用于调试
                        if let responseString = String(data: responseData, encoding: .utf8) {
                            print("原始轮询响应: \(responseString)")
                        }
                        
                        do {
                            // 使用非可选的 responseData
                            if let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                                print("轮询完整API响应: \(json)")
                                
                                // 检查API返回的错误代码
                                if let code = json["code"] as? Int, code != 0 {
                                    let message = json["message"] as? String ?? "未知错误"
                                    print("API返回错误代码: \(code), 消息: \(message)")
                                    promise(.failure(ConversionError.pollingFailed("API错误 \(code): \(message)")))
                                    return
                                }
                                
                                guard let dataDict = json["data"] as? [String: Any] else {
                                    print("错误：缺少data字段")
                                    promise(.failure(ConversionError.pollingFailed("响应缺少data字段")))
                                    return
                                }
                                
                                guard let status = dataDict["status"] as? String else {
                                    print("错误：缺少status字段")
                                    promise(.failure(ConversionError.pollingFailed("响应缺少status字段")))
                                    return
                                }
                                
                                let progress = dataDict["progress"] as? Int ?? 0
                                
                                var modelURL: URL?
                                // 尝试多种可能的状态值和URL路径
                                if status == "success" {
                                    print("3D模型生成成功")
                                    
                                    if let output = dataDict["output"] as? [String: Any] {
                                        modelURL = (output["pbr_model"] as? String).flatMap { URL(string: $0) }
                                    }
                                    
                                    // 如果没有从output获取到URL，尝试从data获取
                                    modelURL = modelURL ?? (dataDict["pbr_model"] as? String).flatMap { URL(string: $0) }
                                    
                                    // 如果模型URL存在，开始下载
                                    if let modelURL = modelURL {
                                        print("模型下载链接: \(modelURL)")
                                        
                                        // 下载模型
                                        self.downloadModel(from: modelURL)
                                        
                                        // 停止轮询
                                        self.conversionProgress.send(ConversionProgress(
                                            progress: 100,
                                            status: "download_complete",
                                            modelURL: modelURL
                                        ))
                                        
                                        // 发送完成事件，终止轮询
                                        promise(.success(ConversionProgress(progress: 100, status: "download_complete", modelURL: modelURL)))
                                        return
                                    }
                                }
                                
                                let conversionProgress = ConversionProgress(
                                    progress: progress,
                                    status: status,
                                    modelURL: modelURL
                                )
                                
                                promise(.success(conversionProgress))
                            } else {
                                print("错误：无法解析JSON")
                                promise(.failure(ConversionError.pollingFailed("无法解析JSON响应")))
                            }
                        } catch {
                            print("JSON解析错误: \(error.localizedDescription)")
                            promise(.failure(ConversionError.pollingFailed("JSON解析错误: \(error.localizedDescription)")))
                        }
                    }
                    
                    task.resume()
                }
            }
            .timeout(.seconds(600), scheduler: DispatchQueue.main, customError: {
                ConversionError.taskTimeout
            })
            .eraseToAnyPublisher()
    }
    
    /// 下载3D模型
    func downloadModel(from url: URL) {
        print("开始下载模型: \(url.absoluteString)")
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("下载错误: \(error.localizedDescription)")
                self.conversionProgress.send(completion: .failure(ConversionError.downloadFailed(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let localURL = localURL else {
                print("下载失败: HTTP状态码或本地URL无效")
                self.conversionProgress.send(completion: .failure(ConversionError.downloadFailed("下载失败")))
                return
            }
            
            print("下载成功，临时文件位置: \(localURL.path)")
            
            // 保存到应用的 Documents 目录（沙盒内）
            let fileManager = FileManager.default
            let documentsDirectory: URL
            do {
                documentsDirectory = try fileManager.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
            } catch {
                print("无法获取 Documents 目录: \(error.localizedDescription)")
                self.conversionProgress.send(completion: .failure(error))
                return
            }
            
            // 生成唯一文件名
            let fileName = "3DModel_\(UUID().uuidString).glb"
            let destinationURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                try fileManager.moveItem(at: localURL, to: destinationURL)
                print("模型已保存到沙盒: \(destinationURL.path)")
                
                // 发送下载完成事件
                self.conversionProgress.send(ConversionProgress(
                    progress: 100,
                    status: "download_complete",
                    modelURL: destinationURL
                ))
                
                // 自动触发分享（导出到文件 App）
                DispatchQueue.main.async {
                    self.triggerFileExport(url: destinationURL)
                }
                
            } catch {
                print("文件移动失败: \(error.localizedDescription)")
                self.conversionProgress.send(completion: .failure(ConversionError.downloadFailed(error.localizedDescription)))
            }
        }
        
        task.resume()
    }
    
    // 触发系统分享菜单，让用户选择保存位置
    private func triggerFileExport(url: URL) {
        // 1. 获取当前活跃的 window scene
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            print("无法获取当前 window scene")
            return
        }
        
        // 2. 从 window scene 获取 key window
        guard let rootViewController = windowScene.windows
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("无法获取根视图控制器")
            return
        }
        
        // 3. 弹出文件导出菜单
        let documentPicker = UIDocumentPickerViewController(forExporting: [url])
        documentPicker.shouldShowFileExtensions = true
        rootViewController.present(documentPicker, animated: true)
    }
}

extension ImageTo3DConverterClient.ConversionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .uploadFailed(let message):
            return message.contains("offline") ? "网络连接已断开，请检查您的网络设置" : "上传失败: \(message)"
        case .taskCreationFailed(let message):
            return message.contains("offline") ? "网络连接已断开，请检查您的网络设置" : "任务创建失败: \(message)"
        case .pollingFailed(let message):
            return message.contains("offline") ? "网络连接已断开，请检查您的网络设置" : "获取进度失败: \(message)"
        case .downloadFailed(let message):
            return message.contains("offline") ? "网络连接已断开，请检查您的网络设置" : "下载失败: \(message)"
        case .invalidResponse:
            return "服务器返回了无效响应"
        case .taskTimeout:
            return "转换超时，请稍后重试"
        case .taskFailed(let status):
            return "转换失败: \(status)"
        case .unsupportedImageFormat:
            return "不支持的图片格式"
        }
    }
}
