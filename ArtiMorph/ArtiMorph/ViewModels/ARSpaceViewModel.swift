//
//  ARSpaceViewModel.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/6.
//

import RealityKit
import ARKit

class ARSpaceViewModel: NSObject, ObservableObject {
    @Published var selectedModel: ARModel? = nil
    var arView: ARView?
    @Published var currentMode: InteractionMode = .select
    
    // 新增模型控制状态
    var selectedEntity: ModelEntity? = nil
    var anchorEntities: [AnchorEntity] = []
    var modelEntities: [ModelEntity] = []
    var isDragging = false
    var currentRotation: Float = 0.0
    var originalRotation: simd_quatf?
    
    var currentScale: Float = 1.0
    var originalScale: Float = 1.0
    
    // 拖动相关临时变量
    private var dragStartLocation: CGPoint?
    private var dragStartPosition: SIMD3<Float>?
    
    func setupARView(_ arView: ARView) {
        // 直接赋值而不触发发布
        self.arView = arView
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        self.setupGestures()
    }
    
    private func setupGestures() {
        guard let arView = self.arView else { return }
        
        // 1. 先移除所有现有手势
        arView.gestureRecognizers?.forEach {
            arView.removeGestureRecognizer($0)
        }
        
        // 2. 重新添加手势
        // 单指点击 - 放置/选择/删除
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // 单指拖动 - 移动
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(panGesture)
        
        // 双指旋转
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotation(_:)))
        rotationGesture.delegate = self
        arView.addGestureRecognizer(rotationGesture)
        
        // 双指缩放
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
        pinchGesture.delegate = self
        arView.addGestureRecognizer(pinchGesture)
        
        // 3. 设置手势依赖关系
        tapGesture.require(toFail: panGesture)
        tapGesture.require(toFail: rotationGesture)
        tapGesture.require(toFail: pinchGesture)
        
        // 4. 启用用户交互
        arView.isUserInteractionEnabled = true
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        let location = sender.location(in: arView)
        
        switch currentMode {
        case .select:
            // 选择模型逻辑
            if let entity = arView.entity(at: location) as? ModelEntity {
                // 确保实体在模型列表中
                if modelEntities.contains(entity) {
                    selectEntity(entity)
                }
            } else {
                deselectAllEntities()
            }
            
        case .delete:
            // 删除模型逻辑
            if let entity = arView.entity(at: location) as? ModelEntity {
                deleteEntity(entity)
            }
            
        case .place:
            // 放置模型逻辑
            if let model = selectedModel {
                placeModel(model, at: location)
            }
        }
    }
    
    private func placeModel(_ model: ARModel, at location: CGPoint) {
        guard let arView = self.arView else { return }
        
        // 修复射线检测方式
        if let raycast = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal).first {
            let anchorEntity = AnchorEntity(world: raycast.worldTransform)
            
            do {
                let entity = try Entity.loadModel(contentsOf: model.url)
                entity.scale = SIMD3<Float>(repeating: 0.3)
                entity.generateCollisionShapes(recursive: true)
                
                let bounds = entity.visualBounds(relativeTo: nil)
                entity.position.y += bounds.extents.y / 2
                
                anchorEntity.addChild(entity)
                arView.scene.addAnchor(anchorEntity)
                
                // 维护模型和锚点数组
                modelEntities.append(entity)
                anchorEntities.append(anchorEntity)
                
                // 自动切换到选择模式并选中新模型
                currentMode = .select
                selectEntity(entity)
                
                print("成功放置模型")
            } catch {
                print("模型加载失败: \(error)")
            }
        } else {
            print("放置失败: 未检测到平面")
        }
    }
    
    private func selectEntity(_ entity: ModelEntity) {
        // 清除所有实体的高亮
        deselectAllEntities()
        
        // 设置当前选中实体
        selectedEntity = entity
        
        // 添加高亮效果（使用黄色材质）
        var material = SimpleMaterial()
        material.color = .init(tint: .white)  // Set base color (e.g., white)
        material.metallic = MaterialScalarParameter(floatLiteral: 0.5)  // Metallic value (0-1)
        material.roughness = MaterialScalarParameter(floatLiteral: 0.5)  // Roughness value (0-1)
        
        // 创建高亮边框
        let bounds = entity.visualBounds(relativeTo: nil)
        let box = ModelEntity(
            mesh: .generateBox(size: bounds.extents * 1.1),
            materials: [material]
        )
        box.position = bounds.center
        box.isEnabled = true
        
        // 添加为子实体
        entity.addChild(box)
    }
    
    func deselectAllEntities() {
        selectedEntity = nil
        
        // 移除所有高亮边框
        for entity in modelEntities {
            for child in entity.children {
                if child is ModelEntity {
                    child.removeFromParent()
                }
            }
        }
    }
    
    private func deleteEntity(_ entity: ModelEntity) {
        guard let index = modelEntities.firstIndex(of: entity) else { return }
        
        // 移除实体
        anchorEntities[index].removeFromParent()
        
        // 从数组中移除
        anchorEntities.remove(at: index)
        modelEntities.remove(at: index)
        
        // 如果删除的是当前选中的实体，清除选择
        if selectedEntity == entity {
            selectedEntity = nil
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let arView = self.arView,
              let selectedEntity = self.selectedEntity,
              let anchor = anchorEntities.first(where: { $0.children.contains(selectedEntity) })
        else { return }
        
        let location = gesture.location(in: arView)
        
        switch gesture.state {
        case .began:
            print("开始拖动")
            // 记录初始位置
            self.dragStartPosition = selectedEntity.position(relativeTo: nil)
            self.dragStartLocation = location
            isDragging = true
            
        case .changed:
            guard isDragging,
                  let startLocation = dragStartLocation,
                  let startPosition = dragStartPosition
            else { return }
            
            // 计算屏幕移动距离
            let translation = gesture.translation(in: arView)
            
            // 将2D平移转换为3D位移（基于摄像机方向）
            let translation3D = self.convertScreenTranslation(translation, in: arView) * 0.5
            
            // 应用新位置
            let newPosition = startPosition + translation3D
            selectedEntity.setPosition(newPosition, relativeTo: nil)
            print("正在拖动")
            
        case .ended, .cancelled:
            print("拖动结束")
            isDragging = false
            dragStartLocation = nil
            dragStartPosition = nil
            
        default:
            isDragging = false
        }
    }
    
    // 替代方案：使用更直接的转换方法
    private func convertScreenTranslation(_ translation: CGPoint, in arView: ARView) -> SIMD3<Float> {
        let cameraTransform = arView.cameraTransform
        
        // 获取相机变换矩阵
        let cameraMatrix = cameraTransform.matrix
        
        // 提取方向向量
        let right = SIMD3<Float>(cameraMatrix.columns.0.x, cameraMatrix.columns.0.y, cameraMatrix.columns.0.z)
        let up = SIMD3<Float>(cameraMatrix.columns.1.x, cameraMatrix.columns.1.y, cameraMatrix.columns.1.z)
        
        // 计算3D位移
        let sensitivity: Float = 0.001
        let horizontalMovement = right * Float(translation.x) * sensitivity
        let verticalMovement = up * Float(-translation.y) * sensitivity  // 反转Y轴
        
        return horizontalMovement + verticalMovement
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        // 只处理选中模型的缩放
        guard let entity = self.selectedEntity else { return }
        
        switch gesture.state {
        case .began:
            // 记录原始缩放值
            self.originalScale = entity.scale.x
            self.currentScale = self.originalScale
            print("handlePinch")
        case .changed:
            // 计算新的缩放值
            let scaleFactor = Float(gesture.scale)
            self.currentScale = self.originalScale * scaleFactor
            
            // 应用缩放（保持均匀缩放）
            entity.scale = SIMD3<Float>(repeating: self.currentScale)
            
        case .ended, .cancelled:
            // 更新原始缩放值
            self.originalScale = self.currentScale
            
        default:
            break
        }
    }
    
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let selectedEntity = selectedEntity,
              let anchor = anchorEntities.first(where: { $0.children.contains(selectedEntity) }) else { return }
        
        switch gesture.state {
        case .began:
            originalRotation = selectedEntity.transform.rotation
            currentRotation = 0.0
            print("handleRotation")
        case .changed:
            let deltaAngle = Float(gesture.rotation)
            gesture.rotation = 0
            currentRotation += deltaAngle
            
            let worldRotation = simd_quatf(angle: currentRotation, axis: [0, 1, 0])
            let combinedRotation = worldRotation * originalRotation!
            
            var newTransform = selectedEntity.transform
            newTransform.rotation = combinedRotation
            selectedEntity.move(to: newTransform, relativeTo: anchor)
        default:
            break
        }
    }
}

extension ARSpaceViewModel: UIGestureRecognizerDelegate {
    // 1. 允许同时识别多个手势
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 允许所有手势同时识别
        return true
    }
    
    // 2. 手势应该开始
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 移动手势：只允许单指
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            return panGesture.numberOfTouches == 1
        }
        
        // 旋转和缩放手势：只允许双指
        if gestureRecognizer is UIRotationGestureRecognizer || gestureRecognizer is UIPinchGestureRecognizer {
            return gestureRecognizer.numberOfTouches == 2
        }
        
        return true
    }
    
    // 3. 移除手势冲突限制
    // func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    //     return false
    // }
}

enum InteractionMode {
    case select   // 选择模式
    case delete   // 删除模式
    case place    // 放置模式
}

// 添加这些扩展以支持向量计算
extension float4x4 {
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension SIMD3 where Scalar == Float {
    func length() -> Float {
        return sqrt(x * x + y * y + z * z)
    }
    
    func normalized() -> SIMD3<Float> {
        let len = length()
        return len > 0 ? self / len : self
    }
}

func cross(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> {
    return SIMD3<Float>(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
}

func normalize(_ vector: SIMD3<Float>) -> SIMD3<Float> {
    let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    if length > 0 {
        return vector / length
    }
    return vector
}
