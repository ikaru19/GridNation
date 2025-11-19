//
//  SettingsBar.swift
//  GridNation
//
//  Controls for pause/play and game speed
//

import SwiftUI

struct SettingsBar: View {
    let isPaused: Bool
    let speed: Double
    let onTogglePause: () -> Void
    let onCycleSpeed: () -> Void
    let onExitToMenu: (() -> Void)?
    
    @State private var showExitConfirmation = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Pause/Play button
            Button {
                onTogglePause()
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(isPaused ? Color.green : Color.orange)
                    .cornerRadius(8)
            }
            
            // Speed indicator and control
            Button {
                onCycleSpeed()
            } label: {
                HStack {
                    Image(systemName: "gauge.high")
                        .foregroundColor(.white)
                    Text(speedLabel)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Exit to menu button (only if handler provided)
            if let onExitToMenu = onExitToMenu {
                Button {
                    showExitConfirmation = true
                } label: {
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .confirmationDialog("Exit to Main Menu?", isPresented: $showExitConfirmation) {
                    Button("Exit", role: .destructive) {
                        onExitToMenu()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Your progress will be saved.")
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private var speedLabel: String {
        if isPaused {
            return "Paused"
        }
        return String(format: "%.0fx", speed)
    }
}

#Preview {
    VStack {
        SettingsBar(isPaused: false, speed: 1.0, onTogglePause: {}, onCycleSpeed: {}, onExitToMenu: nil)
        SettingsBar(isPaused: true, speed: 1.0, onTogglePause: {}, onCycleSpeed: {}, onExitToMenu: {})
        SettingsBar(isPaused: false, speed: 2.0, onTogglePause: {}, onCycleSpeed: {}, onExitToMenu: {})
    }
}

