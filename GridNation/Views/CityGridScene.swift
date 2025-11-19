//
//  CityGridScene.swift
//  GridNation
//
//  SpriteKit scene for high-performance grid rendering
//

import SpriteKit
import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class CityGridScene: SKScene {
    var city: City
    var onTileTap: ((Int, Int) -> Void)?
    var onTileLongPress: ((CGPoint, Int, Int) -> Void)?
    var isMenuActive: Bool = false {
        didSet {
            // Disable/enable user interaction on the SKView when menu state changes
            skView?.isUserInteractionEnabled = !isMenuActive
            print("SKView interaction enabled: \(!isMenuActive)")
        }
    }
    weak var skView: SKView?  // Disable touch when menu is showing
    
    private let tileSize: CGFloat = 32
    private var tileNodes: [[SKSpriteNode]] = []
    
    // Camera for zoom and pan
    private var cameraNode: SKCameraNode!
    
    // Zoom limits
    private let minZoom: CGFloat = 0.1  // Can zoom in very close
    private let maxZoom: CGFloat = 5.0  // Can zoom out very far
    
    // Highlight for selected tile
    private var highlightNode: SKShapeNode?
    
    init(city: City, size: CGSize) {
        self.city = city
        super.init(size: size)
        
        // Scene setup for performance
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.backgroundColor = .black
        self.scaleMode = .aspectFill
        
        // Setup camera for zoom/pan
        setupCamera()
        
        setupGrid()
    }
    
    /// Setup camera for zoom and pan
    private func setupCamera() {
        cameraNode = SKCameraNode()
        addChild(cameraNode)
        camera = cameraNode
        
        // Position camera at a random buildable location on the island
        // Avoid the water borders (first/last 10 tiles)
        let margin: CGFloat = 10
        let maxX = CGFloat(city.gridWidth) - margin
        let maxY = CGFloat(city.gridHeight) - margin
        let randomX = CGFloat.random(in: margin...maxX) * tileSize
        let randomY = CGFloat.random(in: margin...maxY) * tileSize
        cameraNode.position = CGPoint(x: randomX, y: randomY)
        
        // Start zoomed in with very big tiles (~6-8 tiles on screen)
        cameraNode.setScale(0.4)
    }
    
    /// Recenter camera to map center
    private func recenterCamera() {
        let centerX = CGFloat(city.gridWidth) * tileSize / 2
        let centerY = CGFloat(city.gridHeight) * tileSize / 2
        
        let recenter = SKAction.move(to: CGPoint(x: centerX, y: centerY), duration: 0.3)
        let rescale = SKAction.scale(to: 0.4, duration: 0.3)
        recenter.timingMode = .easeInEaseOut
        rescale.timingMode = .easeInEaseOut
        
        cameraNode.run(SKAction.group([recenter, rescale]))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Setup the grid with SpriteKit nodes
    private func setupGrid() {
        // Create tile nodes grid
        for y in 0..<city.gridHeight {
            var row: [SKSpriteNode] = []
            for x in 0..<city.gridWidth {
                let tile = city.tiles[y][x]
                // Add 2px gap for grid lines
                let nodeSize = tileSize - 2
                let node = SKSpriteNode(color: uiColor(for: tile.type), size: CGSize(width: nodeSize, height: nodeSize))
                
                // Position tile (SpriteKit coordinates: bottom-left origin)
                node.position = CGPoint(
                    x: CGFloat(x) * tileSize + tileSize / 2,
                    y: CGFloat(city.gridHeight - y - 1) * tileSize + tileSize / 2
                )
                node.name = "\(x),\(y)"
                
                // Add slight darkening to terrain
                if tile.type.isTerrain {
                    let overlay = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.15), size: node.size)
                    overlay.position = CGPoint.zero
                    overlay.zPosition = 1
                    node.addChild(overlay)
                }
                
                addChild(node)
                row.append(node)
            }
            tileNodes.append(row)
        }
    }
    
    /// Update a specific tile's appearance
    func updateTile(at x: Int, y: Int, type: TileType) {
        guard y < tileNodes.count, x < tileNodes[y].count else { return }
        let node = tileNodes[y][x]
        
        // Update color
        node.color = uiColor(for: type)
        
        // Update terrain overlay
        node.removeAllChildren()
        if type.isTerrain {
            let overlay = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.15), size: node.size)
            overlay.position = CGPoint.zero
            overlay.zPosition = 1
            node.addChild(overlay)
        }
    }
    
    /// Handle touch/tap on tiles  
    #if os(iOS)
    private var lastTouchLocations: [UITouch: CGPoint] = [:]
    private var initialPinchDistance: CGFloat?
    private var initialCameraScale: CGFloat?
    private var lastTapTime: TimeInterval = 0
    private var touchStartTime: TimeInterval = 0
    private var touchStartLocation: CGPoint?
    private var longPressTriggered: Bool = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Ignore all touches if menu is active
        if isMenuActive {
            print("Touch blocked: menu is active")
            return
        }
        
        for touch in touches {
            lastTouchLocations[touch] = touch.location(in: self)
        }
        
        // Track for long press
        if let touch = touches.first, touches.count == 1 {
            touchStartTime = Date().timeIntervalSince1970
            touchStartLocation = touch.location(in: self)
            longPressTriggered = false
            
            // Schedule long press check
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.checkLongPress()
            }
        }
    }
    
    private func checkLongPress() {
        guard !longPressTriggered,
              let startLocation = touchStartLocation,
              let currentTouch = lastTouchLocations.values.first else { return }
        
        // Check if touch is still held and hasn't moved much
        let distance = hypot(currentTouch.x - startLocation.x, currentTouch.y - startLocation.y)
        let elapsed = Date().timeIntervalSince1970 - touchStartTime
        
        if elapsed >= 0.5 && distance < 20 {
            longPressTriggered = true
            handleLongPress(at: startLocation)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Ignore all touches if menu is active
        guard !isMenuActive else { return }
        
        guard let allTouches = event?.allTouches else { return }
        
        if allTouches.count == 2 {
            // Pinch to zoom
            let touchArray = Array(allTouches)
            let touch1 = touchArray[0]
            let touch2 = touchArray[1]
            
            let location1 = touch1.location(in: self)
            let location2 = touch2.location(in: self)
            let distance = hypot(location1.x - location2.x, location1.y - location2.y)
            
            if let initialDistance = initialPinchDistance,
               let initialScale = initialCameraScale {
                let scale = initialScale * (initialDistance / distance)
                let clampedScale = max(minZoom, min(maxZoom, scale))
                cameraNode.setScale(clampedScale)
            } else {
                initialPinchDistance = distance
                initialCameraScale = cameraNode.xScale
            }
        } else if allTouches.count == 1 {
            // Pan
            let touch = allTouches.first!
            let currentLocation = touch.location(in: self)
            if let lastLocation = lastTouchLocations[touch] {
                let delta = CGPoint(
                    x: (lastLocation.x - currentLocation.x) * cameraNode.xScale,
                    y: (lastLocation.y - currentLocation.y) * cameraNode.yScale
                )
                cameraNode.position = CGPoint(
                    x: cameraNode.position.x + delta.x,
                    y: cameraNode.position.y + delta.y
                )
            }
            lastTouchLocations[touch] = currentLocation
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Ignore all touches if menu is active
        if isMenuActive {
            print("Touch ended but menu is active - allowing cleanup")
        }
        
        guard let allTouches = event?.allTouches else { return }
        
        // Only handle tap if long press wasn't triggered
        if allTouches.count == 1, 
           let touch = touches.first,
           let startLocation = lastTouchLocations[touch],
           !longPressTriggered,
           !isMenuActive {
            let endLocation = touch.location(in: self)
            let distance = hypot(endLocation.x - startLocation.x, endLocation.y - startLocation.y)
            let elapsed = Date().timeIntervalSince1970 - touchStartTime
            
            // Quick tap for double-tap recenter
            if distance < 10 && elapsed < 0.3 {
                let now = Date().timeIntervalSince1970
                if now - lastTapTime < 0.3 {
                    recenterCamera()
                }
                lastTapTime = now
            }
        }
        
        // Clean up
        for touch in touches {
            lastTouchLocations.removeValue(forKey: touch)
        }
        
        if allTouches.count < 2 {
            initialPinchDistance = nil
            initialCameraScale = nil
        }
        
        touchStartLocation = nil
        longPressTriggered = false
        
        print("Touch ended, isMenuActive = \(isMenuActive)")
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            lastTouchLocations.removeValue(forKey: touch)
        }
        initialPinchDistance = nil
        initialCameraScale = nil
        touchStartLocation = nil
        longPressTriggered = false
        
        // Safety: ensure menu isn't stuck
        print("Touches cancelled, resetting state")
    }
    
    #elseif os(macOS)
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        handleTapAt(location)
    }
    
    override func scrollWheel(with event: NSEvent) {
        // Zoom with scroll wheel on macOS
        let zoomDelta = event.scrollingDeltaY * 0.01
        let newScale = cameraNode.xScale * (1 - zoomDelta)
        let clampedScale = max(minZoom, min(maxZoom, newScale))
        cameraNode.setScale(clampedScale)
    }
    #endif
    
    /// Handle long press at a specific location
    private func handleLongPress(at location: CGPoint) {
        // Calculate tile coordinates
        let x = Int(location.x / tileSize)
        let y = city.gridHeight - 1 - Int(location.y / tileSize)
        
        // Validate bounds
        guard x >= 0, x < city.gridWidth, y >= 0, y < city.gridHeight else { return }
        
        // Highlight the selected tile
        showHighlight(at: x, y: y)
        
        // Move camera to center on this tile
        focusCamera(on: x, y: y)
        
        // Haptic feedback
        #if os(iOS)
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        #endif
        
        // Convert to screen coordinates for menu display
        let screenLocation = convertPoint(toView: location)
        onTileLongPress?(screenLocation, x, y)
    }
    
    /// Show highlight on a specific tile
    func showHighlight(at x: Int, y: Int) {
        // Remove old highlight if exists
        highlightNode?.removeFromParent()
        
        // Create new highlight
        let rect = CGRect(x: -tileSize / 2, y: -tileSize / 2, width: tileSize, height: tileSize)
        let highlight = SKShapeNode(rect: rect, cornerRadius: 2)
        highlight.fillColor = SKColor.white.withAlphaComponent(0.4)
        highlight.strokeColor = SKColor.white
        highlight.lineWidth = 3
        highlight.zPosition = 10  // On top of everything
        
        // Position at the tile
        highlight.position = CGPoint(
            x: CGFloat(x) * tileSize + tileSize / 2,
            y: CGFloat(city.gridHeight - y - 1) * tileSize + tileSize / 2
        )
        
        // Pulsing animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        highlight.run(SKAction.repeatForever(pulse))
        
        addChild(highlight)
        highlightNode = highlight
    }
    
    /// Remove the highlight
    func hideHighlight() {
        highlightNode?.removeFromParent()
        highlightNode = nil
    }
    
    /// Focus camera on a specific tile
    private func focusCamera(on x: Int, y: Int) {
        let targetX = CGFloat(x) * tileSize + tileSize / 2
        let targetY = CGFloat(city.gridHeight - y - 1) * tileSize + tileSize / 2
        
        let move = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.3)
        move.timingMode = .easeInEaseOut
        cameraNode.run(move)
    }
    
    /// Convert TileType to SKColor
    private func uiColor(for tileType: TileType) -> SKColor {
        return tileType.skColor
    }
}

