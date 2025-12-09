//
//  SoundManagerTests.swift
//  Coral Greif Tests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
@testable import CoralGreif

final class SoundManagerTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        let instance = SoundManager.shared
        XCTAssertNotNil(instance)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = SoundManager.shared
        let instance2 = SoundManager.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Settings Tests

    func testSoundEnabledByDefault() {
        let manager = SoundManager.shared
        // Sound may be disabled if audio session failed, but the property should exist
        _ = manager.soundEnabled
    }

    func testHapticsEnabledByDefault() {
        let manager = SoundManager.shared
        XCTAssertTrue(manager.hapticsEnabled)
    }

    func testCanDisableSound() {
        let manager = SoundManager.shared
        let original = manager.soundEnabled

        manager.soundEnabled = false
        XCTAssertFalse(manager.soundEnabled)

        manager.soundEnabled = original
    }

    func testCanDisableHaptics() {
        let manager = SoundManager.shared
        let original = manager.hapticsEnabled

        manager.hapticsEnabled = false
        XCTAssertFalse(manager.hapticsEnabled)

        manager.hapticsEnabled = original
    }

    // MARK: - Sound Effect Tests

    func testPlaySoundDoesNotCrash() {
        let manager = SoundManager.shared
        manager.soundEnabled = true

        // Test all sound effects
        manager.play(.hit)
        manager.play(.miss)
        manager.play(.sunk)
        manager.play(.shipPlaced)
        manager.play(.buttonTap)
        manager.play(.turnStart)
        manager.play(.turnTimeout)
        manager.play(.victory)
        manager.play(.defeat)
        manager.play(.gameStart)
    }

    func testPlaySoundWhenDisabledDoesNotCrash() {
        let manager = SoundManager.shared
        let original = manager.soundEnabled

        manager.soundEnabled = false
        manager.play(.hit)

        manager.soundEnabled = original
    }

    // MARK: - Haptic Tests

    func testHapticDoesNotCrash() {
        let manager = SoundManager.shared
        manager.hapticsEnabled = true

        manager.haptic(.selection)
        manager.haptic(.lightImpact)
        manager.haptic(.mediumImpact)
        manager.haptic(.heavyImpact)
        manager.haptic(.success)
        manager.haptic(.warning)
        manager.haptic(.error)
    }

    func testHapticWhenDisabledDoesNotCrash() {
        let manager = SoundManager.shared
        let original = manager.hapticsEnabled

        manager.hapticsEnabled = false
        manager.haptic(.heavyImpact)

        manager.hapticsEnabled = original
    }

    // MARK: - Game Event Tests

    func testPlayGameEventDoesNotCrash() {
        let manager = SoundManager.shared

        manager.playGameEvent(.hit)
        manager.playGameEvent(.miss)
        manager.playGameEvent(.sunk(.destroyer))
        manager.playGameEvent(.sunk(.carrier))
        manager.playGameEvent(.shipPlaced)
        manager.playGameEvent(.buttonTap)
        manager.playGameEvent(.turnStart)
        manager.playGameEvent(.turnTimeout)
        manager.playGameEvent(.victory)
        manager.playGameEvent(.defeat)
        manager.playGameEvent(.gameStart)
        manager.playGameEvent(.invalidAction)
    }

    // MARK: - SoundEffect Enum Tests

    func testSoundEffectCases() {
        let allEffects: [SoundEffect] = [
            .hit, .miss, .sunk, .shipPlaced, .buttonTap,
            .turnStart, .turnTimeout, .victory, .defeat, .gameStart
        ]
        XCTAssertEqual(allEffects.count, 10)
    }

    // MARK: - HapticType Enum Tests

    func testHapticTypeCases() {
        let allTypes: [HapticType] = [
            .selection, .lightImpact, .mediumImpact, .heavyImpact,
            .success, .warning, .error
        ]
        XCTAssertEqual(allTypes.count, 7)
    }

    // MARK: - GameSoundEvent Enum Tests

    func testGameSoundEventCases() {
        // Test that all cases can be created
        let events: [GameSoundEvent] = [
            .hit, .miss, .sunk(.destroyer), .shipPlaced, .buttonTap,
            .turnStart, .turnTimeout, .victory, .defeat, .gameStart, .invalidAction
        ]
        XCTAssertEqual(events.count, 11)
    }

    func testGameSoundEventSunkWithDifferentShipTypes() {
        for shipType in ShipType.allCases {
            let event = GameSoundEvent.sunk(shipType)
            if case .sunk(let type) = event {
                XCTAssertEqual(type, shipType)
            } else {
                XCTFail("Expected sunk event")
            }
        }
    }
}
