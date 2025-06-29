//
//  ModelCardView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/29.
//

import SwiftUI

struct ModelCardView: View {
    let model: ARModel
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .aspectRatio(1, contentMode: .fit)
                
                Image(systemName: "cube.transparent")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
            }
            
            Text(model.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
