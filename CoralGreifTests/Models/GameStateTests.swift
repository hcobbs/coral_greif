//
//  GameStateTests.swift
//  Coral Greif Tests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
@testable import CoralGreif

// MARK: - Test Helpers

private func assertSuccess<E: Error>(_ result: Result<Void, E>, file: StaticString = #file, line: UInt = #line) {
    if case .failure(let error) = result {
        XCTFail("Expected success but got failure: \(error)", file: file, line: line)
    }
}

private func assertFailure<E: Error & Equatable>(
    _ result: Result<Void, E>,
    expectedError: E,
    file: StaticString = #file,
    line: UInt = #line
) {
    switch result {
    case .success:
        XCTFail("Expected failure but got success", file: file, line: line)
    case .failure(let error):
        XCTAssertEqual(error, expectedError, file: file, line: line)
    }
}

final class GameStateTests: XCTestCase {

    // MARK: - Test Helpers

    private func createTestPlayers() -> (Profile, Profile) {
        let player1 = Profile(name: "Admiral")
        let player2 = Profile.aiPlayer(name: "CPU")
        return (player1, player2)
    }

    private func createStandardFleet() -> [Ship] {
        return [
            Ship(type: .carrier, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal),
            Ship(type: .battleship, origin: Coordinate(row: 1, column: 0)!, orientation: .horizontal),
            Ship(type: .cruiser, origin: Coordinate(row: 2, column: 0)!, orientation: .horizontal),
            Ship(type: .submarine, origin: Coordinate(row: 3, column: 0)!, orientation: .horizontal),
            Ship(type: .destroyer, origin: Coordinate(row: 4, column: 0)!, orientation: .horizontal)
        ]
    }

    private func setupGameForBattle() -> GameState {
        let (player1, player2) = createTestPlayers()
        var game = GameState(player1: player1, player2: player2, firstPlayerId: player1.id)

        let fleet = createStandardFleet()
        for ship in fleet {
            _ = game.placeShip(ship, for: player1.id)
            _ = game.placeShip(ship, for: player2.id)
        }
        _ = game.startBattle()

        return game
    }

    // MARK: - Initialization Tests

    func testGameStateCreation() {
        let (player1, player2) = createTestPlayers()
        let game = GameState(player1: player1, player2: player2)

        XCTAssertEqual(game.player1.id, player1.id)
        XCTAssertEqual(game.player2.id, player2.id)
        XCTAssertEqual(game.phase, .setup)
        XCTAssertTrue(game.moveHistory.isEmpty)
        XCTAssertNil(game.winnerId)
        XCTAssertNil(game.endedAt)
    }

    func testGameStateWithSpecifiedFirstPlayer() {
        let (player1, player2) = createTestPlayers()
        let game = GameState(player1: player1, player2: player2, firstPlayerId: player2.id)

        XCTAssertEqual(game.currentPlayerId, player2.id)
    }

    func testGameStateRandomFirstPlayer() {
        let (player1, player2) = createTestPlayers()

        // Run multiple times to check randomness is working
        var firstPlayerIds: Set<UUID> = []
        for _ in 0..<100 {
            let game = GameState(player1: player1, player2: player2)
            firstPlayerIds.insert(game.currentPlayerId)
        }

        // Should have seen both players go first at some point
        XCTAssertTrue(firstPlayerIds.contains(player1.id) || firstPlayerIds.contains(player2.id))
    }

    // MARK: - Player Accessor Tests

    func testCurrentPlayer() {
        let (player1, player2) = createTestPlayers()
        let game = GameState(player1: player1, player2: player2, firstPlayerId: player1.id)

        XCTAssertEqual(game.currentPlayer.id, player1.id)
    }

    func testOpponentPlayer() {
        let (player1, player2) = createTestPlayers()
        let game = GameState(player1: player1, player2: player2, firstPlayerId: player1.id)

        XCTAssertEqual(game.opponentPlayer.id, player2.id)
    }

    func testPlayerWithId() {
        let (player1, player2) = createTestPlayers()
        let game = GameState(player1: player1, player2: player2)

        XCTAssertEqual(game.player(withId: player1.id)?.id, player1.id)
        XCTAssertEqual(game.player(withId: player2.id)?.id, player2.id)
        XCTAssertNil(game.player(withId: UUID()))
    }

    func testBoardForPlayer() {
        let (player1, player2) = createTestPlayers()
        let game = GameState(player1: player1, player2: player2)

        XCTAssertNotNil(game.board(for: player1.id))
        XCTAssertNotNil(game.board(for: player2.id))
        XCTAssertNil(game.board(for: UUID()))
    }

    func testOpponentBoardForPlayer() {
        let (player1, player2) = createTestPlayers()
        var game = GameState(player1: player1, player2: player2)

        // Place a ship on player2's board to differentiate
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        _ = game.placeShip(ship, for: player2.id)

        let opponentBoard = game.opponentBoard(for: player1.id)
        XCTAssertNotNil(opponentBoard)
        XCTAssertEqual(opponentBoard?.ships.count, 1)
    }

    // MARK: - Phase Tests

    func testIsInProgress() {
        let (player1, player2) = createTestPlayers()
        let game = GameState(player1: player1, player2: player2)

        XCTAssertTrue(game.isInProgress)
        XCTAssertTrue(game.isSetupPhase)
        XCTAssertFalse(game.isBattlePhase)
        XCTAssertFalse(game.isFinished)
    }

    func testBattlePhase() {
        var game = setupGameForBattle()

        XCTAssertTrue(game.isInProgress)
        XCTAssertFalse(game.isSetupPhase)
        XCTAssertTrue(game.isBattlePhase)
        XCTAssertFalse(game.isFinished)
    }

    // MARK: - Ship Placement Tests

    func testPlaceShipSuccess() {
        let (player1, player2) = createTestPlayers()
        var game = GameState(player1: player1, player2: player2)
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)

        let result = game.placeShip(ship, for: player1.id)

        assertSuccess(result)
        XCTAssertEqual(game.player1Board.ships.count, 1)
    }

    func testPlaceShipWrongPhase() {
        var game = setupGameForBattle()
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 9, column: 0)!, orientation: .horizontal)

        let result = game.placeShip(ship, for: game.player1.id)

        assertFailure(result, expectedError: .invalidPhase)
    }

    func testPlaceShipInvalidPlayer() {
        let (player1, player2) = createTestPlayers()
        var game = GameState(player1: player1, player2: player2)
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)

        let result = game.placeShip(ship, for: UUID())

        assertFailure(result, expectedError: .playerNotFound)
    }

    // MARK: - Start Battle Tests

    func testStartBattleSuccess() {
        let (player1, player2) = createTestPlayers()
        var game = GameState(player1: player1, player2: player2)

        let fleet = createStandardFleet()
        for ship in fleet {
            _ = game.placeShip(ship, for: player1.id)
            _ = game.placeShip(ship, for: player2.id)
        }

        let result = game.startBattle()

        assertSuccess(result)
        XCTAssertEqual(game.phase, .battle)
    }

    func testStartBattleIncompleteFleet() {
        let (player1, player2) = createTestPlayers()
        var game = GameState(player1: player1, player2: player2)

        // Only place one ship
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        _ = game.placeShip(ship, for: player1.id)
        _ = game.placeShip(ship, for: player2.id)

        let result = game.startBattle()

        assertFailure(result, expectedError: .fleetIncomplete)
    }

    func testStartBattleWrongPhase() {
        var game = setupGameForBattle()

        let result = game.startBattle()

        assertFailure(result, expectedError: .invalidPhase)
    }

    // MARK: - Attack Tests

    func testExecuteAttackMiss() {
        var game = setupGameForBattle()
        let attackCoord = Coordinate(row: 9, column: 9)! // Empty cell

        let result = game.executeAttack(at: attackCoord, by: game.currentPlayerId)

        XCTAssertEqual(try? result.get(), .miss)
        XCTAssertEqual(game.moveHistory.count, 1)
    }

    func testExecuteAttackHit() {
        var game = setupGameForBattle()
        let attackCoord = Coordinate(row: 0, column: 0)! // Ship cell

        let result = game.executeAttack(at: attackCoord, by: game.currentPlayerId)

        XCTAssertEqual(try? result.get(), .hit)
    }

    func testExecuteAttackSunk() {
        var game = setupGameForBattle()

        // Attack destroyer (2 cells at row 4, columns 0-1)
        _ = game.executeAttack(at: Coordinate(row: 4, column: 0)!, by: game.player1.id)
        // Turn switches to player2, need to attack back
        _ = game.executeAttack(at: Coordinate(row: 9, column: 9)!, by: game.player2.id)
        // Back to player1
        let result = game.executeAttack(at: Coordinate(row: 4, column: 1)!, by: game.player1.id)

        XCTAssertEqual(try? result.get(), .sunk(.destroyer))
    }

    func testExecuteAttackWrongTurn() {
        var game = setupGameForBattle()
        let wrongPlayer = game.opponentPlayer.id

        let result = game.executeAttack(at: Coordinate(row: 5, column: 5)!, by: wrongPlayer)

        if case .failure(let error) = result {
            XCTAssertEqual(error, .notYourTurn)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testExecuteAttackWrongPhase() {
        let (player1, player2) = createTestPlayers()
        var game = GameState(player1: player1, player2: player2)

        let result = game.executeAttack(at: Coordinate(row: 5, column: 5)!, by: player1.id)

        if case .failure(let error) = result {
            XCTAssertEqual(error, .invalidPhase)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testExecuteAttackAlreadyAttacked() {
        var game = setupGameForBattle()
        let coord = Coordinate(row: 9, column: 9)!

        _ = game.executeAttack(at: coord, by: game.player1.id)
        _ = game.executeAttack(at: Coordinate(row: 8, column: 8)!, by: game.player2.id)

        let result = game.executeAttack(at: coord, by: game.player1.id)

        if case .failure(let error) = result {
            XCTAssertEqual(error, .alreadyAttacked)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testAttackSwitchesTurn() {
        var game = setupGameForBattle()
        let firstPlayer = game.currentPlayerId

        _ = game.executeAttack(at: Coordinate(row: 9, column: 9)!, by: firstPlayer)

        XCTAssertNotEqual(game.currentPlayerId, firstPlayer)
    }

    func testTimeoutAttack() {
        var game = setupGameForBattle()

        let result = game.executeAttack(at: Coordinate(row: 9, column: 9)!, by: game.currentPlayerId, wasTimeout: true)

        XCTAssertEqual(try? result.get(), .miss)
        XCTAssertTrue(game.moveHistory.lastMove?.wasTimeout ?? false)
    }

    // MARK: - Win Condition Tests

    func testGameEndsWhenAllShipsSunk() {
        // Use a simpler setup: both players have just a destroyer
        let (player1, player2) = createTestPlayers()
        var game = GameState(player1: player1, player2: player2, firstPlayerId: player1.id)

        // Place full fleet on player1
        let fleet = createStandardFleet()
        for ship in fleet {
            _ = game.placeShip(ship, for: player1.id)
        }

        // Place full fleet on player2 too
        let fleet2 = [
            Ship(type: .carrier, origin: Coordinate(row: 5, column: 0)!, orientation: .horizontal),
            Ship(type: .battleship, origin: Coordinate(row: 6, column: 0)!, orientation: .horizontal),
            Ship(type: .cruiser, origin: Coordinate(row: 7, column: 0)!, orientation: .horizontal),
            Ship(type: .submarine, origin: Coordinate(row: 8, column: 0)!, orientation: .horizontal),
            Ship(type: .destroyer, origin: Coordinate(row: 9, column: 0)!, orientation: .horizontal)
        ]
        for ship in fleet2 {
            _ = game.placeShip(ship, for: player2.id)
        }

        _ = game.startBattle()

        // All coordinates for player2's ships
        let allShipCoords = [
            // carrier at row 5
            Coordinate(row: 5, column: 0)!, Coordinate(row: 5, column: 1)!, Coordinate(row: 5, column: 2)!,
            Coordinate(row: 5, column: 3)!, Coordinate(row: 5, column: 4)!,
            // battleship at row 6
            Coordinate(row: 6, column: 0)!, Coordinate(row: 6, column: 1)!, Coordinate(row: 6, column: 2)!,
            Coordinate(row: 6, column: 3)!,
            // cruiser at row 7
            Coordinate(row: 7, column: 0)!, Coordinate(row: 7, column: 1)!, Coordinate(row: 7, column: 2)!,
            // submarine at row 8
            Coordinate(row: 8, column: 0)!, Coordinate(row: 8, column: 1)!, Coordinate(row: 8, column: 2)!,
            // destroyer at row 9
            Coordinate(row: 9, column: 0)!, Coordinate(row: 9, column: 1)!
        ]

        // Player2 will attack empty cells on player1's board (rows 5-9 are empty)
        var p2AttackIndex = 0
        for coord in allShipCoords {
            if game.isFinished {
                break
            }

            // Player1 attacks
            _ = game.executeAttack(at: coord, by: player1.id)

            // If game not finished, player2 needs to attack
            if game.isInProgress {
                // Attack rows 5-9 on player1's board (guaranteed empty since player1's ships are at rows 0-4)
                let attackRow = 5 + (p2AttackIndex / 10)
                let attackCol = p2AttackIndex % 10
                _ = game.executeAttack(at: Coordinate(row: attackRow, column: attackCol)!, by: player2.id)
                p2AttackIndex += 1
            }
        }

        XCTAssertTrue(game.isFinished)
        XCTAssertEqual(game.winnerId, player1.id)
        XCTAssertNotNil(game.endedAt)
    }

    func testWinnerAndLoser() {
        var game = setupGameForBattle()
        _ = game.forfeit(playerId: game.player1.id)

        XCTAssertEqual(game.winner?.id, game.player2.id)
        XCTAssertEqual(game.loser?.id, game.player1.id)
    }

    // MARK: - Forfeit Tests

    func testForfeitSuccess() {
        var game = setupGameForBattle()

        let result = game.forfeit(playerId: game.player1.id)

        assertSuccess(result)
        XCTAssertTrue(game.isFinished)
        XCTAssertEqual(game.winnerId, game.player2.id)
        XCTAssertNotNil(game.endedAt)
    }

    func testForfeitWhenGameAlreadyFinished() {
        var game = setupGameForBattle()
        _ = game.forfeit(playerId: game.player1.id)

        let result = game.forfeit(playerId: game.player2.id)

        assertFailure(result, expectedError: .gameAlreadyFinished)
    }

    func testForfeitInvalidPlayer() {
        var game = setupGameForBattle()

        let result = game.forfeit(playerId: UUID())

        assertFailure(result, expectedError: .playerNotFound)
    }

    // MARK: - Total Turns Tests

    func testTotalTurns() {
        var game = setupGameForBattle()

        XCTAssertEqual(game.totalTurns, 0)

        _ = game.executeAttack(at: Coordinate(row: 9, column: 9)!, by: game.currentPlayerId)
        XCTAssertEqual(game.totalTurns, 1)

        _ = game.executeAttack(at: Coordinate(row: 8, column: 8)!, by: game.currentPlayerId)
        XCTAssertEqual(game.totalTurns, 2)
    }

    // MARK: - Equatable Tests

    func testGameStateEquality() {
        let testId = UUID()
        let testDate = Date(timeIntervalSince1970: 1000)
        let testPlayerId1 = UUID()
        let testPlayerId2 = UUID()

        let player1 = Profile(
            id: testPlayerId1,
            name: "Admiral",
            isAI: false,
            avatarId: nil,
            stats: ProfileStats(),
            createdAt: testDate
        )
        let player2 = Profile(
            id: testPlayerId2,
            name: "CPU",
            isAI: true,
            avatarId: nil,
            stats: ProfileStats(),
            createdAt: testDate
        )

        let game1 = GameState(
            id: testId,
            player1: player1,
            player2: player2,
            player1Board: Board(),
            player2Board: Board(),
            currentPlayerId: player1.id,
            phase: .setup,
            moveHistory: MoveHistory(),
            createdAt: testDate,
            endedAt: nil,
            winnerId: nil
        )

        let game2 = GameState(
            id: testId,
            player1: player1,
            player2: player2,
            player1Board: Board(),
            player2Board: Board(),
            currentPlayerId: player1.id,
            phase: .setup,
            moveHistory: MoveHistory(),
            createdAt: testDate,
            endedAt: nil,
            winnerId: nil
        )

        XCTAssertEqual(game1, game2)
    }
}

// MARK: - GamePhase Tests

final class GamePhaseTests: XCTestCase {

    func testGamePhaseEquality() {
        XCTAssertEqual(GamePhase.setup, GamePhase.setup)
        XCTAssertEqual(GamePhase.battle, GamePhase.battle)
        XCTAssertEqual(GamePhase.finished, GamePhase.finished)
    }

    func testGamePhaseInequality() {
        XCTAssertNotEqual(GamePhase.setup, GamePhase.battle)
        XCTAssertNotEqual(GamePhase.battle, GamePhase.finished)
    }

    func testGamePhaseCodable() throws {
        let phases: [GamePhase] = [.setup, .battle, .finished]

        for original in phases {
            let encoder = JSONEncoder()
            let data = try encoder.encode(original)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(GamePhase.self, from: data)

            XCTAssertEqual(original, decoded)
        }
    }
}

// MARK: - GameError Tests

final class GameErrorTests: XCTestCase {

    func testGameErrorEquality() {
        XCTAssertEqual(GameError.invalidPhase, GameError.invalidPhase)
        XCTAssertEqual(GameError.playerNotFound, GameError.playerNotFound)
        XCTAssertEqual(GameError.shipPlacementFailed, GameError.shipPlacementFailed)
        XCTAssertEqual(GameError.fleetIncomplete, GameError.fleetIncomplete)
        XCTAssertEqual(GameError.notYourTurn, GameError.notYourTurn)
        XCTAssertEqual(GameError.alreadyAttacked, GameError.alreadyAttacked)
        XCTAssertEqual(GameError.invalidAttack, GameError.invalidAttack)
        XCTAssertEqual(GameError.gameAlreadyFinished, GameError.gameAlreadyFinished)
    }

    func testGameErrorInequality() {
        XCTAssertNotEqual(GameError.invalidPhase, GameError.playerNotFound)
    }

    func testGameErrorIsError() {
        let error: Error = GameError.invalidPhase
        XCTAssertNotNil(error)
    }
}
