//
//  GameState.swift
//  GridNation
//
//  Observable game state that manages the simulation loop
//

import Foundation
import Combine
internal import CoreGraphics

/// The main game state observable by SwiftUI views
/// Uses @Observable macro for modern SwiftUI state management
@Observable
class GameState {
    var world: World
    var isPaused: Bool
    var speed: Double  // Multiplier: 0, 1, 2, 3
    var gridScene: CityGridScene?  // Reference to SpriteKit scene for updates
    
    // Tile selector menu state
    var showTileSelector: Bool = false
    var tileSelectorPosition: CGPoint = .zero
    var selectedTileCoordinates: (x: Int, y: Int)?
    
    private var lastTickTime: Date
    private var tickTimer: Timer?
    private var eventSpawnCounter: Double = 0
    
    init(seed: Int? = nil) {
        self.world = World(seed: seed)
        self.isPaused = false
        self.speed = 1.0
        self.lastTickTime = Date()
        
        startSimulation()
    }
    
    /// Start the simulation timer
    func startSimulation() {
        // Timer fires every 0.5 seconds (optimized for performance)
        // Less frequent updates = better performance
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    /// Stop the simulation timer
    func stopSimulation() {
        tickTimer?.invalidate()
        tickTimer = nil
    }
    
    /// Execute one simulation tick
    private func tick() {
        guard !isPaused, speed > 0 else { return }
        
        let now = Date()
        let deltaTime = now.timeIntervalSince(lastTickTime)
        lastTickTime = now
        
        // Apply speed multiplier
        let effectiveDelta = deltaTime * speed
        
        // Simulate world
        world.simulate(deltaTime: effectiveDelta)
        
        // Check for event spawning (roughly every 10-15 seconds of real time)
        eventSpawnCounter += deltaTime
        if eventSpawnCounter >= 10.0 {
            world.spawnEventIfNeeded()
            eventSpawnCounter = 0
        }
//        world.spawnEventIfNeeded()
    }
    
    /// Toggle between play speeds: 0x → 1x → 2x → 3x → 0x
    func cycleSpeed() {
        if isPaused {
            isPaused = false
            speed = 1.0
        } else {
            switch speed {
            case 1.0:
                speed = 2.0
            case 2.0:
                speed = 3.0
            case 3.0:
                isPaused = true
                speed = 1.0
            default:
                speed = 1.0
            }
        }
    }
    
    /// Toggle pause/unpause
    func togglePause() {
        isPaused.toggle()
    }
    
    /// Set a specific speed
    func setSpeed(_ newSpeed: Double) {
        speed = max(0, min(3, newSpeed))
        isPaused = speed == 0
    }
    
    /// Show tile selector menu at position
    func showTileSelectorMenu(at position: CGPoint, for x: Int, y: Int) {
        guard let tile = world.city.tile(at: x, y: y) else { return }
        
        // Don't allow changing terrain tiles
        guard !tile.type.isTerrain else { return }
        
        // Check if tile is within territory (allow building anywhere if no territory yet)
        if world.city.territoryBorder.count > 0 && !world.city.isWithinTerritory(x: x, y: y) {
            // Show a message that you can't build outside territory
            print("Cannot build outside territory!")
            // TODO: Show visual feedback to user
            return
        }
        
        tileSelectorPosition = position
        selectedTileCoordinates = (x, y)
        showTileSelector = true
        
        // Disable map interaction
        print("Setting isMenuActive = true")
        gridScene?.isMenuActive = true
    }
    
    /// Hide tile selector menu
    func hideTileSelector() {
        showTileSelector = false
        selectedTileCoordinates = nil
        
        // Re-enable map interaction
        print("Setting isMenuActive = false")
        gridScene?.isMenuActive = false
        
        // Remove highlight
        gridScene?.hideHighlight()
    }
    
    /// Place selected tile type at stored coordinates
    func placeTile(_ tileType: TileType) {
        guard let coords = selectedTileCoordinates else { return }
        
        world.city.setTile(at: coords.x, y: coords.y, type: tileType)
        
        // Expand territory when placing a building (not empty tiles)
        if tileType != .empty && !tileType.isTerrain {
            // Different building types expand territory by different amounts
            let expansionRadius: Int
            switch tileType {
            case .military:
                expansionRadius = 4  // Military expands border the most
            case .residential, .commercial, .industrial:
                expansionRadius = 3  // Economic buildings expand moderately
            case .park:
                expansionRadius = 2  // Parks expand least
            default:
                expansionRadius = 2
            }
            
            world.city.expandTerritory(from: coords.x, y: coords.y, radius: expansionRadius)
        }
        
        // Update SpriteKit scene immediately for responsive feedback
        gridScene?.updateTile(at: coords.x, y: coords.y, type: tileType)
        
        // Update city reference in scene (needed for border calculations)
        gridScene?.updateCity(world.city)
        
        // Update border visualization
        gridScene?.updateBorderVisualization()
        
        print("Tile placed, hiding selector...")
        hideTileSelector()
        
        // Extra safety: ensure state is clean after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            print("Safety check: isMenuActive = \(self?.gridScene?.isMenuActive ?? false)")
            if self?.gridScene?.isMenuActive == true {
                print("WARNING: Menu still active, forcing reset")
                self?.gridScene?.isMenuActive = false
            }
        }
    }
    
    /// Handle event choice selection
    func selectEventChoice(_ choice: EventChoice) {
        world.resolveEvent(with: choice)
        
        // Ensure map interaction is enabled after event
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.gridScene?.isMenuActive = false
        }
    }
}

