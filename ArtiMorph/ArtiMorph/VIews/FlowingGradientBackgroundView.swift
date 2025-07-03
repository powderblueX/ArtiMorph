//
//  FlowingGradientBackgroundView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/29.
//

import SwiftUI

struct FlowingGradientBackgroundView: View {
    @State private var startPoint: UnitPoint = .topLeading
    @State private var endPoint: UnitPoint = .bottomTrailing
    @State var Color_1: Color
    @State var Color_2: Color
    @State var duration: TimeInterval
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color_1, Color_2]),
            startPoint: startPoint,
            endPoint: endPoint
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(Animation.linear(duration: duration).repeatForever()) {
                startPoint = .bottomLeading
                endPoint = .topTrailing
            }
        }
    }
}

#Preview {
    FlowingGradientBackgroundView(Color_1: Color.blue.opacity(0.5), Color_2: Color.mint.opacity(0.7), duration: 1)
}

