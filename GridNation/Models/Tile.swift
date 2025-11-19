//
//  Tile.swift
//  GridNation
//
//  Represents a single tile in the grid
//

import Foundation

/// A single tile in the city grid
struct Tile: Codable, Identifiable {
    let id: UUID
    let x: Int
    let y: Int
    var type: TileType
    
    init(x: Int, y: Int, type: TileType = .empty) {
        self.id = UUID()
        self.x = x
        self.y = y
        self.type = type
    }
}

