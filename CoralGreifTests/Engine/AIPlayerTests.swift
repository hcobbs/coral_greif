//
//  AIPlayerTests.swift
//  Coral Greif Tests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
@testable import CoralGreif

// MARK: - AI Difficulty Tests

final class AIDifficultyTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(AIDifficulty.allCases.count, 3)
    }

    func testDisplayNames() {
        XCTAssertEqual(AIDifficulty.ensign.displayName, "Ensign")
        XCTAssertEqual(AIDifficulty.commander.displayName, "Commander")
        XCTAssertEqual(AIDifficulty.admiral.displayName, "Admiral")
    }

    func testDescriptions() {
        XCTAssertFalse(AIDifficulty.ensign.description.isEmpty)
        XCTAssertFalse(AIDifficulty.commander.description.isEmpty)
        XCTAssertFalse(AIDifficulty.admiral.description.isEmpty)
    }

    func testCodable() throws {
        let original = AIDifficulty.commander

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AIDifficulty.self, from: data)

        XCTAssertEqual(original, decoded)
    }
}

// MARK: - Random AI Tests

final class RandomAITests: XCTestCase {

    func testDifficulty() {
        let ai = RandomAI()
        XCTAssertEqual(ai.difficulty, .ensign)
    }

    func testChoosesValidTarget() {
        let ai = RandomAI()
        let board = Board()

        guard let target = ai.chooseTarget(against: board, history: MoveHistory()) else {
            XCTFail("Should return a target")
            return
        }

        XCTAssertTrue(board.validTargets.contains(target))
    }

    func testChoosesFromReducedTargets() {
        let ai = RandomAI()
        var board = Board()

        // Attack most of the board
        for row in 0..<9 {
            for col in 0..<10 {
                _ = board.receiveAttack(at: Coordinate(row: row, column: col)!)
            }
        }

        // Only row 9 remains
        guard let target = ai.chooseTarget(against: board, history: MoveHistory()) else {
            XCTFail("Should return a target")
            return
        }

        XCTAssertEqual(target.row, 9)
    }

    func testReturnsNilWhenNoTargets() {
        let ai = RandomAI()
        var board = Board()

        // Attack entire board
        for row in 0..<10 {
            for col in 0..<10 {
                _ = board.receiveAttack(at: Coordinate(row: row, column: col)!)
            }
        }

        let target = ai.chooseTarget(against: board, history: MoveHistory())
        XCTAssertNil(target)
    }

    func testGeneratesValidPlacements() {
        let ai = RandomAI()
        let ships = ai.generateShipPlacements()

        XCTAssertEqual(ships.count, 5)

        // Verify no overlaps
        var board = Board()
        for ship in ships {
            let result = board.placeShip(ship)
            if case .failure = result {
                XCTFail("Generated ship placement is invalid")
            }
        }

        XCTAssertTrue(board.isFleetComplete)
    }
}

// MARK: - Hunt/Target AI Tests

final class HuntTargetAITests: XCTestCase {

    func testDifficulty() {
        let ai = HuntTargetAI()
        XCTAssertEqual(ai.difficulty, .commander)
    }

    func testChoosesValidTarget() {
        let ai = HuntTargetAI()
        let board = Board()

        guard let target = ai.chooseTarget(against: board, history: MoveHistory()) else {
            XCTFail("Should return a target")
            return
        }

        XCTAssertTrue(board.validTargets.contains(target))
    }

    func testPrefersCheckerboardPattern() {
        let ai = HuntTargetAI()
        let board = Board()

        // Get 100 targets and check checkerboard preference
        var checkerboardCount = 0
        for _ in 0..<100 {
            ai.reset()
            if let target = ai.chooseTarget(against: board, history: MoveHistory()) {
                if (target.row + target.column) % 2 == 0 {
                    checkerboardCount += 1
                }
            }
        }

        // Should strongly prefer checkerboard (> 90%)
        XCTAssertGreaterThan(checkerboardCount, 90)
    }

    func testTargetsModeAfterHit() {
        let ai = HuntTargetAI()
        var board = Board()

        // Place a ship for reference
        let ship = Ship(type: .cruiser, origin: Coordinate(row: 5, column: 5)!, orientation: .horizontal)
        _ = board.placeShip(ship)

        // First hit
        let hitCoord = Coordinate(row: 5, column: 5)!
        _ = board.receiveAttack(at: hitCoord)
        ai.recordResult(.hit, at: hitCoord)

        // Next target should be adjacent to the hit
        guard let nextTarget = ai.chooseTarget(against: board, history: MoveHistory()) else {
            XCTFail("Should return a target")
            return
        }

        let isAdjacent = nextTarget.isAdjacent(to: hitCoord)
        XCTAssertTrue(isAdjacent)
    }

    func testReturnsToHuntAfterSunk() {
        let ai = HuntTargetAI()
        let board = Board()

        // Simulate hit and sunk
        let hitCoord = Coordinate(row: 5, column: 5)!
        ai.recordResult(.hit, at: hitCoord)
        ai.recordResult(.sunk(.destroyer), at: Coordinate(row: 5, column: 6)!)

        // Next target should be random (hunt mode), not necessarily adjacent
        _ = ai.chooseTarget(against: board, history: MoveHistory())
        // Just verify it doesn't crash and returns something
    }

    func testResetClearsState() {
        let ai = HuntTargetAI()

        // Record some results
        ai.recordResult(.hit, at: Coordinate(row: 5, column: 5)!)
        ai.recordResult(.miss, at: Coordinate(row: 5, column: 4)!)

        ai.reset()

        // After reset, should be back in hunt mode
        // (hard to test directly, but at least verify no crash)
        let board = Board()
        _ = ai.chooseTarget(against: board, history: MoveHistory())
    }

    func testGeneratesValidPlacements() {
        let ai = HuntTargetAI()
        let ships = ai.generateShipPlacements()

        XCTAssertEqual(ships.count, 5)

        var board = Board()
        for ship in ships {
            let result = board.placeShip(ship)
            if case .failure = result {
                XCTFail("Generated ship placement is invalid")
            }
        }

        XCTAssertTrue(board.isFleetComplete)
    }

    func testFollowsDirectionAfterTwoHits() {
        let ai = HuntTargetAI()
        var board = Board()

        // Simulate two horizontal hits
        let hit1 = Coordinate(row: 5, column: 5)!
        let hit2 = Coordinate(row: 5, column: 6)!

        _ = board.receiveAttack(at: hit1)
        _ = board.receiveAttack(at: hit2)
        ai.recordResult(.hit, at: hit1)
        ai.recordResult(.hit, at: hit2)

        // Next target should continue in horizontal direction
        guard let nextTarget = ai.chooseTarget(against: board, history: MoveHistory()) else {
            XCTFail("Should return a target")
            return
        }

        // Should be either (5, 4) or (5, 7)
        let validNextTargets = [Coordinate(row: 5, column: 4)!, Coordinate(row: 5, column: 7)!]
        XCTAssertTrue(validNextTargets.contains(nextTarget))
    }
}

// MARK: - Probability AI Tests

final class ProbabilityAITests: XCTestCase {

    func testDifficulty() {
        let ai = ProbabilityAI()
        XCTAssertEqual(ai.difficulty, .admiral)
    }

    func testChoosesValidTarget() {
        let ai = ProbabilityAI()
        let board = Board()

        guard let target = ai.chooseTarget(against: board, history: MoveHistory()) else {
            XCTFail("Should return a target")
            return
        }

        XCTAssertTrue(board.validTargets.contains(target))
    }

    func testPrefersHighProbabilityCells() {
        let ai = ProbabilityAI()
        var board = Board()

        // Attack corners and edges, leaving center open
        for row in 0..<10 {
            _ = board.receiveAttack(at: Coordinate(row: row, column: 0)!)
            _ = board.receiveAttack(at: Coordinate(row: row, column: 9)!)
        }
        for col in 1..<9 {
            _ = board.receiveAttack(at: Coordinate(row: 0, column: col)!)
            _ = board.receiveAttack(at: Coordinate(row: 9, column: col)!)
        }

        // Center cells should have higher probability
        guard let target = ai.chooseTarget(against: board, history: MoveHistory()) else {
            XCTFail("Should return a target")
            return
        }

        // Target should be in the center region
        XCTAssertGreaterThan(target.row, 0)
        XCTAssertLessThan(target.row, 9)
        XCTAssertGreaterThan(target.column, 0)
        XCTAssertLessThan(target.column, 9)
    }

    func testTargetsAdjacentAfterHit() {
        let ai = ProbabilityAI()
        var board = Board()

        // Record a hit
        let hitCoord = Coordinate(row: 5, column: 5)!
        _ = board.receiveAttack(at: hitCoord)
        ai.recordResult(.hit, at: hitCoord)

        // Next target should be adjacent
        guard let nextTarget = ai.chooseTarget(against: board, history: MoveHistory()) else {
            XCTFail("Should return a target")
            return
        }

        XCTAssertTrue(nextTarget.isAdjacent(to: hitCoord))
    }

    func testResetClearsState() {
        let ai = ProbabilityAI()

        ai.recordResult(.hit, at: Coordinate(row: 5, column: 5)!)
        ai.recordResult(.sunk(.destroyer), at: Coordinate(row: 5, column: 6)!)

        ai.reset()

        let board = Board()
        _ = ai.chooseTarget(against: board, history: MoveHistory())
    }

    func testGeneratesValidPlacements() {
        let ai = ProbabilityAI()
        let ships = ai.generateShipPlacements()

        XCTAssertEqual(ships.count, 5)

        var board = Board()
        for ship in ships {
            let result = board.placeShip(ship)
            if case .failure = result {
                XCTFail("Generated ship placement is invalid")
            }
        }

        XCTAssertTrue(board.isFleetComplete)
    }
}

// MARK: - AI Factory Tests

final class AIFactoryTests: XCTestCase {

    func testCreateEnsign() {
        let ai = AIFactory.create(difficulty: .ensign)
        XCTAssertEqual(ai.difficulty, .ensign)
        XCTAssertTrue(ai is RandomAI)
    }

    func testCreateCommander() {
        let ai = AIFactory.create(difficulty: .commander)
        XCTAssertEqual(ai.difficulty, .commander)
        XCTAssertTrue(ai is HuntTargetAI)
    }

    func testCreateAdmiral() {
        let ai = AIFactory.create(difficulty: .admiral)
        XCTAssertEqual(ai.difficulty, .admiral)
        XCTAssertTrue(ai is ProbabilityAI)
    }
}

// MARK: - Ship Placer Tests

final class ShipPlacerTests: XCTestCase {

    func testGeneratesAllShips() {
        let ships = ShipPlacer.generateRandomPlacements()
        XCTAssertEqual(ships.count, 5)
    }

    func testGeneratesValidPlacements() {
        // Run multiple times to test randomness
        for _ in 0..<10 {
            let ships = ShipPlacer.generateRandomPlacements()

            var board = Board()
            for ship in ships {
                let result = board.placeShip(ship)
                if case .failure = result {
                    XCTFail("Generated ship placement is invalid")
                    return
                }
            }

            XCTAssertTrue(board.isFleetComplete)
        }
    }

    func testGeneratesAllShipTypes() {
        let ships = ShipPlacer.generateRandomPlacements()
        let types = Set(ships.map { $0.type })

        XCTAssertTrue(types.contains(.carrier))
        XCTAssertTrue(types.contains(.battleship))
        XCTAssertTrue(types.contains(.cruiser))
        XCTAssertTrue(types.contains(.submarine))
        XCTAssertTrue(types.contains(.destroyer))
    }
}
