//
//  CityGridView.swift
//  GridNation
//
//  High-performance SpriteKit-based grid rendering for large maps
//

import SwiftUI
import SpriteKit

struct CityGridView: View {
    let city: City
    let onTileTap: (Int, Int) -> Void
    let onTileLongPress: (CGPoint, Int, Int) -> Void
    @Binding var scene: CityGridScene?
    
    var body: some View {
        GeometryReader { geometry in
            SpriteKitContainer(
                city: city,
                onTileTap: onTileTap,
                onTileLongPress: onTileLongPress,
                scene: $scene
            )
            .ignoresSafeArea()
        }
    }
}

/// SwiftUI wrapper for SpriteKit scene
struct SpriteKitContainer: UIViewRepresentable {
    let city: City
    let onTileTap: (Int, Int) -> Void
    let onTileLongPress: (CGPoint, Int, Int) -> Void
    @Binding var scene: CityGridScene?
    
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        skView.backgroundColor = .black
        
        // Performance settings
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        
        // Create scene with proper size
        let sceneSize = CGSize(
            width: CGFloat(city.gridWidth) * 32,
            height: CGFloat(city.gridHeight) * 32
        )
        let gridScene = CityGridScene(city: city, size: sceneSize)
        gridScene.onTileTap = onTileTap
        gridScene.onTileLongPress = onTileLongPress
        gridScene.skView = skView  // Store reference to SKView
        
        // Store scene reference
        DispatchQueue.main.async {
            self.scene = gridScene
        }
        
        skView.presentScene(gridScene)
        return skView
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        // Scene updates happen through GameState
    }
}

#Preview {
    @Previewable @State var scene: CityGridScene? = nil
    return CityGridView(
        city: City(width: 10, height: 10),
        onTileTap: { x, y in
            print("Tapped \(x), \(y)")
        },
        onTileLongPress: { pos, x, y in
            print("Long pressed \(x), \(y) at \(pos)")
        },
        scene: $scene
    )
}

