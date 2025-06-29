import SwiftUI

struct ColorPickerView: View {
    let colors: [Color]
    let selectedColor: Color
    let onColorSelected: (Color) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Group {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                if selectedColor == color {
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 3)
                                        .scaleEffect(1.1)
                                }
                            }
                        )
                        .onTapGesture {
                            onColorSelected(color)
                        }
                }
            }
            .padding()
        }
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}