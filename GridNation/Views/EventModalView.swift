//
//  EventModalView.swift
//  GridNation
//
//  Modal card that displays events and choices to the player
//

import SwiftUI

struct EventModalView: View {
    let event: GameEvent
    let onChoice: (EventChoice) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text(event.title)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(textColor)
            
            // Description
            Text(event.description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(textColor.opacity(0.9))
                .lineLimit(3)
                .padding(.horizontal, 8)
            
            Divider()
                .background(textColor.opacity(0.3))
                .padding(.vertical, 4)
            
            // Choices
            VStack(spacing: 10) {
                ForEach(event.choices, id: \.id) { choice in
                    Button {
                        onChoice(choice)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(choice.text)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(textColor)
                            
                            // Show effects
                            HStack(spacing: 10) {
                                if let money = choice.moneyChange, money != 0 {
                                    EffectLabel(
                                        value: money,
                                        format: "$%.0f",
                                        isPositive: money > 0,
                                        textColor: textColor
                                    )
                                }
                                if let stability = choice.stabilityChange, stability != 0 {
                                    EffectLabel(
                                        value: stability,
                                        format: "%.0f stability",
                                        isPositive: stability > 0,
                                        textColor: textColor
                                    )
                                }
                                if let tension = choice.worldTensionChange, tension != 0 {
                                    EffectLabel(
                                        value: tension,
                                        format: "%.0f tension",
                                        isPositive: tension < 0,  // Lower tension is good
                                        textColor: textColor
                                    )
                                }
                            }
                            .font(.caption2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(textColor.opacity(0.15))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: 500)
        .background(backgroundColor)
        .cornerRadius(16)
        .shadow(radius: 20)
        .padding(30)
    }
    
    /// Background color based on event type
    private var backgroundColor: Color {
        switch event.eventType {
        case .good:
            return .green.opacity(0.9)
        case .political:
            return .blue.opacity(0.9)
        case .riot:
            return .red.opacity(0.9)
        case .neutral:
            return .gray.opacity(0.9)
        }
    }
    
    /// Text color that contrasts with the background
    private var textColor: Color {
        switch event.eventType {
        case .good, .political, .riot:
            return .white
        case .neutral:
            return .primary
        }
    }
}

/// Shows effect value with color
struct EffectLabel: View {
    let value: Double
    let format: String
    let isPositive: Bool
    let textColor: Color
    
    var body: some View {
        let sign = value > 0 ? "+" : ""
        let formatted = String(format: format, value)
        
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.caption2)
            Text("\(sign)\(formatted)")
        }
        .foregroundColor(textColor.opacity(0.9))
        .fontWeight(.medium)
    }
}

//#Preview {
//    ZStack {
//        Color.gray.ignoresSafeArea()
//        EventModalView(event: GameEvent.randomEvent()) { choice in
//            print("Selected: \(choice.text)")
//        }
//    }
//}

