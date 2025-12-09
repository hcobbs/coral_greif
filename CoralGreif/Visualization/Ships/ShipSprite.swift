//
//  ShipSprite.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import SpriteKit

/// A SpriteKit node representing a ship on the game board.
/// Renders WWII silhouettes using procedural CGPath drawing.
final class ShipSprite: SKNode {

    // MARK: - Properties

    /// The ship type this sprite represents.
    let shipType: ShipType

    /// The orientation of the ship.
    let orientation: Orientation

    /// The size of a single cell in points.
    let cellSize: CGFloat

    /// The shape node containing the ship silhouette.
    private let shapeNode: SKShapeNode

    /// The number of hits this ship has taken (for damage visualization).
    private(set) var hitCount: Int = 0

    /// Whether the ship is sunk.
    var isSunk: Bool {
        return hitCount >= shipType.size
    }

    // MARK: - Initialization

    /// Creates a new ship sprite.
    /// - Parameters:
    ///   - shipType: The type of ship to render
    ///   - orientation: Horizontal or vertical placement
    ///   - cellSize: The size of a single grid cell in points
    ///   - tint: The color tint for the ship (defaults to navy steel)
    init(
        shipType: ShipType,
        orientation: Orientation,
        cellSize: CGFloat,
        tint: UIColor = AppTheme.Colors.navySteel
    ) {
        self.shipType = shipType
        self.orientation = orientation
        self.cellSize = cellSize

        // Calculate ship dimensions
        let shipLength = CGFloat(shipType.size) * cellSize
        let shipBeam = cellSize * 0.85  // Ships are slightly narrower than cells

        // Get the scaled path
        let size: CGSize
        if orientation == .horizontal {
            size = CGSize(width: shipLength, height: shipBeam)
        } else {
            size = CGSize(width: shipBeam, height: shipLength)
        }

        // Create the shape node
        let path = ShipSprite.createOrientedPath(
            for: shipType,
            size: size,
            orientation: orientation
        )
        shapeNode = SKShapeNode(path: path)
        shapeNode.fillColor = tint
        shapeNode.strokeColor = tint.darker(by: 0.2)
        shapeNode.lineWidth = 1.5

        super.init()

        addChild(shapeNode)
        self.name = "ship_\(shipType.rawValue)"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Path Creation

    /// Creates an oriented path for the ship.
    private static func createOrientedPath(
        for type: ShipType,
        size: CGSize,
        orientation: Orientation
    ) -> CGPath {
        let basePath = ShipPaths.path(for: type)

        var transform: CGAffineTransform
        if orientation == .horizontal {
            // Scale to fit horizontally (ship runs left to right)
            transform = CGAffineTransform(scaleX: size.width, y: size.height)
        } else {
            // Rotate 90 degrees and scale (ship runs top to bottom)
            transform = CGAffineTransform(rotationAngle: .pi / 2)
                .scaledBy(x: size.height, y: size.width)
                .translatedBy(x: 0, y: -1)
        }

        if let transformed = basePath.copy(using: &transform) {
            return transformed
        }
        return basePath
    }

    // MARK: - Damage State

    /// Records a hit on the ship and updates visual state.
    /// - Parameter coordinate: The coordinate that was hit (relative to ship origin)
    func recordHit() {
        hitCount += 1
        updateDamageVisuals()
    }

    /// Updates the visual appearance based on damage state.
    private func updateDamageVisuals() {
        let damageRatio = CGFloat(hitCount) / CGFloat(shipType.size)

        if isSunk {
            // Sunk: dark gray, semi-transparent
            shapeNode.fillColor = AppTheme.Colors.sunkShip
            shapeNode.alpha = 0.7
        } else if damageRatio > 0.5 {
            // Heavy damage: reddish tint
            shapeNode.fillColor = AppTheme.Colors.navySteel.blend(
                with: AppTheme.Colors.hitRed,
                ratio: 0.4
            )
        } else if damageRatio > 0 {
            // Light damage: slight red tint
            shapeNode.fillColor = AppTheme.Colors.navySteel.blend(
                with: AppTheme.Colors.hitRed,
                ratio: 0.2
            )
        }
    }

    // MARK: - Animation

    /// Plays a hit animation at the specified local position.
    /// - Parameter position: The position within the ship to animate
    func playHitAnimation(at position: CGPoint) {
        let flash = SKShapeNode(circleOfRadius: cellSize * 0.3)
        flash.fillColor = .orange
        flash.strokeColor = .clear
        flash.position = position
        flash.alpha = 1.0
        flash.zPosition = 10
        addChild(flash)

        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scale = SKAction.scale(to: 1.5, duration: 0.3)
        let group = SKAction.group([fadeOut, scale])
        let remove = SKAction.removeFromParent()

        flash.run(SKAction.sequence([group, remove]))
    }

    /// Plays the sinking animation.
    /// - Parameter completion: Called when animation completes
    func playSinkAnimation(completion: @escaping () -> Void) {
        let fadeOut = SKAction.fadeOut(withDuration: 1.5)
        let sink = SKAction.moveBy(x: 0, y: -cellSize * 0.5, duration: 1.5)
        let group = SKAction.group([fadeOut, sink])
        let callback = SKAction.run(completion)

        run(SKAction.sequence([group, callback]))
    }
}

// MARK: - UIColor Extensions

private extension UIColor {

    /// Returns a darker version of the color.
    func darker(by percentage: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return UIColor(
                hue: h,
                saturation: s,
                brightness: max(b - percentage, 0),
                alpha: a
            )
        }
        return self
    }

    /// Blends this color with another color.
    func blend(with other: UIColor, ratio: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let clampedRatio = max(0, min(1, ratio))
        return UIColor(
            red: r1 + (r2 - r1) * clampedRatio,
            green: g1 + (g2 - g1) * clampedRatio,
            blue: b1 + (b2 - b1) * clampedRatio,
            alpha: a1 + (a2 - a1) * clampedRatio
        )
    }
}
