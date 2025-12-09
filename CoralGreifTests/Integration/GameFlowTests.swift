//
//  GameFlowTests.swift
//  Coral Greif Tests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
@testable import CoralGreif

/// Integration tests for complete game flows.
final class GameFlowTests: XCTestCase {

    // MARK: - Full Game Flow Tests

    func testCompleteGameAgainstRandomAI() {
        // Create players
        let human = Profile(name: "Test Player")
        let ai = Profile.aiPlayer(name: "Ensign AI")

        // Create engine with Random AI
        let aiPlayer = RandomAI()
        let engine = GameEngine(
            player1: human,
            player2: ai,
            turnDuration: 20.0,
            aiPlayer: aiPlayer
        )

        // Place human ships
        let humanShips = ShipPlacer.generateRandomPlacements()
        for ship in humanShips {
            let result = engine.placeShip(ship, for: human.id)
            if case .failure = result {
                XCTFail("Failed to place human ship")
                return
            }
        }

        // Place AI ships
        let aiShips = aiPlayer.generateShipPlacements()
        for ship in aiShips {
            let result = engine.placeShip(ship, for: ai.id)
            if case .failure = result {
                XCTFail("Failed to place AI ship")
                return
            }
        }

        // Verify both fleets are complete
        XCTAssertTrue(engine.canStartBattle)

        // Start battle
        let startResult = engine.startBattle()
        XCTAssertNotNil(try? startResult.get())
        XCTAssertTrue(engine.isStarted)

        // Simulate turns until game ends (max 200 turns to prevent infinite loop)
        var turnCount = 0
        let maxTurns = 200

        while !engine.isFinished && turnCount < maxTurns {
            let currentPlayer = engine.currentPlayerId
            let targetBoard = engine.gameState.opponentBoard(for: currentPlayer)!
            let validTargets = targetBoard.validTargets

            if let target = validTargets.randomElement() {
                _ = engine.executeAttack(at: target, by: currentPlayer)
            }
            turnCount += 1
        }

        // Verify game completed
        XCTAssertTrue(engine.isFinished, "Game should have finished")
        XCTAssertNotNil(engine.winnerId, "Should have a winner")
        XCTAssertLessThan(turnCount, maxTurns, "Game should complete before max turns")
    }

    func testCompleteGameAgainstHuntTargetAI() {
        let human = Profile(name: "Test Player")
        let ai = Profile.aiPlayer(name: "Commander AI")

        let aiPlayer = HuntTargetAI()
        let engine = GameEngine(
            player1: human,
            player2: ai,
            turnDuration: 20.0,
            aiPlayer: aiPlayer
        )

        // Setup ships
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: human.id)
        }
        for ship in aiPlayer.generateShipPlacements() {
            _ = engine.placeShip(ship, for: ai.id)
        }

        _ = engine.startBattle()

        var turnCount = 0
        while !engine.isFinished && turnCount < 200 {
            let currentPlayer = engine.currentPlayerId
            let targetBoard = engine.gameState.opponentBoard(for: currentPlayer)!

            if let target = targetBoard.validTargets.randomElement() {
                _ = engine.executeAttack(at: target, by: currentPlayer)
            }
            turnCount += 1
        }

        XCTAssertTrue(engine.isFinished)
        XCTAssertNotNil(engine.winnerId)
    }

    func testCompleteGameAgainstProbabilityAI() {
        let human = Profile(name: "Test Player")
        let ai = Profile.aiPlayer(name: "Admiral AI")

        let aiPlayer = ProbabilityAI()
        let engine = GameEngine(
            player1: human,
            player2: ai,
            turnDuration: 20.0,
            aiPlayer: aiPlayer
        )

        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: human.id)
        }
        for ship in aiPlayer.generateShipPlacements() {
            _ = engine.placeShip(ship, for: ai.id)
        }

        _ = engine.startBattle()

        var turnCount = 0
        while !engine.isFinished && turnCount < 200 {
            let currentPlayer = engine.currentPlayerId
            let targetBoard = engine.gameState.opponentBoard(for: currentPlayer)!

            if let target = targetBoard.validTargets.randomElement() {
                _ = engine.executeAttack(at: target, by: currentPlayer)
            }
            turnCount += 1
        }

        XCTAssertTrue(engine.isFinished)
        XCTAssertNotNil(engine.winnerId)
    }

    // MARK: - Setup Phase Tests

    func testSetupPhaseValidation() {
        let human = Profile(name: "Test Player")
        let ai = Profile.aiPlayer(name: "AI")

        let engine = GameEngine(
            player1: human,
            player2: ai,
            turnDuration: 20.0,
            aiPlayer: nil
        )

        // Cannot start battle without ships
        XCTAssertFalse(engine.canStartBattle)

        // Place human ships only
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: human.id)
        }

        // Still cannot start (AI has no ships)
        XCTAssertFalse(engine.canStartBattle)

        // Place AI ships
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: ai.id)
        }

        // Now can start
        XCTAssertTrue(engine.canStartBattle)
    }

    func testShipRemovalDuringSetup() {
        let human = Profile(name: "Test Player")
        let ai = Profile.aiPlayer(name: "AI")

        let engine = GameEngine(
            player1: human,
            player2: ai,
            turnDuration: 20.0,
            aiPlayer: nil
        )

        // Place a ship
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        _ = engine.placeShip(ship, for: human.id)

        // Verify it's placed
        XCTAssertEqual(engine.gameState.player1Board.ships.count, 1)

        // Remove it
        let removeResult = engine.removeShip(id: ship.id, for: human.id)
        XCTAssertNotNil(try? removeResult.get())

        // Verify it's removed
        XCTAssertEqual(engine.gameState.player1Board.ships.count, 0)
    }

    // MARK: - Battle Phase Tests

    func testTurnAlternation() {
        let human = Profile(name: "Test Player")
        let ai = Profile.aiPlayer(name: "AI")

        let engine = GameEngine(
            player1: human,
            player2: ai,
            turnDuration: 20.0,
            aiPlayer: nil
        )

        // Setup
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: human.id)
        }
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: ai.id)
        }
        _ = engine.startBattle()

        let firstPlayer = engine.currentPlayerId
        let targetBoard = engine.gameState.opponentBoard(for: firstPlayer)!

        // Execute attack
        if let target = targetBoard.validTargets.first {
            _ = engine.executeAttack(at: target, by: firstPlayer)
        }

        // Turn should switch
        XCTAssertNotEqual(engine.currentPlayerId, firstPlayer)
    }

    func testCannotAttackOnOpponentTurn() {
        let human = Profile(name: "Test Player")
        let ai = Profile.aiPlayer(name: "AI")

        let engine = GameEngine(
            player1: human,
            player2: ai,
            turnDuration: 20.0,
            aiPlayer: nil
        )

        // Setup
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: human.id)
        }
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: ai.id)
        }
        _ = engine.startBattle()

        // Get the non-current player
        let currentPlayer = engine.currentPlayerId
        let otherPlayer = currentPlayer == human.id ? ai.id : human.id

        // Try to attack as the wrong player
        let targetBoard = engine.gameState.opponentBoard(for: otherPlayer)!
        if let target = targetBoard.validTargets.first {
            let result = engine.executeAttack(at: target, by: otherPlayer)
            if case .failure(let error) = result {
                XCTAssertEqual(error, .notYourTurn)
            } else {
                XCTFail("Should not be able to attack on opponent's turn")
            }
        }
    }

    func testForfeit() {
        let human = Profile(name: "Test Player")
        let ai = Profile.aiPlayer(name: "AI")

        let engine = GameEngine(
            player1: human,
            player2: ai,
            turnDuration: 20.0,
            aiPlayer: nil
        )

        // Setup
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: human.id)
        }
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: ai.id)
        }
        _ = engine.startBattle()

        // Forfeit
        let result = engine.forfeit(playerId: human.id)
        XCTAssertNotNil(try? result.get())

        // Game should be finished
        XCTAssertTrue(engine.isFinished)

        // AI should be winner
        XCTAssertEqual(engine.winnerId, ai.id)
    }

    // MARK: - Move History Tests

    func testMoveHistoryRecordsAllMoves() {
        let human = Profile(name: "Test Player")
        let ai = Profile.aiPlayer(name: "AI")

        let engine = GameEngine(
            player1: human,
            player2: ai,
            turnDuration: 20.0,
            aiPlayer: nil
        )

        // Setup
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: human.id)
        }
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: ai.id)
        }
        _ = engine.startBattle()

        // Execute 10 attacks
        for _ in 0..<10 {
            let currentPlayer = engine.currentPlayerId
            let targetBoard = engine.gameState.opponentBoard(for: currentPlayer)!

            if let target = targetBoard.validTargets.first {
                _ = engine.executeAttack(at: target, by: currentPlayer)
            }

            if engine.isFinished { break }
        }

        // Verify history has moves
        XCTAssertGreaterThan(engine.gameState.moveHistory.count, 0)
    }

    // MARK: - AI Factory Tests

    func testAIFactoryCreatesDifferentDifficulties() {
        let ensign = AIFactory.create(difficulty: .ensign)
        let commander = AIFactory.create(difficulty: .commander)
        let admiral = AIFactory.create(difficulty: .admiral)

        XCTAssertEqual(ensign.difficulty, .ensign)
        XCTAssertEqual(commander.difficulty, .commander)
        XCTAssertEqual(admiral.difficulty, .admiral)

        XCTAssertTrue(ensign is RandomAI)
        XCTAssertTrue(commander is HuntTargetAI)
        XCTAssertTrue(admiral is ProbabilityAI)
    }

    // MARK: - Pun Generator Integration Tests

    func testPunGeneratorIntegration() {
        let generator = PunGenerator.shared

        // Test all categories
        let hitPun = generator.pun(for: .onHit)
        XCTAssertFalse(hitPun.isEmpty)

        let missPun = generator.pun(for: .onMiss)
        XCTAssertFalse(missPun.isEmpty)

        let sunkPun = generator.pun(for: .onSunk(.destroyer))
        XCTAssertFalse(sunkPun.isEmpty)

        let victoryPun = generator.pun(for: .onVictory)
        XCTAssertFalse(victoryPun.isEmpty)

        let defeatPun = generator.pun(for: .onDefeat)
        XCTAssertFalse(defeatPun.isEmpty)

        let startPun = generator.pun(for: .onGameStart)
        XCTAssertFalse(startPun.isEmpty)

        let timeoutPun = generator.pun(for: .onTimeout)
        XCTAssertFalse(timeoutPun.isEmpty)
    }

    // MARK: - Edge Case Tests

    func testAllShipsSunkEndsGame() {
        let human = Profile(name: "Test Player")
        let ai = Profile.aiPlayer(name: "AI")

        // Create engine
        let engine = GameEngine(
            player1: human,
            player2: ai,
            turnDuration: 20.0,
            aiPlayer: nil
        )

        // Place ships for human
        for ship in ShipPlacer.generateRandomPlacements() {
            _ = engine.placeShip(ship, for: human.id)
        }

        // Place single destroyer for AI (easy to sink)
        let aiShips = ShipPlacer.generateRandomPlacements()
        for ship in aiShips {
            _ = engine.placeShip(ship, for: ai.id)
        }

        _ = engine.startBattle()

        // Systematically attack all AI ship positions
        // (We can't access private ship positions, so we attack everything)
        var turnCount = 0
        while !engine.isFinished && turnCount < 200 {
            let currentPlayer = engine.currentPlayerId
            let targetBoard = engine.gameState.opponentBoard(for: currentPlayer)!

            if let target = targetBoard.validTargets.first {
                _ = engine.executeAttack(at: target, by: currentPlayer)
            }
            turnCount += 1
        }

        XCTAssertTrue(engine.isFinished)
    }
}
