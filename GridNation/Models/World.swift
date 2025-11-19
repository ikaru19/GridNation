//
//  World.swift
//  GridNation
//
//  The complete world state including city and global politics
//

import Foundation

/// Complete game world state
struct World: Codable {
    var city: City
    var globalState: GlobalState
    var currentEvent: GameEvent?
    
    // Custom coding keys to skip currentEvent
    enum CodingKeys: String, CodingKey {
        case city
        case globalState
    }
    
    init(seed: Int? = nil) {
        // Increase to 200×200 for really big maps!
        // SpriteKit can handle this easily
        self.city = City(width: 200, height: 200, seed: seed)
        self.globalState = GlobalState()
        self.currentEvent = nil
    }
    
    // Custom decoder - currentEvent is not saved
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        city = try container.decode(City.self, forKey: .city)
        globalState = try container.decode(GlobalState.self, forKey: .globalState)
        currentEvent = nil  // Events are transient, not saved
    }
    
    // Custom encoder - currentEvent is not saved
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(city, forKey: .city)
        try container.encode(globalState, forKey: .globalState)
        // currentEvent is intentionally not encoded (transient state)
    }
    
    /// Simulate one tick of the game
    mutating func simulate(deltaTime: Double) {
        // Calculate tile counts once per tick (cached for performance)
        let residential = city.countTiles(of: .residential)
        guard residential > 0 || city.population > 0 else {
            // Skip simulation if no city built yet (performance optimization)
            return
        }
        
        let commercial = city.countTiles(of: .commercial)
        let industrial = city.countTiles(of: .industrial)
        let parks = city.countTiles(of: .park)
        let military = city.countTiles(of: .military)
        
        // Population grows with residential zones (capped at 30 per tile)
        let maxPopulation = residential * 30
        if city.population < maxPopulation && residential > 0 {
            // Calculate available jobs (each commercial/industrial tile provides 20 jobs)
            let availableJobs = (commercial + industrial) * 20
            let unemployment = max(0, city.population - availableJobs)
            
            // Growth rate depends on stability and job availability
            var growthMultiplier = 1.0
            
            // Stability factor (0.5x to 1.5x based on stability)
            if city.stability > 70 {
                growthMultiplier = 1.5  // High stability = faster growth
            } else if city.stability > 40 {
                growthMultiplier = 1.0  // Normal stability = normal growth
            } else {
                growthMultiplier = 0.5  // Low stability = slower growth
            }
            
            // Job availability factor
            if unemployment > 0 {
                // Too many unemployed people, slow down growth significantly
                let unemploymentRate = Double(unemployment) / Double(max(1, city.population))
                if unemploymentRate > 0.5 {
                    growthMultiplier *= 0.1  // Very high unemployment = almost no growth
                } else if unemploymentRate > 0.2 {
                    growthMultiplier *= 0.3  // High unemployment = very slow growth
                } else {
                    growthMultiplier *= 0.6  // Some unemployment = slower growth
                }
            }
            
            // Base growth: 2 population per residential tile per second
            let baseGrowth = Double(residential) * 2.0 * deltaTime
            let populationGrowth = max(1, Int(baseGrowth * growthMultiplier))
            city.population = min(city.population + populationGrowth, maxPopulation)
        }
        
        // Money from commercial and industrial
        let moneyGain = Double(commercial * 5 + industrial * 8)
        city.money += moneyGain * deltaTime
        
        // Stability calculations
        var stabilityChange = 0.0
        
        // Parks increase stability
        stabilityChange += Double(parks) * 0.5 * deltaTime
        
        // Industrial zones decrease stability (pollution)
        stabilityChange -= Double(industrial) * 0.3 * deltaTime
        
        // Low money hurts stability
        if city.money < 100 {
            stabilityChange -= 2.0 * deltaTime
        }
        
        // Apply stability changes (clamped to 0-100)
        city.stability = max(0, min(100, city.stability + stabilityChange))
        
        // World tension system - based on border security and diplomatic relations
        var tensionChange = 0.0
        
        // Calculate actual border perimeter that needs defending
        let borderPerimeter = city.calculateBorderPerimeter()
        
        // Each military building can secure 10 tiles of border
        let securedBorderTiles = military * 10
        
        // Calculate border security percentage
        let borderSecurity = borderPerimeter > 0 ? 
            (Double(securedBorderTiles) / Double(borderPerimeter)) * 100.0 : 100.0
        
        // Unsecured borders create tension (neighbor countries may be hostile)
        if borderSecurity < 100 {
            let unsecuredPercent = (100.0 - borderSecurity) / 100.0
            tensionChange += unsecuredPercent * 0.4 * deltaTime
        }
        
        // Over-secured borders reduce tension (deterrent effect)
        if borderSecurity > 100 {
            let excessSecurity = borderSecurity - 100.0
            tensionChange -= (excessSecurity / 100.0) * 0.3 * deltaTime
        }
        
        // High city stability improves diplomatic relations (peaceful reputation)
        if city.stability > 70 {
            tensionChange -= 0.2 * deltaTime
        } else if city.stability < 30 {
            // Low stability makes neighbors nervous (unstable neighbor = threat)
            tensionChange += 0.15 * deltaTime
        }
        
        // TODO: Future implementation - Sabotage events
        // - Random sabotage attempts from hostile neighbors when tension > 70
        // - Counter-intelligence buildings to prevent sabotage
        // - Diplomatic missions to reduce tension
        
        // Apply tension changes (clamped to 0-100)
        globalState.worldTension += tensionChange
        globalState.worldTension = max(0, min(100, globalState.worldTension))
    }
    
    /// Spawn a random event (call this periodically)
    mutating func spawnEventIfNeeded() {
        // Only spawn if no current event
        guard currentEvent == nil else { return }
        
        // Random chance to spawn event
        if Double.random(in: 0...1) < 0.3 {
            currentEvent = GameEvent.randomEvent(city: city, globalState: globalState)
        }
    }
    
    /// Apply the effects of a chosen event option
    mutating func resolveEvent(with choice: EventChoice) {
        if let money = choice.moneyChange {
            city.money += money
        }
        if let stability = choice.stabilityChange {
            city.stability += stability
            city.stability = max(0, min(100, city.stability))
        }
        if let tension = choice.worldTensionChange {
            globalState.worldTension += tension
            globalState.worldTension = max(0, min(100, globalState.worldTension))
        }
        
        // Clear the event
        currentEvent = nil
    }
}

