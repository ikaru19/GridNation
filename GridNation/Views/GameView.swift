//
//  GameView.swift
//  GridNation
//
//  Main game view that combines all UI components
//

import SwiftUI

struct GameView: View {
    @State var gameState: GameState
    let onExitToMenu: () -> Void
    
    var body: some View {
        ZStack {
            // Background - Fullscreen grid
            CityGridView(
                city: gameState.world.city,
                onTileTap: { x, y in
                    // No longer needed - long press shows menu
                },
                onTileLongPress: { position, x, y in
                    gameState.showTileSelectorMenu(at: position, for: x, y: y)
                },
                scene: $gameState.gridScene
            )
            .ignoresSafeArea()
            
            // UI Overlays
            VStack(spacing: 0) {
                // Top: Settings bar
                SettingsBar(
                    isPaused: gameState.isPaused,
                    speed: gameState.speed,
                    onTogglePause: {
                        gameState.togglePause()
                    },
                    onCycleSpeed: {
                        gameState.cycleSpeed()
                    },
                    onExitToMenu: onExitToMenu
                )
                
                Spacer()
            }
            
            // HUD overlay (top right)
            VStack {
                HStack {
                    Spacer()
                    HUDView(
                        city: gameState.world.city,
                        globalState: gameState.world.globalState
                    )
                    .padding(.top, 60) // Below settings bar
                    .padding(.trailing, 8)
                }
                Spacer()
            }
            
            // Legend overlay (bottom left)
            VStack {
                Spacer()
                HStack {
                    TileLegendView()
                        .padding(.leading, 8)
                        .padding(.bottom, 8)
                    Spacer()
                }
            }
            
            // Tile selector menu (appears on long press)
            if gameState.showTileSelector {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        gameState.hideTileSelector()
                    }
                
                TileSelectorMenu(
                    position: gameState.tileSelectorPosition,
                    buildableTiles: TileType.buildableTypes,
                    selectedType: .constant(nil),
                    onSelect: { tileType in
                        gameState.placeTile(tileType)
                    },
                    onCancel: {
                        gameState.hideTileSelector()
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Event modal (centered, appears when event exists and menu is not showing)
            if let event = gameState.world.currentEvent, !gameState.showTileSelector {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Prevent tap-through
                    }
                
                EventModalView(event: event) { choice in
                    gameState.selectEventChoice(choice)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
