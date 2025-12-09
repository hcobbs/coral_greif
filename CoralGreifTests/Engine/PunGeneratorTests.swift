//
//  PunGeneratorTests.swift
//  Coral Greif Tests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
@testable import CoralGreif

final class PunGeneratorTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        let generator = PunGenerator.shared
        XCTAssertNotNil(generator)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = PunGenerator.shared
        let instance2 = PunGenerator.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Category Tests

    func testOnHitReturnsNonEmpty() {
        let pun = PunGenerator.shared.pun(for: .onHit)
        XCTAssertFalse(pun.isEmpty)
    }

    func testOnMissReturnsNonEmpty() {
        let pun = PunGenerator.shared.pun(for: .onMiss)
        XCTAssertFalse(pun.isEmpty)
    }

    func testOnSunkReturnsNonEmpty() {
        for shipType in ShipType.allCases {
            let pun = PunGenerator.shared.pun(for: .onSunk(shipType))
            XCTAssertFalse(pun.isEmpty, "Empty pun for sunk \(shipType)")
        }
    }

    func testOnConsecutiveMissesThree() {
        let pun = PunGenerator.shared.pun(for: .onConsecutiveMisses(count: 3))
        XCTAssertFalse(pun.isEmpty)
    }

    func testOnConsecutiveMissesFive() {
        let pun = PunGenerator.shared.pun(for: .onConsecutiveMisses(count: 5))
        XCTAssertFalse(pun.isEmpty)
    }

    func testOnGettingHitReturnsNonEmpty() {
        let pun = PunGenerator.shared.pun(for: .onGettingHit)
        XCTAssertFalse(pun.isEmpty)
    }

    func testOnGettingSunkReturnsNonEmpty() {
        for shipType in ShipType.allCases {
            let pun = PunGenerator.shared.pun(for: .onGettingSunk(shipType))
            XCTAssertFalse(pun.isEmpty, "Empty pun for getting sunk \(shipType)")
        }
    }

    func testOnVictoryReturnsNonEmpty() {
        let pun = PunGenerator.shared.pun(for: .onVictory)
        XCTAssertFalse(pun.isEmpty)
    }

    func testOnDefeatReturnsNonEmpty() {
        let pun = PunGenerator.shared.pun(for: .onDefeat)
        XCTAssertFalse(pun.isEmpty)
    }

    func testOnGameStartReturnsNonEmpty() {
        let pun = PunGenerator.shared.pun(for: .onGameStart)
        XCTAssertFalse(pun.isEmpty)
    }

    func testOnTurnStartReturnsNonEmpty() {
        let pun = PunGenerator.shared.pun(for: .onTurnStart)
        XCTAssertFalse(pun.isEmpty)
    }

    func testOnTimeoutReturnsNonEmpty() {
        let pun = PunGenerator.shared.pun(for: .onTimeout)
        XCTAssertFalse(pun.isEmpty)
    }

    // MARK: - All Puns Tests

    func testAllPunsReturnsMultiple() {
        let puns = PunGenerator.shared.allPuns(for: .onHit)
        XCTAssertGreaterThan(puns.count, 5)
    }

    func testAllSunkPunsIncludeShipSpecific() {
        let carrierPuns = PunGenerator.shared.allPuns(for: .onSunk(.carrier))
        let destroyerPuns = PunGenerator.shared.allPuns(for: .onSunk(.destroyer))

        // Should have different counts due to ship-specific puns
        XCTAssertGreaterThan(carrierPuns.count, 5)
        XCTAssertGreaterThan(destroyerPuns.count, 5)
    }

    // MARK: - Randomness Tests

    func testPunsAreRandomized() {
        var uniquePuns: Set<String> = []

        // Get 50 puns and check for variety
        for _ in 0..<50 {
            let pun = PunGenerator.shared.pun(for: .onHit)
            uniquePuns.insert(pun)
        }

        // Should have gotten at least a few different puns
        XCTAssertGreaterThan(uniquePuns.count, 3)
    }

    // MARK: - Convenience Method Tests

    func testPunForAttackResultMiss() {
        let pun = PunGenerator.shared.pun(for: .miss, isPlayerAttack: true)
        XCTAssertFalse(pun.isEmpty)
    }

    func testPunForAttackResultHit() {
        let pun = PunGenerator.shared.pun(for: .hit, isPlayerAttack: true)
        XCTAssertFalse(pun.isEmpty)
    }

    func testPunForAttackResultSunk() {
        let pun = PunGenerator.shared.pun(for: .sunk(.carrier), isPlayerAttack: true)
        XCTAssertFalse(pun.isEmpty)
    }

    func testPunForOpponentAttack() {
        let hitPun = PunGenerator.shared.pun(for: .hit, isPlayerAttack: false)
        XCTAssertFalse(hitPun.isEmpty)

        let sunkPun = PunGenerator.shared.pun(for: .sunk(.destroyer), isPlayerAttack: false)
        XCTAssertFalse(sunkPun.isEmpty)
    }

    // MARK: - Content Quality Tests

    func testPunsDoNotContainEmDashes() {
        let categories: [PunCategory] = [
            .onHit, .onMiss, .onGettingHit, .onVictory, .onDefeat,
            .onGameStart, .onTurnStart, .onTimeout,
            .onSunk(.carrier), .onSunk(.battleship), .onSunk(.cruiser),
            .onSunk(.submarine), .onSunk(.destroyer),
            .onGettingSunk(.carrier), .onGettingSunk(.destroyer),
            .onConsecutiveMisses(count: 3), .onConsecutiveMisses(count: 5)
        ]

        for category in categories {
            let puns = PunGenerator.shared.allPuns(for: category)
            for pun in puns {
                XCTAssertFalse(pun.contains("—"), "Pun contains em dash: \(pun)")
            }
        }
    }

    func testPunsAreNotEmpty() {
        let categories: [PunCategory] = [
            .onHit, .onMiss, .onGettingHit, .onVictory, .onDefeat,
            .onGameStart, .onTurnStart, .onTimeout
        ]

        for category in categories {
            let puns = PunGenerator.shared.allPuns(for: category)
            XCTAssertGreaterThan(puns.count, 0, "No puns for category")

            for pun in puns {
                XCTAssertFalse(pun.isEmpty, "Empty pun found")
                XCTAssertGreaterThan(pun.count, 5, "Pun too short: \(pun)")
            }
        }
    }
}
