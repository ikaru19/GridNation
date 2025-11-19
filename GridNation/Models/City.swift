//
//  City.swift
//  GridNation
//
//  Represents the player's city with its grid and resources
//

import Foundation

/// Coordinate for a tile position
struct TileCoordinate: Codable, Hashable {
    let x: Int
    let y: Int
}

/// The player's city with a grid of tiles
struct City: Codable {
    var name: String
    var tiles: [[Tile]]  // 2D array of tiles [y][x]
    var money: Double
    var population: Int
    var stability: Double  // 0-100, higher is better
    var territoryBorder: Set<TileCoordinate> = []  // Tiles at the border of your territory
    
    let gridWidth: Int
    let gridHeight: Int
    let seed: Int  // Random seed for reproducible terrain
    
    init(name: String = "GridNation", width: Int = 20, height: Int = 20, generateTerrain: Bool = true, seed: Int? = nil) {
        self.name = name
        self.gridWidth = width
        self.gridHeight = height
        self.money = 1000.0
        self.population = 0
        self.stability = 75.0
        self.seed = seed ?? Int.random(in: 0...999999)
        
        // Initialize empty grid
        var grid: [[Tile]] = []
        for y in 0..<height {
            var row: [Tile] = []
            for x in 0..<width {
                row.append(Tile(x: x, y: y, type: .empty))
            }
            grid.append(row)
        }
        self.tiles = grid
        
        // Generate terrain features with seed
        if generateTerrain {
            generateTerrainFeatures()
        }
    }
    
    /// Generate natural-looking terrain (water bodies and mountains)
    private mutating func generateTerrainFeatures() {
        // Use seed for reproducible generation
        var rng = SeededRandomGenerator(seed: seed)
        
        // First, make all borders water to create an island
        for x in 0..<gridWidth {
            // Top and bottom borders
            tiles[0][x].type = .water
            tiles[gridHeight - 1][x].type = .water
        }
        for y in 0..<gridHeight {
            // Left and right borders
            tiles[y][0].type = .water
            tiles[y][gridWidth - 1].type = .water
        }
        
        // Add some extra water depth (2-3 tiles deep) for more natural coastline
        let borderDepth = rng.randomInt(in: 2...3)
        for depth in 1..<borderDepth {
            for x in depth..<(gridWidth - depth) {
                // Top and bottom
                if rng.randomDouble(in: 0...1) > 0.3 {
                    tiles[depth][x].type = .water
                    tiles[gridHeight - 1 - depth][x].type = .water
                }
            }
            for y in depth..<(gridHeight - depth) {
                // Left and right
                if rng.randomDouble(in: 0...1) > 0.3 {
                    tiles[y][depth].type = .water
                    tiles[y][gridWidth - 1 - depth].type = .water
                }
            }
        }
        
        // Generate moderate number of inland water bodies
        let waterBodies = rng.randomInt(in: 5...10)
        for _ in 0..<waterBodies {
            // Keep water bodies away from edges
            let centerX = rng.randomInt(in: 10..<(gridWidth - 10))
            let centerY = rng.randomInt(in: 10..<(gridHeight - 10))
            let size = rng.randomInt(in: 3...6)
            generateCluster(centerX: centerX, centerY: centerY, size: size, type: .water, rng: &rng)
        }
        
        // Generate mountain ranges (also away from borders)
        let mountainRanges = rng.randomInt(in: 8...15)
        for _ in 0..<mountainRanges {
            let centerX = rng.randomInt(in: 5..<(gridWidth - 5))
            let centerY = rng.randomInt(in: 5..<(gridHeight - 5))
            let size = rng.randomInt(in: 4...8)
            generateCluster(centerX: centerX, centerY: centerY, size: size, type: .mountain, rng: &rng)
        }
    }
    
    /// Generate a cluster of terrain tiles around a center point
    private mutating func generateCluster(centerX: Int, centerY: Int, size: Int, type: TileType, rng: inout SeededRandomGenerator) {
        for y in (centerY - size)...(centerY + size) {
            for x in (centerX - size)...(centerX + size) {
                // Check if within bounds
                guard x >= 0, x < gridWidth, y >= 0, y < gridHeight else { continue }
                
                // Don't overwrite existing terrain
                guard tiles[y][x].type == .empty else { continue }
                
                // Calculate distance from center
                let dx = x - centerX
                let dy = y - centerY
                let distance = sqrt(Double(dx * dx + dy * dy))
                
                // Use distance to determine if this tile should be terrain
                let threshold = Double(size) * rng.randomDouble(in: 0.6...0.9)
                if distance < threshold {
                    tiles[y][x].type = type
                }
            }
        }
    }
    
    /// Get tile at specific position
    func tile(at x: Int, y: Int) -> Tile? {
        guard y >= 0, y < tiles.count, x >= 0, x < tiles[y].count else {
            return nil
        }
        return tiles[y][x]
    }
    
    /// Set tile at specific position
    mutating func setTile(at x: Int, y: Int, type: TileType) {
        guard y >= 0, y < tiles.count, x >= 0, x < tiles[y].count else {
            return
        }
        tiles[y][x].type = type
    }
    
    /// Count tiles of a specific type (optimized with simple iteration)
    func countTiles(of type: TileType) -> Int {
        // Simple fast iteration - optimized by compiler
        var count = 0
        for row in tiles {
            for tile in row {
                if tile.type == type {
                    count += 1
                }
            }
        }
        return count
    }
    
    /// Expand territory border when a new building is placed
    mutating func expandTerritory(from x: Int, y: Int, radius: Int = 2) {
        // Add the building tile itself
        territoryBorder.insert(TileCoordinate(x: x, y: y))
        
        // Expand border in a radius around the building
        for dy in -radius...radius {
            for dx in -radius...radius {
                let newX = x + dx
                let newY = y + dy
                
                // Check if within grid bounds
                guard newX >= 0, newX < gridWidth, newY >= 0, newY < gridHeight else { continue }
                
                // Calculate distance (Manhattan distance for more natural borders)
                let distance = abs(dx) + abs(dy)
                if distance <= radius {
                    territoryBorder.insert(TileCoordinate(x: newX, y: newY))
                }
            }
        }
    }
    
    /// Check if a tile is within your territory border
    func isWithinTerritory(x: Int, y: Int) -> Bool {
        return territoryBorder.contains(TileCoordinate(x: x, y: y))
    }
    
    /// Calculate total border perimeter (for military calculations)
    func calculateBorderPerimeter() -> Int {
        var perimeterTiles = 0
        
        for coord in territoryBorder {
            // Check if this tile is on the edge of territory
            let neighbors = [
                (coord.x - 1, coord.y),
                (coord.x + 1, coord.y),
                (coord.x, coord.y - 1),
                (coord.x, coord.y + 1)
            ]
            
            // If any neighbor is outside territory, this is a border tile
            for (nx, ny) in neighbors {
                if nx < 0 || nx >= gridWidth || ny < 0 || ny >= gridHeight ||
                   !territoryBorder.contains(TileCoordinate(x: nx, y: ny)) {
                    perimeterTiles += 1
                    break
                }
            }
        }
        
        return perimeterTiles
    }
}

/// Seeded random number generator for reproducible terrain
struct SeededRandomGenerator {
    private var state: UInt64
    
    init(seed: Int) {
        self.state = UInt64(truncatingIfNeeded: seed)
        // Mix the seed
        for _ in 0..<10 {
            _ = next()
        }
    }
    
    private mutating func next() -> UInt64 {
        // Linear congruential generator
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
    
    mutating func randomInt(in range: Range<Int>) -> Int {
        let n = UInt64(range.count)
        let random = next()
        return range.lowerBound + Int(random % n)
    }
    
    mutating func randomInt(in range: ClosedRange<Int>) -> Int {
        let n = UInt64(range.count)
        let random = next()
        return range.lowerBound + Int(random % n)
    }
    
    mutating func randomDouble(in range: ClosedRange<Double>) -> Double {
        let random = Double(next()) / Double(UInt64.max)
        return range.lowerBound + random * (range.upperBound - range.lowerBound)
    }
}

