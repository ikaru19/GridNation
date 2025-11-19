//
//  ContentView.swift
//  GridNation
//
//  Created by Muhammad Syafrizal on 19/11/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showGame = false
    @State private var gameState: GameState?
    
    var body: some View {
        if showGame, let gameState = gameState {
            GameView(gameState: gameState, onExitToMenu: {
                showGame = false
            })
        } else {
            MainMenuView(showGame: $showGame, gameState: $gameState)
        }
    }
}

#Preview {
    ContentView()
}
