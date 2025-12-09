//
//  GameEngineTests.swift
//  Coral Greif Tests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
@testable import CoralGreif

// MARK: - Mock Delegate

final class MockGameEngineDelegate: GameEngineDelegate {
    var turnBeganFor: [UUID] = []
    var turnEndedFor: [UUID] = []
    var attacks: [(result: AttackResult, coordinate: Coordinate, playerId: UUID)] = []
    var winner: UUID?
    var timerUpdates: [Int] = []
    var timeouts: [UUID] = []

    var attackExpectation: XCTestExpectation?
    var winExpectation: XCTestExpectation?

    func gameEngine(_ engine: GameEngine, turnDidBeginFor playerId: UUID) {
        turnBeganFor.append(playerId)
    }

    func gameEngine(_ engine: GameEngine, turnDidEndFor playerId: UUID) {
        turnEndedFor.append(playerId)
    }

    func gameEngine(_ engine: GameEngine, didExecuteAttack result: AttackResult, at coordinate: Coordinate, by playerId: UUID) {
        attacks.append((result, coordinate, playerId))
        attackExpectation?.fulfill()
    }

    func gameEngine(_ engine: GameEngine, gameDidEndWithWinner winnerId: UUID) {
        winner = winnerId
        winExpectation?.fulfill()
    }

    func gameEngine(_ engine: GameEngine, turnTimerDidUpdate remainingSeconds: Int) {
        timerUpdates.append(remainingSeconds)
    }

    func gameEngine(_ engine: GameEngine, turnDidTimeoutFor playerId: UUID) {
        timeouts.append(playerId)
    }
}

// MARK: - Test Helpers

private func createTestPlayers() -> (Profile, Profile) {
    let player1 = Profile(name: "Player 1")
    let player2 = Profile(name: "Player 2")
    return (player1, player2)
}

private func createStandardFleet(startRow: Int = 0) -> [Ship] {
    return [
        Ship(type: .carrier, origin: Coordinate(row: startRow, column: 0)!, orientation: .horizontal),
        Ship(type: .battleship, origin: Coordinate(row: startRow + 1, column: 0)!, orientation: .horizontal),
        Ship(type: .cruiser, origin: Coordinate(row: startRow + 2, column: 0)!, orientation: .horizontal),
        Ship(type: .submarine, origin: Coordinate(row: startRow + 3, column: 0)!, orientation: .horizontal),
        Ship(type: .destroyer, origin: Coordinate(row: startRow + 4, column: 0)!, orientation: .horizontal)
    ]
}

private func setupEngineForBattle() -> GameEngine {
    let (player1, player2) = createTestPlayers()
    let engine = GameEngine(player1: player1, player2: player2, turnDuration: 20)

    let fleet1 = createStandardFleet(startRow: 0)
    let fleet2 = createStandardFleet(startRow: 5)

    for ship in fleet1 {
        _ = engine.placeShip(ship, for: player1.id)
    }
    for ship in fleet2 {
        _ = engine.placeShip(ship, for: player2.id)
    }

    _ = engine.startBattle()
    return engine
}

// MARK: - Game Engine Tests

final class GameEngineTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitialization() {
        let (player1, player2) = createTestPlayers()
        let engine = GameEngine(player1: player1, player2: player2)

        XCTAssertEqual(engine.turnDuration, 20.0)
        XCTAssertFalse(engine.isStarted)
        XCTAssertFalse(engine.isFinished)
    }

    func testInitializationWithCustomDuration() {
        let (player1, player2) = createTestPlayers()
        let engine = GameEngine(player1: player1, player2: player2, turnDuration: 30)

        XCTAssertEqual(engine.turnDuration, 30.0)
    }

    func testInitializationWithExistingState() {
        let (player1, player2) = createTestPlayers()
        var state = GameState(player1: player1, player2: player2)

        // Place ships and start battle
        for ship in createStandardFleet(startRow: 0) {
            _ = state.placeShip(ship, for: player1.id)
        }
        for ship in createStandardFleet(startRow: 5) {
            _ = state.placeShip(ship, for: player2.id)
        }
        _ = state.startBattle()

        let engine = GameEngine(gameState: state)

        XCTAssertTrue(engine.isStarted)
    }

    // MARK: - Setup Phase Tests

    func testPlaceShipSuccess() {
        let (player1, player2) = createTestPlayers()
        let engine = GameEngine(player1: player1, player2: player2)

        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        let result = engine.placeShip(ship, for: player1.id)

        if case .failure = result {
            XCTFail("Expected success")
        }
    }

    func testPlaceShipAfterBattleStarted() {
        let engine = setupEngineForBattle()

        let ship = Ship(type: .destroyer, origin: Coordinate(row: 9, column: 9)!, orientation: .horizontal)
        let result = engine.placeShip(ship, for: engine.gameState.player1.id)

        if case .success = result {
            XCTFail("Expected failure")
        }
    }

    func testCanStartBattleFalseWithoutFleets() {
        let (player1, player2) = createTestPlayers()
        let engine = GameEngine(player1: player1, player2: player2)

        XCTAssertFalse(engine.canStartBattle)
    }

    func testCanStartBattleTrueWithFleets() {
        let (player1, player2) = createTestPlayers()
        let engine = GameEngine(player1: player1, player2: player2)

        for ship in createStandardFleet(startRow: 0) {
            _ = engine.placeShip(ship, for: player1.id)
        }
        for ship in createStandardFleet(startRow: 5) {
            _ = engine.placeShip(ship, for: player2.id)
        }

        XCTAssertTrue(engine.canStartBattle)
    }

    // MARK: - Battle Phase Tests

    func testStartBattleSuccess() {
        let (player1, player2) = createTestPlayers()
        let engine = GameEngine(player1: player1, player2: player2)

        for ship in createStandardFleet(startRow: 0) {
            _ = engine.placeShip(ship, for: player1.id)
        }
        for ship in createStandardFleet(startRow: 5) {
            _ = engine.placeShip(ship, for: player2.id)
        }

        let result = engine.startBattle()

        if case .failure = result {
            XCTFail("Expected success")
        }
        XCTAssertTrue(engine.isStarted)
    }

    func testStartBattleWithoutFleets() {
        let (player1, player2) = createTestPlayers()
        let engine = GameEngine(player1: player1, player2: player2)

        let result = engine.startBattle()

        if case .success = result {
            XCTFail("Expected failure")
        }
    }

    func testStartBattleTwice() {
        let engine = setupEngineForBattle()

        let result = engine.startBattle()

        if case .failure(let error) = result {
            XCTAssertEqual(error, .gameAlreadyStarted)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testStartBattleNotifiesDelegate() {
        let (player1, player2) = createTestPlayers()
        let engine = GameEngine(player1: player1, player2: player2)
        let delegate = MockGameEngineDelegate()
        engine.delegate = delegate

        for ship in createStandardFleet(startRow: 0) {
            _ = engine.placeShip(ship, for: player1.id)
        }
        for ship in createStandardFleet(startRow: 5) {
            _ = engine.placeShip(ship, for: player2.id)
        }

        _ = engine.startBattle()

        XCTAssertFalse(delegate.turnBeganFor.isEmpty)
    }

    // MARK: - Attack Tests

    func testExecuteAttackSuccess() {
        let engine = setupEngineForBattle()
        let currentPlayer = engine.currentPlayerId

        let result = engine.executeAttack(at: Coordinate(row: 9, column: 9)!, by: currentPlayer)

        if case .failure = result {
            XCTFail("Expected success")
        }
    }

    func testExecuteAttackBeforeBattle() {
        let (player1, player2) = createTestPlayers()
        let engine = GameEngine(player1: player1, player2: player2)

        let result = engine.executeAttack(at: Coordinate(row: 0, column: 0)!, by: player1.id)

        if case .failure(let error) = result {
            XCTAssertEqual(error, .gameNotStarted)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testExecuteAttackWrongTurn() {
        let engine = setupEngineForBattle()
        let wrongPlayer = engine.gameState.player1.id == engine.currentPlayerId
            ? engine.gameState.player2.id
            : engine.gameState.player1.id

        let result = engine.executeAttack(at: Coordinate(row: 0, column: 0)!, by: wrongPlayer)

        if case .failure(let error) = result {
            XCTAssertEqual(error, .notYourTurn)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testExecuteAttackNotifiesDelegate() {
        let engine = setupEngineForBattle()
        let delegate = MockGameEngineDelegate()
        engine.delegate = delegate
        let currentPlayer = engine.currentPlayerId

        _ = engine.executeAttack(at: Coordinate(row: 9, column: 9)!, by: currentPlayer)

        XCTAssertFalse(delegate.attacks.isEmpty)
    }

    // MARK: - Forfeit Tests

    func testForfeitSuccess() {
        let engine = setupEngineForBattle()
        let player1Id = engine.gameState.player1.id
        let player2Id = engine.gameState.player2.id

        let result = engine.forfeit(playerId: player1Id)

        if case .failure = result {
            XCTFail("Expected success")
        }
        XCTAssertTrue(engine.isFinished)
        XCTAssertEqual(engine.winnerId, player2Id)
    }

    func testForfeitBeforeBattle() {
        let (player1, player2) = createTestPlayers()
        let engine = GameEngine(player1: player1, player2: player2)

        let result = engine.forfeit(playerId: player1.id)

        if case .failure(let error) = result {
            XCTAssertEqual(error, .gameNotStarted)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testForfeitNotifiesDelegate() {
        let engine = setupEngineForBattle()
        let delegate = MockGameEngineDelegate()
        engine.delegate = delegate
        let player1Id = engine.gameState.player1.id

        _ = engine.forfeit(playerId: player1Id)

        XCTAssertNotNil(delegate.winner)
    }

    // MARK: - Turn Management Tests

    func testTurnSwitchesAfterAttack() {
        let engine = setupEngineForBattle()
        let firstPlayer = engine.currentPlayerId

        _ = engine.executeAttack(at: Coordinate(row: 9, column: 9)!, by: firstPlayer)

        XCTAssertNotEqual(engine.currentPlayerId, firstPlayer)
    }
}

// MARK: - Game Engine Error Tests

final class GameEngineErrorTests: XCTestCase {

    func testErrorEquality() {
        XCTAssertEqual(GameEngineError.gameNotStarted, GameEngineError.gameNotStarted)
        XCTAssertEqual(GameEngineError.notYourTurn, GameEngineError.notYourTurn)
        XCTAssertNotEqual(GameEngineError.gameNotStarted, GameEngineError.notYourTurn)
    }

    func testErrorIsError() {
        let error: Error = GameEngineError.invalidAttack
        XCTAssertNotNil(error)
    }
}
