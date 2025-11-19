//
//  MainMenuView.swift
//  GridNation
//
//  Main menu for the game
//

import SwiftUI

struct MainMenuView: View {
    @Binding var showGame: Bool
    @Binding var gameState: GameState?
    
    @State private var showNewGameOptions = false
    @State private var customSeed: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Animated grid background
                GridBackgroundView()
                    .opacity(0.3)
                
                HStack(spacing: 0) {
                    // Left side: Title and info
                    VStack(alignment: .leading, spacing: 20) {
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("GridNation")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Build Your City-State")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("🏝️ Island Management Simulator")
                                .font(.subheadline)
                                .foregroundColor(.cyan.opacity(0.8))
                                .padding(.top, 5)
                        }
                        
                        Spacer()
                        
                        // Version
                        Text("v1.0.0")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(width: geometry.size.width * 0.4)
                    .padding(.leading, 40)
                    .padding(.vertical, 40)
                    
                    // Right side: Menu buttons
                    VStack(spacing: 16) {
                        // Continue (if game exists)
                        if gameState != nil {
                            MenuButton(
                                title: "Continue",
                                icon: "play.fill",
                                color: .green
                            ) {
                                showGame = true
                            }
                        }
                        
                        // New Game
                        MenuButton(
                            title: "New Game",
                            icon: "plus.circle.fill",
                            color: .blue
                        ) {
                            showNewGameOptions = true
                        }
                        
                        // Settings (placeholder)
                        MenuButton(
                            title: "Settings",
                            icon: "gearshape.fill",
                            color: .gray
                        ) {
                            // TODO: Settings
                        }
                        
                        // About
                        MenuButton(
                            title: "About",
                            icon: "info.circle.fill",
                            color: .purple
                        ) {
                            // TODO: About
                        }
                    }
                    .frame(width: geometry.size.width * 0.5)
                    .padding(.trailing, 40)
                }
            }
            .sheet(isPresented: $showNewGameOptions) {
                NewGameSheet(
                    customSeed: $customSeed,
                    onStart: { seed in
                        startNewGame(seed: seed)
                    }
                )
            }
        }
    }
    
    private func startNewGame(seed: Int?) {
        gameState = GameState(seed: seed)
        showGame = true
        showNewGameOptions = false
    }
}

/// Menu button component
struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
    }
}

/// New game options sheet
struct NewGameSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var customSeed: String
    let onStart: (Int?) -> Void
    
    @State private var useCustomSeed = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Icon
                Image(systemName: "map.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                // Description
                Text("Start a new city on a randomly generated island")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Seed options
                VStack(spacing: 15) {
                    Toggle("Use Custom Seed", isOn: $useCustomSeed)
                        .padding(.horizontal)
                    
                    if useCustomSeed {
                        TextField("Enter seed (number)", text: $customSeed)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Start button
                Button {
                    let seed: Int?
                    if useCustomSeed, let seedValue = Int(customSeed) {
                        seed = seedValue
                    } else {
                        seed = nil
                    }
                    onStart(seed)
                } label: {
                    Text("Start Game")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Animated grid background
struct GridBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            let gridSize: CGFloat = 40
            let columns = Int(geometry.size.width / gridSize) + 1
            let rows = Int(geometry.size.height / gridSize) + 1
            
            Canvas { context, size in
                for row in 0..<rows {
                    for col in 0..<columns {
                        let x = CGFloat(col) * gridSize
                        let y = CGFloat(row) * gridSize
                        let rect = CGRect(x: x, y: y, width: gridSize - 2, height: gridSize - 2)
                        
                        let opacity = animate ? 0.1 : 0.05
                        context.fill(
                            Path(rect),
                            with: .color(.white.opacity(opacity))
                        )
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

#Preview {
    @Previewable @State var showGame = false
    @Previewable @State var gameState: GameState? = nil
    return MainMenuView(showGame: $showGame, gameState: $gameState)
}

