//
//  ParticleEffectsTests.swift
//  CoralGreifTests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
import SpriteKit
@testable import CoralGreif

final class ParticleEffectsTests: XCTestCase {

    // MARK: - Explosion Effect Tests

    func testExplosionCreation() {
        let emitter = ParticleEffects.explosion()
        XCTAssertNotNil(emitter, "Explosion emitter should be created")
        XCTAssertNotNil(emitter.particleTexture, "Explosion should have a texture")
    }

    func testExplosionConfiguration() {
        let emitter = ParticleEffects.explosion()
        XCTAssertGreaterThan(emitter.particleBirthRate, 0, "Explosion should have positive birth rate")
        XCTAssertGreaterThan(emitter.numParticlesToEmit, 0, "Explosion should emit particles")
        XCTAssertGreaterThan(emitter.particleLifetime, 0, "Particles should have lifetime")
    }

    func testExplosionWithScale() {
        let smallExplosion = ParticleEffects.explosion(scale: 0.5)
        let largeExplosion = ParticleEffects.explosion(scale: 2.0)

        XCTAssertLessThan(smallExplosion.particleSpeed, largeExplosion.particleSpeed,
                          "Larger scale should have higher particle speed")
    }

    // MARK: - Water Splash Effect Tests

    func testWaterSplashCreation() {
        let emitter = ParticleEffects.waterSplash()
        XCTAssertNotNil(emitter, "Water splash emitter should be created")
        XCTAssertNotNil(emitter.particleTexture, "Water splash should have a texture")
    }

    func testWaterSplashConfiguration() {
        let emitter = ParticleEffects.waterSplash()
        XCTAssertGreaterThan(emitter.particleBirthRate, 0, "Splash should have positive birth rate")
        XCTAssertGreaterThan(emitter.numParticlesToEmit, 0, "Splash should emit particles")

        // Splash should have gravity
        XCTAssertLessThan(emitter.yAcceleration, 0, "Water splash should fall down")
    }

    func testWaterSplashWithScale() {
        let smallSplash = ParticleEffects.waterSplash(scale: 0.5)
        let largeSplash = ParticleEffects.waterSplash(scale: 2.0)

        XCTAssertLessThan(smallSplash.particleSpeed, largeSplash.particleSpeed,
                          "Larger scale should have higher particle speed")
    }

    // MARK: - Smoke Plume Effect Tests

    func testSmokePlumeCreation() {
        let emitter = ParticleEffects.smokePlume()
        XCTAssertNotNil(emitter, "Smoke plume emitter should be created")
        XCTAssertNotNil(emitter.particleTexture, "Smoke should have a texture")
    }

    func testSmokePlumeIsContinuous() {
        let emitter = ParticleEffects.smokePlume()
        XCTAssertEqual(emitter.numParticlesToEmit, 0, "Smoke should be continuous (0 = unlimited)")
        XCTAssertGreaterThan(emitter.particleBirthRate, 0, "Smoke should emit particles")
    }

    func testSmokePlumeRises() {
        let emitter = ParticleEffects.smokePlume()
        XCTAssertEqual(emitter.emissionAngle, .pi / 2, accuracy: 0.01,
                       "Smoke should emit upward")
    }

    // MARK: - Fire Effect Tests

    func testFireCreation() {
        let emitter = ParticleEffects.fire()
        XCTAssertNotNil(emitter, "Fire emitter should be created")
        XCTAssertNotNil(emitter.particleTexture, "Fire should have a texture")
    }

    func testFireIsContinuous() {
        let emitter = ParticleEffects.fire()
        XCTAssertEqual(emitter.numParticlesToEmit, 0, "Fire should be continuous")
        XCTAssertGreaterThan(emitter.particleBirthRate, 50, "Fire should have rapid birth rate")
    }

    func testFireUsesAdditiveBlending() {
        let emitter = ParticleEffects.fire()
        XCTAssertEqual(emitter.particleBlendMode, .add, "Fire should use additive blending")
    }

    // MARK: - Sinking Bubbles Effect Tests

    func testSinkingBubblesCreation() {
        let emitter = ParticleEffects.sinkingBubbles()
        XCTAssertNotNil(emitter, "Sinking bubbles emitter should be created")
        XCTAssertNotNil(emitter.particleTexture, "Bubbles should have a texture")
    }

    func testSinkingBubblesRise() {
        let emitter = ParticleEffects.sinkingBubbles()
        XCTAssertEqual(emitter.emissionAngle, .pi / 2, accuracy: 0.01,
                       "Bubbles should rise upward")
    }

    func testSinkingBubblesIsContinuous() {
        let emitter = ParticleEffects.sinkingBubbles()
        XCTAssertEqual(emitter.numParticlesToEmit, 0, "Bubbles should be continuous until stopped")
    }

    // MARK: - Scale Parameter Tests

    func testAllEffectsAcceptScale() {
        let scales: [CGFloat] = [0.5, 1.0, 2.0]

        for scale in scales {
            let explosion = ParticleEffects.explosion(scale: scale)
            XCTAssertNotNil(explosion, "Explosion with scale \(scale) should be created")

            let splash = ParticleEffects.waterSplash(scale: scale)
            XCTAssertNotNil(splash, "Splash with scale \(scale) should be created")

            let smoke = ParticleEffects.smokePlume(scale: scale)
            XCTAssertNotNil(smoke, "Smoke with scale \(scale) should be created")

            let fire = ParticleEffects.fire(scale: scale)
            XCTAssertNotNil(fire, "Fire with scale \(scale) should be created")

            let bubbles = ParticleEffects.sinkingBubbles(scale: scale)
            XCTAssertNotNil(bubbles, "Bubbles with scale \(scale) should be created")
        }
    }

    // MARK: - Convenience Method Tests

    func testPlayExplosionAddsToParent() {
        let parent = SKNode()

        ParticleEffects.playExplosion(at: .zero, in: parent, completion: nil)

        // Effect should be added to parent immediately
        XCTAssertEqual(parent.children.count, 1, "Effect should be added to parent")

        // Child should be an emitter
        XCTAssertTrue(parent.children.first is SKEmitterNode, "Child should be an emitter")
    }

    func testPlaySplashAddsToParent() {
        let parent = SKNode()

        ParticleEffects.playSplash(at: .zero, in: parent, completion: nil)

        // Effect should be added to parent immediately
        XCTAssertEqual(parent.children.count, 1, "Effect should be added to parent")

        // Child should be an emitter
        XCTAssertTrue(parent.children.first is SKEmitterNode, "Child should be an emitter")
    }

    func testPlayExplosionPositionsCorrectly() {
        let parent = SKNode()
        let position = CGPoint(x: 100, y: 200)

        ParticleEffects.playExplosion(at: position, in: parent, completion: nil)

        let emitter = parent.children.first
        XCTAssertEqual(emitter?.position, position, "Effect should be at specified position")
    }

    func testPlaySplashPositionsCorrectly() {
        let parent = SKNode()
        let position = CGPoint(x: 50, y: 150)

        ParticleEffects.playSplash(at: position, in: parent, completion: nil)

        let emitter = parent.children.first
        XCTAssertEqual(emitter?.position, position, "Effect should be at specified position")
    }
}
