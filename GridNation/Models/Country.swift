//
//  Country.swift
//  GridNation
//
//  Represents neighboring countries in the political layer
//

import Foundation

/// A neighboring country that can interact with the player
struct Country: Codable, Identifiable {
    let id: UUID
    var name: String
    var relationship: Double  // -100 to 100, negative is hostile
    var militaryStrength: Int
    var isHostile: Bool {
        relationship < -20
    }
    
    init(name: String, relationship: Double = 0, militaryStrength: Int = 50) {
        self.id = UUID()
        self.name = name
        self.relationship = relationship
        self.militaryStrength = militaryStrength
    }
}

