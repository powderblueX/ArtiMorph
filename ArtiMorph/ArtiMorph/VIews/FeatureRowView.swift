//
//  FeatureRowView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/28.
//

import SwiftUI

struct FeatureRowView: View {
    // MARK: - 属性
    
    let iconName: String
    let text: String
    
    // MARK: - 视图主体
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}
