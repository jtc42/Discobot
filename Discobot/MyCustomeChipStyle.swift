//
//  ChipStyle.swift
//  Discobot
//
//  Created by Joel Collins on 26/05/2024.
//

import SwiftUI

struct MyCustomeChipStyle: ChipStyle {
    func makeBody(configuration: Configuration) -> some View {
        MyCustomeChipStyle(configuration: configuration)
    }
    
    private struct MyCustomeChipStyle: View {
        // MARK: Constants
        
        private let textFont = Font.subheadline
        
        private let backgroundUnselectedColor = Color(UIColor.systemBackground).opacity(0.5)
        private let backgroundSelectedColor = Color.accentColor
        private let borderColor = Color.accentColor
        
        private let height: CGFloat = 32
        private let radius: CGFloat = 16
        private let configuration: ChipStyleConfiguration
        
        init(configuration: ChipStyleConfiguration) {
            self.configuration = configuration
        }
        
        private var backgroundColor: Color {
            configuration.$isOn.wrappedValue
                ? backgroundSelectedColor
                : backgroundUnselectedColor
        }
        
        private var fontColor: Color {
            configuration.$isOn.wrappedValue ? .white : .accentColor
        }
        
        var body: some View {
            configuration
                .label
                .font(textFont)
                .foregroundColor(fontColor)
                .lineLimit(1)
                .frame(height: height)
                .padding(.horizontal, 4)
                .background(backgroundColor)
                .clipShape(.rect(cornerRadius: radius)) // Background radius
                .overlay( // Draw border
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(borderColor, lineWidth: 1)
                )
                .animation(.default, value: configuration.isOn)
        }
    }
}
