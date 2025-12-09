//
//  GameAnimations.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import SpriteKit

/// Provides standardized game animations for state transitions.
enum GameAnimations {

    // MARK: - Attack Sequence

    /// Animates an attack sequence including targeting, impact, and result.
    /// - Parameters:
    ///   - targetNode: The node being targeted (e.g., cell or ship)
    ///   - result: The attack result (hit, miss, or sunk)
    ///   - gridScene: The grid scene to play effects in
    ///   - coordinate: The attack coordinate
    ///   - completion: Called when the animation completes
    static func playAttackSequence(
        on targetNode: SKNode,
        result: AttackResult,
        in gridScene: GridScene,
        at coordinate: Coordinate,
        completion: @escaping () -> Void
    ) {
        // Phase 1: Target flash
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.5, duration: 0.1),
            SKAction.colorize(with: .white, colorBlendFactor: 0, duration: 0.1)
        ])

        targetNode.run(flash) {
            // Phase 2: Impact effect
            switch result {
            case .hit:
                gridScene.playHitEffect(at: coordinate) {
                    completion()
                }
            case .miss:
                gridScene.playMissEffect(at: coordinate) {
                    completion()
                }
            case .sunk(let shipType):
                gridScene.playHitEffect(at: coordinate) {
                    // Additional sink notification could go here
                    completion()
                }
            }
        }
    }

    // MARK: - Turn Transition

    /// Creates a turn transition overlay animation.
    /// - Parameters:
    ///   - playerName: The name of the player whose turn it is
    ///   - parent: The parent node to add the overlay to
    ///   - sceneSize: The size of the scene
    ///   - completion: Called when the animation completes
    static func playTurnTransition(
        playerName: String,
        in parent: SKNode,
        sceneSize: CGSize,
        completion: @escaping () -> Void
    ) {
        // Overlay background
        let overlay = SKShapeNode(rectOf: sceneSize)
        overlay.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        overlay.fillColor = AppTheme.Colors.oceanDeep.withAlphaComponent(0.9)
        overlay.strokeColor = .clear
        overlay.zPosition = 1000
        overlay.alpha = 0

        // Turn label
        let label = SKLabelNode(fontNamed: AppTheme.Fonts.heading().fontName)
        label.text = "\(playerName)'s Turn"
        label.fontSize = 32
        label.fontColor = AppTheme.Colors.textPrimary
        label.position = .zero
        label.alpha = 0
        overlay.addChild(label)

        parent.addChild(overlay)

        // Animation sequence
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        let callback = SKAction.run { completion() }

        let labelFadeIn = SKAction.fadeIn(withDuration: 0.3)
        let labelPulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        let labelFadeOut = SKAction.fadeOut(withDuration: 0.3)

        overlay.run(SKAction.sequence([fadeIn, wait, fadeOut, callback, remove]))
        label.run(SKAction.sequence([
            labelFadeIn,
            labelPulse,
            SKAction.wait(forDuration: 0.6),
            labelFadeOut
        ]))
    }

    // MARK: - Victory/Defeat

    /// Plays the victory animation.
    /// - Parameters:
    ///   - parent: The parent node to add the animation to
    ///   - sceneSize: The size of the scene
    ///   - completion: Called when the animation completes
    static func playVictory(
        in parent: SKNode,
        sceneSize: CGSize,
        completion: @escaping () -> Void
    ) {
        playEndGameAnimation(
            title: "VICTORY!",
            color: AppTheme.Colors.victoryGreen,
            symbol: .victory,
            in: parent,
            sceneSize: sceneSize,
            completion: completion
        )
    }

    /// Plays the defeat animation.
    /// - Parameters:
    ///   - parent: The parent node to add the animation to
    ///   - sceneSize: The size of the scene
    ///   - completion: Called when the animation completes
    static func playDefeat(
        in parent: SKNode,
        sceneSize: CGSize,
        completion: @escaping () -> Void
    ) {
        playEndGameAnimation(
            title: "DEFEAT",
            color: AppTheme.Colors.hitRed,
            symbol: .defeat,
            in: parent,
            sceneSize: sceneSize,
            completion: completion
        )
    }

    private static func playEndGameAnimation(
        title: String,
        color: UIColor,
        symbol: SymbolSprites.GameSymbol,
        in parent: SKNode,
        sceneSize: CGSize,
        completion: @escaping () -> Void
    ) {
        // Container
        let container = SKNode()
        container.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        container.zPosition = 1000
        container.alpha = 0
        parent.addChild(container)

        // Background overlay
        let background = SKShapeNode(rectOf: sceneSize)
        background.fillColor = AppTheme.Colors.oceanDeep.withAlphaComponent(0.95)
        background.strokeColor = .clear
        container.addChild(background)

        // Symbol
        if let symbolSprite = SymbolSprites.sprite(
            for: symbol,
            pointSize: 80,
            weight: .bold,
            tint: color
        ) {
            symbolSprite.position = CGPoint(x: 0, y: 50)
            symbolSprite.setScale(0)
            container.addChild(symbolSprite)

            let scaleIn = SKAction.scale(to: 1.0, duration: 0.5)
            scaleIn.timingMode = .easeOut
            symbolSprite.run(scaleIn)
        }

        // Title label
        let titleLabel = SKLabelNode(fontNamed: AppTheme.Fonts.title().fontName)
        titleLabel.text = title
        titleLabel.fontSize = 48
        titleLabel.fontColor = color
        titleLabel.position = CGPoint(x: 0, y: -50)
        titleLabel.alpha = 0
        container.addChild(titleLabel)

        // Animation sequence
        let containerFadeIn = SKAction.fadeIn(withDuration: 0.3)
        let labelFadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 2.0)
        let callback = SKAction.run { completion() }

        container.run(SKAction.sequence([containerFadeIn, wait, callback]))
        titleLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            labelFadeIn
        ]))
    }

    // MARK: - Ship Placement

    /// Animates a ship being placed on the board.
    /// - Parameters:
    ///   - sprite: The ship sprite to animate
    ///   - targetPosition: The final position for the ship
    static func playShipPlacement(_ sprite: ShipSprite, to targetPosition: CGPoint) {
        sprite.alpha = 0.5
        sprite.setScale(1.1)

        let moveAndScale = SKAction.group([
            SKAction.move(to: targetPosition, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2),
            SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        ])
        moveAndScale.timingMode = .easeOut

        sprite.run(moveAndScale)
    }

    /// Animates a ship being removed from the board.
    /// - Parameters:
    ///   - sprite: The ship sprite to animate
    ///   - completion: Called when animation completes
    static func playShipRemoval(_ sprite: ShipSprite, completion: @escaping () -> Void) {
        let fadeAndShrink = SKAction.group([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.scale(to: 0.8, duration: 0.2)
        ])
        let remove = SKAction.removeFromParent()
        let callback = SKAction.run { completion() }

        sprite.run(SKAction.sequence([fadeAndShrink, callback, remove]))
    }

    // MARK: - Timer Warning

    /// Pulses a node to indicate time running low.
    /// - Parameter node: The node to pulse
    /// - Returns: The pulse action (run with repeatForever for continuous pulsing)
    static func timerWarningPulse() -> SKAction {
        return SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3),
            SKAction.colorize(with: AppTheme.Colors.warningOrange, colorBlendFactor: 0.3, duration: 0.3),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.3)
        ])
    }

    // MARK: - Cell Highlight

    /// Creates a highlight effect for a targetable cell.
    /// - Parameter node: The cell node to highlight
    /// - Returns: The highlight action
    static func cellHighlight() -> SKAction {
        return SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.2),
            SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        ])
    }

    // MARK: - Shake Effect

    /// Creates a shake effect (for invalid actions).
    /// - Parameter magnitude: The shake magnitude in points
    /// - Returns: The shake action
    static func shake(magnitude: CGFloat = 5) -> SKAction {
        let shakeLeft = SKAction.moveBy(x: -magnitude, y: 0, duration: 0.05)
        let shakeRight = SKAction.moveBy(x: magnitude * 2, y: 0, duration: 0.1)
        let shakeCenter = SKAction.moveBy(x: -magnitude, y: 0, duration: 0.05)

        return SKAction.sequence([
            shakeLeft,
            shakeRight,
            shakeCenter,
            shakeLeft,
            shakeRight,
            shakeCenter
        ])
    }

    // MARK: - Pop Effect

    /// Creates a pop-in effect for appearing elements.
    /// - Returns: The pop action
    static func popIn() -> SKAction {
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        scaleUp.timingMode = .easeOut
        scaleDown.timingMode = .easeIn

        return SKAction.sequence([
            SKAction.scale(to: 0, duration: 0),
            scaleUp,
            scaleDown
        ])
    }

    /// Creates a pop-out effect for disappearing elements.
    /// - Returns: The pop action
    static func popOut() -> SKAction {
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
        let scaleDown = SKAction.scale(to: 0, duration: 0.15)
        scaleUp.timingMode = .easeOut
        scaleDown.timingMode = .easeIn

        return SKAction.sequence([scaleUp, scaleDown])
    }
}
