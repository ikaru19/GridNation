# GridNation

A real-time grid-based building simulation game built with Swift and SwiftUI, inspired by Tropico-style gameplay.

## 🎮 Game Overview

GridNation is a simple real-time city builder with:
- **80×80 scrollable grid map** with colored tiles representing different zones
- **Procedural terrain generation** with water and mountains (seed-based)
- **Real-time simulation** that continuously updates your city
- **Political layer** with neighboring countries and world tension
- **Random events** that require strategic decisions
- **Resource management** (money, population, stability)

## 🏗️ Architecture

### GameCore (Pure Swift Models)
Located in `GridNation/Models/`:

- **TileType.swift** - Enum defining tile types (empty, residential, commercial, industrial, park, military)
- **Tile.swift** - Individual tile in the grid
- **City.swift** - Player's city with grid and resources
- **Country.swift** - Neighboring countries with relationships
- **GlobalState.swift** - World politics and tension
- **GameEvent.swift** - Random events with choices
- **World.swift** - Complete world state and simulation logic

### Game Logic
- **GameState.swift** - Observable game state with timer-based simulation loop

### SwiftUI Views
Located in `GridNation/Views/`:

- **GameView.swift** - Main game screen
- **CityGridView.swift** - Renders the tile grid
- **HUDView.swift** - Displays stats (money, population, stability, tension)
- **EventModalView.swift** - Shows events and choices
- **SettingsBar.swift** - Pause/play and speed controls
- **TileLegendView.swift** - Tile type reference

## 🎯 How to Play

1. **Explore the Map**
   - **Swipe/scroll** to pan around the 80×80 grid
   - Find buildable areas between water (🌊 cyan) and mountains (⛰️ brown)
   - Terrain is randomly generated each game using a unique **seed**

2. **Build Your City**
   - Tap any empty tile to cycle through tile types
   - **Terrain tiles cannot be built on** - work around them!
   - Each tile type has different effects:
     - 🟢 **Residential**: Houses population (max 30 per tile)
     - 🔵 **Commercial**: Generates money + provides 20 jobs per tile
     - 🟠 **Industrial**: Generates more money + 20 jobs but causes pollution
     - 🩵 **Park**: Improves stability
     - 🔴 **Military**: Reduces world tension
     - ⚪ **Empty**: Unused land

3. **Map Seeds**
   - Each game has a unique 6-digit **seed** shown in the HUD
   - Share seeds with friends to play the same map!
   - Same seed = same terrain layout (reproducible)

4. **Manage Resources & Jobs**
   - Watch your money, population (current/max), jobs, and stability
   - **Population cap**: Each residential tile holds max 30 people
   - **Jobs system**: Commercial/industrial tiles provide 20 jobs each
   - **Growth mechanics**:
     - High stability (>70%) = 1.5× faster growth
     - Normal stability (40-70%) = normal growth
     - Low stability (<40%) = 0.5× slower growth
     - Not enough jobs = very slow or no growth
   - Build commercial/industrial BEFORE residential for best results
   - Balance housing, jobs, and citizen happiness
   - Monitor world tension to avoid conflicts

5. **Handle Events**
   - Random events appear periodically
   - Choose wisely - each choice has consequences
   - Effects include money, stability, and international relations

6. **Control Time**
   - Pause/Play button to stop/start simulation
   - Speed button cycles through: 1x → 2x → 3x → Pause
   - Watch your city evolve in real-time!

## 🛠️ Technical Details

### Simulation Loop
- Runs on a `Timer` with 0.25s intervals
- Speed multiplier (1x, 2x, 3x) affects simulation rate
- Continuously updates:
  - **Population growth** (complex system):
    - Capped at 30 per residential tile
    - Affected by stability (0.5× to 1.5× multiplier)
    - Requires jobs: unemployment slows growth dramatically
    - Base rate: 2 population per residential tile per second
  - Money generation (from commercial/industrial zones)
  - Stability changes (parks increase, industrial decreases)
  - World tension dynamics

### Terrain Generation
- **Seeded random generation** for reproducible maps
- Each map has a unique 6-digit seed (0-999999)
- Uses Linear Congruential Generator (LCG) for deterministic randomness
- 8-15 water bodies, 10-18 mountain ranges
- Terrain tiles are locked and cannot be built on

### State Management
- Uses Swift's `@Observable` macro for reactive state
- SwiftUI views automatically update when state changes
- Pure Swift models keep game logic separate from UI

### Scaling
- Currently 80×80 grid (6,400 tiles)
- Fullscreen scrollable view with pan/swipe controls
- Fixed 20px tile size for consistent appearance
- Lightweight rendering using SwiftUI Rectangles

## 🚀 Future Enhancements

Potential features to add:
- Save/load game state (already `Codable` ready!)
- More tile types (hospital, school, police, etc.)
- Building costs (pay to place tiles)
- Neighbor interactions (trade, sabotage, annexation)
- Tech tree or upgrades
- Disasters and special events
- SpriteKit integration for better performance at larger scales
- Sound effects and background music

## 📝 Code Highlights

### Clean Separation
```swift
// Pure Swift model - no UI dependencies
struct World {
    var city: City
    var globalState: GlobalState
    
    mutating func simulate(deltaTime: Double) {
        // Game logic here
    }
}

// SwiftUI view - only displays state
struct GameView: View {
    @State private var gameState = GameState()
    // UI code here
}
```

### Observable Pattern
```swift
@Observable
class GameState {
    var world: World
    var isPaused: Bool
    var speed: Double
    // SwiftUI automatically updates when these change
}
```

### Composable Views
Each UI component is self-contained and reusable, making the code maintainable and testable.

## 🎓 Learning Resources

This project demonstrates:
- **Swift basics**: `struct`, `class`, `enum`, `protocol`, `Codable`
- **SwiftUI**: `View`, `@State`, `@Observable`, view composition
- **Architecture**: Separation of concerns, MVVM patterns
- **Game dev**: Real-time simulation, event systems, state management

Perfect for learning Swift/SwiftUI while building something fun!

---

Built with ❤️ using Swift and SwiftUI

