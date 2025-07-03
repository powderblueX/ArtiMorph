//
//  ThumbnailGenerator.swift
//  ArtiMorph
//
//  Created by admin on 2025/7/3.
//

import UIKit
import QuickLook
import RealityKit

class ThumbnailGenerator {
    static func generateThumbnail(for url: URL, size: CGSize) -> UIImage? {
        let scale = UIScreen.main.scale
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )
        
        var resultImage: UIImage?
        let semaphore = DispatchSemaphore(value: 0)
        
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { thumbnail, error in
            resultImage = thumbnail?.uiImage
            semaphore.signal()
        }
        
        semaphore.wait()
        return resultImage
    }
}
