//
//  ARModel.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/29.
//

import Foundation

struct ARModel: Identifiable {
    let id: UUID
    let name: String
    let url: URL
    var modificationDate: Date {
        get {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                return attributes[.modificationDate] as? Date ?? Date.distantPast
            } catch {
                return Date.distantPast
            }
        }
    }
}
