//
//  TileType.swift
//  GridNation
//
//  Defines the types of tiles that can exist in the world
//

import SwiftUI
import SpriteKit

/// Represents different types of tiles on the grid
enum TileType: String, Codable, CaseIterable {
    // Buildable tiles
    case empty      // Empty/unused land
    case residential // Houses people
    case commercial  // Generates money
    case industrial  // Generates money but pollution
    case park        // Increases stability
    case military    // Defense/attack capability
    
    // Terrain (non-buildable)
    case water      // Cannot build here
    case mountain   // Cannot build here
    
    /// The color used to render this tile type (SwiftUI Color)
    var color: Color {
        switch self {
        case .empty:
            return Color.gray.opacity(0.3)
        case .residential:
            return Color.yellow
        case .commercial:
            return Color.blue
        case .industrial:
            return Color.orange
        case .park:
            return Color.green
        case .military:
            return Color.red
        case .water:
            return Color.cyan
        case .mountain:
            return Color.brown
        }
    }
    
    /// The color used for SpriteKit rendering (SKColor)
    /// This uses the same color definitions as the SwiftUI color
    var skColor: SKColor {
        switch self {
        case .empty:
            return SKColor.gray.withAlphaComponent(0.3)
        case .residential:
            return SKColor.yellow
        case .commercial:
            return SKColor.blue
        case .industrial:
            return SKColor.orange
        case .park:
            return SKColor.green
        case .military:
            return SKColor.red
        case .water:
            return SKColor.cyan
        case .mountain:
            return SKColor.brown
        }
    }
    
    /// Display name for UI
    var displayName: String {
        rawValue.capitalized
    }
    
    /// Whether this tile is terrain (non-buildable)
    var isTerrain: Bool {
        switch self {
        case .water, .mountain:
            return true
        default:
            return false
        }
    }
    
    /// All buildable tile types (excludes terrain)
    static var buildableTypes: [TileType] {
        [.empty, .residential, .commercial, .industrial, .park, .military]
    }
    
    /// Cycles to the next buildable tile type
    func next() -> TileType {
        // Only cycle through buildable types
        let buildable = TileType.buildableTypes
        guard let currentIndex = buildable.firstIndex(of: self) else {
            return .empty
        }
        let nextIndex = (currentIndex + 1) % buildable.count
        return buildable[nextIndex]
    }
}

