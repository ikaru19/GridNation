//
//  GameEvent.swift
//  GridNation
//
//  Represents random events that happen during gameplay
//

import Foundation

/// Category of event that determines UI styling
enum EventType: String, Codable {
    case good      // Positive opportunities (green)
    case political // Diplomatic/neighbor events (blue)
    case riot      // Crises, strikes, protests (red)
    case neutral   // General events (gray)
}

/// Event conditions for when it can appear
struct EventConditions: Codable {
    var minPopulation: Int?
    var maxPopulation: Int?
    var minStability: Int?
    var maxStability: Int?
    var minResidential: Int?
    var minCommercial: Int?
    var minIndustrial: Int?
    var maxParks: Int?
    var minUnemployment: Int?
    var populationNearCap: Bool?
    
    func isMet(city: City, globalState: GlobalState, unemployment: Int, populationCapacity: Int) -> Bool {
        if let min = minPopulation, city.population < min { return false }
        if let max = maxPopulation, city.population > max { return false }
        if let min = minStability, Int(city.stability) < min { return false }
        if let max = maxStability, Int(city.stability) > max { return false }
        
        let residential = city.countTiles(of: .residential)
        let commercial = city.countTiles(of: .commercial)
        let industrial = city.countTiles(of: .industrial)
        let parks = city.countTiles(of: .park)
        
        if let min = minResidential, residential < min { return false }
        if let min = minCommercial, commercial < min { return false }
        if let min = minIndustrial, industrial < min { return false }
        if let max = maxParks, parks > max { return false }
        if let min = minUnemployment, unemployment < min { return false }
        if let nearCap = populationNearCap, nearCap {
            let ratio = Double(city.population) / Double(max(1, populationCapacity))
            if ratio < 0.8 { return false }  // Only trigger if 80%+ capacity
        }
        
        return true
    }
}

/// A choice the player can make in response to an event
struct EventChoice: Identifiable, Codable {
    let id: String
    let text: String
    let moneyChange: Double?
    let stabilityChange: Double?
    let worldTensionChange: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, text, moneyChange, stabilityChange, worldTensionChange
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.text = try container.decode(String.self, forKey: .text)
        self.moneyChange = try container.decodeIfPresent(Double.self, forKey: .moneyChange)
        self.stabilityChange = try container.decodeIfPresent(Double.self, forKey: .stabilityChange)
        self.worldTensionChange = try container.decodeIfPresent(Double.self, forKey: .worldTensionChange)
    }
}

/// JSON structure for event data
struct EventData: Codable {
    let id: String
    let title: String
    let description: String
    let type: EventType
    let choices: [EventChoice]
    let minPopulation: Int?
    let maxPopulation: Int?
    let minStability: Int?
    let maxStability: Int?
    let minResidential: Int?
    let minCommercial: Int?
    let minIndustrial: Int?
    let maxParks: Int?
    let minUnemployment: Int?
    let populationNearCap: Bool?
}

/// A random event that requires player decision
struct GameEvent: Identifiable {
    let id: String
    let title: String
    let description: String
    let choices: [EventChoice]
    let eventType: EventType
    let conditions: EventConditions
    
    /// Load events from JSON file
    static func loadEvents() -> [EventData] {
        guard let url = Bundle.main.url(forResource: "events", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONDecoder().decode([String: [EventData]].self, from: data) else {
            print("Failed to load events.json")
            return []
        }
        return json["events"] ?? []
    }
    
    /// Get a random event that meets current game conditions
    static func randomEvent(city: City, globalState: GlobalState) -> GameEvent? {
        let allEvents = loadEvents()
        
        // Calculate unemployment
        let availableJobs = (city.countTiles(of: .commercial) + city.countTiles(of: .industrial)) * 20
        let unemployment = max(0, city.population - availableJobs)
        let populationCapacity = city.countTiles(of: .residential) * 30
        
        // Filter events that meet conditions
        let validEvents = allEvents.filter { eventData in
            let conditions = EventConditions(
                minPopulation: eventData.minPopulation,
                maxPopulation: eventData.maxPopulation,
                minStability: eventData.minStability,
                maxStability: eventData.maxStability,
                minResidential: eventData.minResidential,
                minCommercial: eventData.minCommercial,
                minIndustrial: eventData.minIndustrial,
                maxParks: eventData.maxParks,
                minUnemployment: eventData.minUnemployment,
                populationNearCap: eventData.populationNearCap
            )
            return conditions.isMet(city: city, globalState: globalState, unemployment: unemployment, populationCapacity: populationCapacity)
        }
        
        guard let eventData = validEvents.randomElement() else { return nil }
        
        return GameEvent(
            id: eventData.id,
            title: eventData.title,
            description: eventData.description,
            choices: eventData.choices,
            eventType: eventData.type,
            conditions: EventConditions(
                minPopulation: eventData.minPopulation,
                maxPopulation: eventData.maxPopulation,
                minStability: eventData.minStability,
                maxStability: eventData.maxStability,
                minResidential: eventData.minResidential,
                minCommercial: eventData.minCommercial,
                minIndustrial: eventData.minIndustrial,
                maxParks: eventData.maxParks,
                minUnemployment: eventData.minUnemployment,
                populationNearCap: eventData.populationNearCap
            )
        )
    }
}

