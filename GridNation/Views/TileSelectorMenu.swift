//
//  TileSelectorMenu.swift
//  GridNation
//
//  Radial menu for selecting tile types (GTA 5 weapon wheel style)
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

struct TileSelectorMenu: View {
    let position: CGPoint
    let buildableTiles: [TileType]
    @Binding var selectedType: TileType?
    let onSelect: (TileType) -> Void
    let onCancel: () -> Void
    
    @State private var dragLocation: CGPoint = .zero
    @State private var hoveredType: TileType?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 220, height: 220)
                    .blur(radius: 5)
                
                // Outer ring
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 200, height: 200)
                
                // Inner circle
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                // Tile options arranged in circle
                ForEach(Array(buildableTiles.enumerated()), id: \.element) { index, tileType in
                    let angle = angleForIndex(index, total: buildableTiles.count)
                    let isHovered = hoveredType == tileType
                    
                    TileOption(
                        tileType: tileType,
                        isSelected: isHovered,
                        angle: angle
                    )
                }
                
                // Center hint text
                if let hovered = hoveredType {
                    Text(hovered.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(6)
                } else {
                    Text("Drag to select")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .position(x: position.x, y: position.y)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragLocation = value.location
                        updateHoveredType(at: value.location, center: position)
                    }
                    .onEnded { _ in
                        if let hovered = hoveredType {
                            onSelect(hovered)
                        } else {
                            onCancel()
                        }
                    }
            )
        }
    }
    
    private func angleForIndex(_ index: Int, total: Int) -> Double {
        let angleStep = 360.0 / Double(total)
        return Double(index) * angleStep - 90 // Start from top
    }
    
    private func updateHoveredType(at location: CGPoint, center: CGPoint) {
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        let previousHovered = hoveredType
        
        // Only select if dragging outside inner circle
        if distance > 30 {
            var angle = atan2(dy, dx) * 180 / .pi + 90
            if angle < 0 { angle += 360 }
            
            let segmentAngle = 360.0 / Double(buildableTiles.count)
            let index = Int((angle + segmentAngle / 2) / segmentAngle) % buildableTiles.count
            hoveredType = buildableTiles[index]
        } else {
            hoveredType = nil
        }
        
        // Haptic feedback on selection change
        #if os(iOS)
        if previousHovered != hoveredType && hoveredType != nil {
            let feedback = UISelectionFeedbackGenerator()
            feedback.selectionChanged()
        }
        #endif
    }
}

struct TileOption: View {
    let tileType: TileType
    let isSelected: Bool
    let angle: Double
    
    var body: some View {
        ZStack {
            // Selection indicator - larger and more visible
            if isSelected {
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 60, height: 60)
                
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 60, height: 60)
            }
            
            // Tile color square
            RoundedRectangle(cornerRadius: 8)
                .fill(tileType.color)
                .frame(width: isSelected ? 45 : 35, height: isSelected ? 45 : 35)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: isSelected ? 4 : 2)
                )
                .shadow(color: isSelected ? Color.white.opacity(0.5) : .black.opacity(0.3), 
                       radius: isSelected ? 12 : 3)
        }
        .offset(x: cos(angle * .pi / 180) * 85, y: sin(angle * .pi / 180) * 85)
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSelected)
    }
}

#Preview {
    TileSelectorMenu(
        position: CGPoint(x: 200, y: 400),
        buildableTiles: TileType.buildableTypes,
        selectedType: .constant(nil),
        onSelect: { _ in },
        onCancel: {}
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray)
}

