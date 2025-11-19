//
//  GlobalState.swift
//  GridNation
//
//  Represents the global political situation
//

import Foundation

/// Tracks global politics and neighboring countries
struct GlobalState: Codable {
    var worldTension: Double  // 0-100, higher means more conflict
    var neighbors: [Country]
    
    init() {
        self.worldTension = 30.0
        self.neighbors = [
            Country(name: "Northland", relationship: 20, militaryStrength: 60),
            Country(name: "Southaria", relationship: -10, militaryStrength: 40),
            Country(name: "East Republic", relationship: 50, militaryStrength: 70),
            Country(name: "Westonia", relationship: 0, militaryStrength: 50)
        ]
    }
    
    /// Average relationship with all neighbors
    var averageRelationship: Double {
        guard !neighbors.isEmpty else { return 0 }
        return neighbors.map { $0.relationship }.reduce(0, +) / Double(neighbors.count)
    }
}

