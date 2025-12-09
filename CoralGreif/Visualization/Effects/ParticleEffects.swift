//
//  ParticleEffects.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import SpriteKit

/// Factory for creating particle effect emitters.
/// All effects are procedurally generated without external textures.
enum ParticleEffects {

    // MARK: - Explosion Effect (Hit)

    /// Creates an explosion effect for confirmed hits.
    /// Orange/red burst with outward velocity and alpha fade.
    /// - Parameter scale: Scale factor for the effect size (default 1.0)
    /// - Returns: Configured SKEmitterNode
    static func explosion(scale: CGFloat = 1.0) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Particle texture (procedural circle)
        emitter.particleTexture = generateCircleTexture(radius: 8)

        // Birth rate and lifetime
        emitter.particleBirthRate = 200
        emitter.numParticlesToEmit = 50
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2

        // Position
        emitter.particlePositionRange = CGVector(dx: 5 * scale, dy: 5 * scale)

        // Speed and direction (outward burst)
        emitter.particleSpeed = 150 * scale
        emitter.particleSpeedRange = 80 * scale
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2  // Full 360 degrees

        // Acceleration (slight upward drift for smoke effect)
        emitter.yAcceleration = 20

        // Size
        emitter.particleScale = 0.8 * scale
        emitter.particleScaleRange = 0.4 * scale
        emitter.particleScaleSpeed = -0.8

        // Color (orange to red gradient)
        emitter.particleColor = UIColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = colorSequence(
            colors: [
                UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0),  // Bright yellow
                UIColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1.0),  // Orange
                UIColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 0.8),  // Dark red
                UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.0)   // Smoke fade
            ],
            times: [0, 0.2, 0.5, 1.0]
        )

        // Alpha
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.5

        // Blend mode
        emitter.particleBlendMode = .add

        return emitter
    }

    // MARK: - Water Splash Effect (Miss)

    /// Creates a water splash effect for misses.
    /// Blue/white particles with upward burst then gravity fall.
    /// - Parameter scale: Scale factor for the effect size (default 1.0)
    /// - Returns: Configured SKEmitterNode
    static func waterSplash(scale: CGFloat = 1.0) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Particle texture (water droplet shape)
        emitter.particleTexture = generateCircleTexture(radius: 6)

        // Birth rate and lifetime
        emitter.particleBirthRate = 150
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3

        // Position
        emitter.particlePositionRange = CGVector(dx: 8 * scale, dy: 2 * scale)

        // Speed (upward burst)
        emitter.particleSpeed = 120 * scale
        emitter.particleSpeedRange = 60 * scale
        emitter.emissionAngle = .pi / 2  // Upward
        emitter.emissionAngleRange = .pi / 3  // Cone spread

        // Gravity (fall back down)
        emitter.yAcceleration = -300

        // Size
        emitter.particleScale = 0.5 * scale
        emitter.particleScaleRange = 0.3 * scale
        emitter.particleScaleSpeed = -0.3

        // Color (white to blue)
        emitter.particleColor = AppTheme.Colors.missWhite
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = colorSequence(
            colors: [
                UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),  // White
                UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.9), // Light blue
                UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 0.0)   // Ocean blue fade
            ],
            times: [0, 0.4, 1.0]
        )

        // Alpha
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -1.0

        // Blend mode
        emitter.particleBlendMode = .alpha

        return emitter
    }

    // MARK: - Smoke Plume Effect (Damaged)

    /// Creates a smoke plume effect for damaged ships.
    /// Gray particles with slow rise and drift.
    /// - Parameter scale: Scale factor for the effect size (default 1.0)
    /// - Returns: Configured SKEmitterNode
    static func smokePlume(scale: CGFloat = 1.0) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Particle texture (soft circle for smoke)
        emitter.particleTexture = generateSoftCircleTexture(radius: 16)

        // Birth rate and lifetime (continuous effect)
        emitter.particleBirthRate = 15
        emitter.numParticlesToEmit = 0  // Continuous
        emitter.particleLifetime = 2.5
        emitter.particleLifetimeRange = 0.5

        // Position
        emitter.particlePositionRange = CGVector(dx: 6 * scale, dy: 2 * scale)

        // Speed (slow rise)
        emitter.particleSpeed = 30 * scale
        emitter.particleSpeedRange = 15 * scale
        emitter.emissionAngle = .pi / 2  // Upward
        emitter.emissionAngleRange = .pi / 8  // Narrow cone

        // Drift
        emitter.xAcceleration = 10  // Slight wind drift
        emitter.yAcceleration = 5

        // Size (grows as it rises)
        emitter.particleScale = 0.3 * scale
        emitter.particleScaleRange = 0.1 * scale
        emitter.particleScaleSpeed = 0.15

        // Color (dark to light gray)
        emitter.particleColor = UIColor(white: 0.4, alpha: 0.8)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = colorSequence(
            colors: [
                UIColor(white: 0.3, alpha: 0.9),  // Dark gray
                UIColor(white: 0.5, alpha: 0.6),  // Medium gray
                UIColor(white: 0.7, alpha: 0.0)   // Light gray fade
            ],
            times: [0, 0.5, 1.0]
        )

        // Alpha
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.3

        // Blend mode
        emitter.particleBlendMode = .alpha

        return emitter
    }

    // MARK: - Fire Effect (Critical Damage)

    /// Creates a fire effect for critically damaged ships.
    /// Orange flicker with rapid birth rate.
    /// - Parameter scale: Scale factor for the effect size (default 1.0)
    /// - Returns: Configured SKEmitterNode
    static func fire(scale: CGFloat = 1.0) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Particle texture
        emitter.particleTexture = generateSoftCircleTexture(radius: 10)

        // Birth rate and lifetime (continuous, rapid)
        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 0  // Continuous
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2

        // Position
        emitter.particlePositionRange = CGVector(dx: 10 * scale, dy: 4 * scale)

        // Speed (upward flames)
        emitter.particleSpeed = 50 * scale
        emitter.particleSpeedRange = 30 * scale
        emitter.emissionAngle = .pi / 2  // Upward
        emitter.emissionAngleRange = .pi / 6

        // Flicker effect via acceleration variation
        emitter.xAcceleration = 0
        emitter.yAcceleration = 20

        // Size
        emitter.particleScale = 0.6 * scale
        emitter.particleScaleRange = 0.3 * scale
        emitter.particleScaleSpeed = -0.8

        // Color (yellow core to orange to red tip)
        emitter.particleColor = UIColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = colorSequence(
            colors: [
                UIColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1.0),  // Yellow core
                UIColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1.0),   // Orange
                UIColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 0.8),   // Red
                UIColor(red: 0.3, green: 0.1, blue: 0.1, alpha: 0.0)    // Dark red fade
            ],
            times: [0, 0.3, 0.7, 1.0]
        )

        // Alpha
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.8

        // Blend mode
        emitter.particleBlendMode = .add

        return emitter
    }

    // MARK: - Sinking Effect (Ship Destroyed)

    /// Creates a sinking effect with bubbles rising.
    /// - Parameter scale: Scale factor for the effect size (default 1.0)
    /// - Returns: Configured SKEmitterNode
    static func sinkingBubbles(scale: CGFloat = 1.0) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Particle texture (bubble)
        emitter.particleTexture = generateBubbleTexture(radius: 6)

        // Birth rate and lifetime
        emitter.particleBirthRate = 25
        emitter.numParticlesToEmit = 0  // Continuous until stopped
        emitter.particleLifetime = 1.5
        emitter.particleLifetimeRange = 0.5

        // Position (spread across ship width)
        emitter.particlePositionRange = CGVector(dx: 30 * scale, dy: 5 * scale)

        // Speed (upward bubbles)
        emitter.particleSpeed = 60 * scale
        emitter.particleSpeedRange = 30 * scale
        emitter.emissionAngle = .pi / 2  // Upward
        emitter.emissionAngleRange = .pi / 6

        // Wobble effect
        emitter.xAcceleration = 0

        // Size variation
        emitter.particleScale = 0.4 * scale
        emitter.particleScaleRange = 0.3 * scale
        emitter.particleScaleSpeed = 0.1

        // Color
        emitter.particleColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.7)
        emitter.particleColorBlendFactor = 1.0

        // Alpha (pop at surface)
        emitter.particleAlpha = 0.7
        emitter.particleAlphaSpeed = -0.4

        // Blend mode
        emitter.particleBlendMode = .alpha

        // Rotation for visual variety
        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi
        emitter.particleRotationSpeed = 1.0

        return emitter
    }

    // MARK: - Texture Generation

    /// Generates a solid circle texture for particles.
    private static func generateCircleTexture(radius: CGFloat) -> SKTexture {
        let size = CGSize(width: radius * 2, height: radius * 2)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: rect)
        }

        return SKTexture(image: image)
    }

    /// Generates a soft-edged circle texture for smoke/fire effects.
    private static func generateSoftCircleTexture(radius: CGFloat) -> SKTexture {
        let size = CGSize(width: radius * 2, height: radius * 2)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let center = CGPoint(x: radius, y: radius)
            let colors = [
                UIColor.white.cgColor,
                UIColor.white.withAlphaComponent(0.5).cgColor,
                UIColor.white.withAlphaComponent(0).cgColor
            ]
            let locations: [CGFloat] = [0, 0.5, 1.0]

            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: locations
            ) {
                context.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: []
                )
            }
        }

        return SKTexture(image: image)
    }

    /// Generates a bubble texture with highlight.
    private static func generateBubbleTexture(radius: CGFloat) -> SKTexture {
        let size = CGSize(width: radius * 2, height: radius * 2)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // Bubble body (semi-transparent)
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            context.cgContext.fillEllipse(in: rect)

            // Bubble outline
            context.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.6).cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.strokeEllipse(in: rect.insetBy(dx: 0.5, dy: 0.5))

            // Highlight
            let highlightRect = CGRect(
                x: radius * 0.3,
                y: radius * 0.3,
                width: radius * 0.5,
                height: radius * 0.4
            )
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.7).cgColor)
            context.cgContext.fillEllipse(in: highlightRect)
        }

        return SKTexture(image: image)
    }

    // MARK: - Color Sequence Helper

    /// Creates a color sequence for particle color animation.
    private static func colorSequence(colors: [UIColor], times: [CGFloat]) -> SKKeyframeSequence {
        let sequence = SKKeyframeSequence(keyframeValues: colors, times: times as [NSNumber])
        sequence.interpolationMode = .linear
        return sequence
    }
}

// MARK: - Convenience Methods

extension ParticleEffects {

    /// Plays an explosion effect at a position and removes it when done.
    /// - Parameters:
    ///   - position: The position in the parent's coordinate system
    ///   - parent: The parent node to add the effect to
    ///   - completion: Called when the effect completes
    static func playExplosion(
        at position: CGPoint,
        in parent: SKNode,
        completion: (() -> Void)? = nil
    ) {
        let emitter = explosion()
        emitter.position = position
        emitter.zPosition = 100
        parent.addChild(emitter)

        let wait = SKAction.wait(forDuration: 0.8)
        let remove = SKAction.removeFromParent()
        let callback = SKAction.run { completion?() }

        emitter.run(SKAction.sequence([wait, callback, remove]))
    }

    /// Plays a water splash effect at a position and removes it when done.
    /// - Parameters:
    ///   - position: The position in the parent's coordinate system
    ///   - parent: The parent node to add the effect to
    ///   - completion: Called when the effect completes
    static func playSplash(
        at position: CGPoint,
        in parent: SKNode,
        completion: (() -> Void)? = nil
    ) {
        let emitter = waterSplash()
        emitter.position = position
        emitter.zPosition = 100
        parent.addChild(emitter)

        let wait = SKAction.wait(forDuration: 1.0)
        let remove = SKAction.removeFromParent()
        let callback = SKAction.run { completion?() }

        emitter.run(SKAction.sequence([wait, callback, remove]))
    }
}
