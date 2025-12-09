//
//  MoveTests.swift
//  Coral Greif Tests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
@testable import CoralGreif

final class MoveTests: XCTestCase {

    // MARK: - Initialization Tests

    func testMoveCreation() {
        let playerId = UUID()
        let coord = Coordinate(row: 5, column: 5)!
        let move = Move(playerId: playerId, coordinate: coord, result: .hit)

        XCTAssertEqual(move.playerId, playerId)
        XCTAssertEqual(move.coordinate, coord)
        XCTAssertEqual(move.result, .hit)
        XCTAssertFalse(move.wasTimeout)
    }

    func testMoveCreationWithTimeout() {
        let playerId = UUID()
        let coord = Coordinate(row: 5, column: 5)!
        let move = Move(playerId: playerId, coordinate: coord, result: .miss, wasTimeout: true)

        XCTAssertTrue(move.wasTimeout)
    }

    func testMoveHasTimestamp() {
        let before = Date()
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .miss)
        let after = Date()

        XCTAssertGreaterThanOrEqual(move.timestamp, before)
        XCTAssertLessThanOrEqual(move.timestamp, after)
    }

    func testFullInitializer() {
        let testId = UUID()
        let playerId = UUID()
        let coord = Coordinate(row: 3, column: 7)!
        let testDate = Date(timeIntervalSince1970: 1000)

        let move = Move(
            id: testId,
            playerId: playerId,
            coordinate: coord,
            result: .sunk(.destroyer),
            timestamp: testDate,
            wasTimeout: true
        )

        XCTAssertEqual(move.id, testId)
        XCTAssertEqual(move.playerId, playerId)
        XCTAssertEqual(move.coordinate, coord)
        XCTAssertEqual(move.result, .sunk(.destroyer))
        XCTAssertEqual(move.timestamp, testDate)
        XCTAssertTrue(move.wasTimeout)
    }

    // MARK: - IsHit Tests

    func testIsHitForMiss() {
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .miss)
        XCTAssertFalse(move.isHit)
    }

    func testIsHitForHit() {
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .hit)
        XCTAssertTrue(move.isHit)
    }

    func testIsHitForSunk() {
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .sunk(.destroyer))
        XCTAssertTrue(move.isHit)
    }

    // MARK: - DidSink Tests

    func testDidSinkForMiss() {
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .miss)
        XCTAssertFalse(move.didSink)
    }

    func testDidSinkForHit() {
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .hit)
        XCTAssertFalse(move.didSink)
    }

    func testDidSinkForSunk() {
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .sunk(.carrier))
        XCTAssertTrue(move.didSink)
    }

    // MARK: - SunkShipType Tests

    func testSunkShipTypeForMiss() {
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .miss)
        XCTAssertNil(move.sunkShipType)
    }

    func testSunkShipTypeForHit() {
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .hit)
        XCTAssertNil(move.sunkShipType)
    }

    func testSunkShipTypeForSunk() {
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .sunk(.battleship))
        XCTAssertEqual(move.sunkShipType, .battleship)
    }

    // MARK: - Equatable Tests

    func testMoveEqualityById() {
        let testId = UUID()
        let playerId = UUID()
        let coord = Coordinate(row: 0, column: 0)!
        let testDate = Date(timeIntervalSince1970: 1000)

        let move1 = Move(
            id: testId,
            playerId: playerId,
            coordinate: coord,
            result: .miss,
            timestamp: testDate,
            wasTimeout: false
        )
        let move2 = Move(
            id: testId,
            playerId: playerId,
            coordinate: coord,
            result: .miss,
            timestamp: testDate,
            wasTimeout: false
        )

        XCTAssertEqual(move1, move2)
    }

    // MARK: - Codable Tests

    func testCodableRoundTripMiss() throws {
        let original = Move(playerId: UUID(), coordinate: Coordinate(row: 3, column: 7)!, result: .miss)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Move.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.result, decoded.result)
    }

    func testCodableRoundTripHit() throws {
        let original = Move(playerId: UUID(), coordinate: Coordinate(row: 3, column: 7)!, result: .hit)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Move.self, from: data)

        XCTAssertEqual(original.result, decoded.result)
    }

    func testCodableRoundTripSunk() throws {
        let original = Move(playerId: UUID(), coordinate: Coordinate(row: 3, column: 7)!, result: .sunk(.cruiser))

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Move.self, from: data)

        XCTAssertEqual(original.result, decoded.result)
        XCTAssertEqual(decoded.sunkShipType, .cruiser)
    }
}

// MARK: - MoveHistory Tests

final class MoveHistoryTests: XCTestCase {

    // MARK: - Initialization Tests

    func testEmptyHistoryInitialization() {
        let history = MoveHistory()

        XCTAssertTrue(history.isEmpty)
        XCTAssertEqual(history.count, 0)
        XCTAssertNil(history.lastMove)
    }

    func testHistoryInitializationWithMoves() {
        let move1 = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .miss)
        let move2 = Move(playerId: UUID(), coordinate: Coordinate(row: 1, column: 1)!, result: .hit)

        let history = MoveHistory(moves: [move1, move2])

        XCTAssertEqual(history.count, 2)
        XCTAssertFalse(history.isEmpty)
    }

    // MARK: - Add Move Tests

    func testAddMove() {
        var history = MoveHistory()
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .miss)

        history.add(move)

        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.lastMove?.id, move.id)
    }

    func testAddMultipleMoves() {
        var history = MoveHistory()
        let move1 = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .miss)
        let move2 = Move(playerId: UUID(), coordinate: Coordinate(row: 1, column: 1)!, result: .hit)

        history.add(move1)
        history.add(move2)

        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history.lastMove?.id, move2.id)
    }

    // MARK: - Player Filtering Tests

    func testMovesByPlayer() {
        let player1 = UUID()
        let player2 = UUID()

        var history = MoveHistory()
        history.add(Move(playerId: player1, coordinate: Coordinate(row: 0, column: 0)!, result: .miss))
        history.add(Move(playerId: player2, coordinate: Coordinate(row: 1, column: 1)!, result: .hit))
        history.add(Move(playerId: player1, coordinate: Coordinate(row: 2, column: 2)!, result: .hit))

        let player1Moves = history.moves(by: player1)
        XCTAssertEqual(player1Moves.count, 2)

        let player2Moves = history.moves(by: player2)
        XCTAssertEqual(player2Moves.count, 1)
    }

    func testHitsByPlayer() {
        let playerId = UUID()

        var history = MoveHistory()
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 0, column: 0)!, result: .miss))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 1, column: 1)!, result: .hit))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 2, column: 2)!, result: .sunk(.destroyer)))

        XCTAssertEqual(history.hits(by: playerId), 2)
    }

    func testMissesByPlayer() {
        let playerId = UUID()

        var history = MoveHistory()
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 0, column: 0)!, result: .miss))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 1, column: 1)!, result: .miss))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 2, column: 2)!, result: .hit))

        XCTAssertEqual(history.misses(by: playerId), 2)
    }

    func testShipsSunkByPlayer() {
        let playerId = UUID()

        var history = MoveHistory()
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 0, column: 0)!, result: .hit))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 1, column: 1)!, result: .sunk(.destroyer)))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 2, column: 2)!, result: .sunk(.cruiser)))

        XCTAssertEqual(history.shipsSunk(by: playerId), 2)
    }

    // MARK: - Consecutive Misses Tests

    func testConsecutiveMissesNone() {
        let playerId = UUID()

        var history = MoveHistory()
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 0, column: 0)!, result: .hit))

        XCTAssertEqual(history.consecutiveMisses(by: playerId), 0)
    }

    func testConsecutiveMissesThree() {
        let playerId = UUID()

        var history = MoveHistory()
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 0, column: 0)!, result: .hit))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 1, column: 1)!, result: .miss))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 2, column: 2)!, result: .miss))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 3, column: 3)!, result: .miss))

        XCTAssertEqual(history.consecutiveMisses(by: playerId), 3)
    }

    func testConsecutiveMissesResetAfterHit() {
        let playerId = UUID()

        var history = MoveHistory()
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 0, column: 0)!, result: .miss))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 1, column: 1)!, result: .miss))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 2, column: 2)!, result: .hit))
        history.add(Move(playerId: playerId, coordinate: Coordinate(row: 3, column: 3)!, result: .miss))

        XCTAssertEqual(history.consecutiveMisses(by: playerId), 1)
    }

    func testConsecutiveMissesOnlyCountsPlayerMoves() {
        let player1 = UUID()
        let player2 = UUID()

        var history = MoveHistory()
        history.add(Move(playerId: player1, coordinate: Coordinate(row: 0, column: 0)!, result: .miss))
        history.add(Move(playerId: player2, coordinate: Coordinate(row: 1, column: 1)!, result: .hit))
        history.add(Move(playerId: player1, coordinate: Coordinate(row: 2, column: 2)!, result: .miss))

        XCTAssertEqual(history.consecutiveMisses(by: player1), 2)
    }

    // MARK: - Attacked Coordinates Tests

    func testAttackedCoordinates() {
        var history = MoveHistory()
        let coord1 = Coordinate(row: 0, column: 0)!
        let coord2 = Coordinate(row: 5, column: 5)!

        history.add(Move(playerId: UUID(), coordinate: coord1, result: .miss))
        history.add(Move(playerId: UUID(), coordinate: coord2, result: .hit))

        let attacked = history.attackedCoordinates
        XCTAssertEqual(attacked.count, 2)
        XCTAssertTrue(attacked.contains(coord1))
        XCTAssertTrue(attacked.contains(coord2))
    }

    func testAttackedCoordinatesEmpty() {
        let history = MoveHistory()
        XCTAssertTrue(history.attackedCoordinates.isEmpty)
    }

    // MARK: - Equatable Tests

    func testHistoryEquality() {
        let move = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .miss)

        let history1 = MoveHistory(moves: [move])
        let history2 = MoveHistory(moves: [move])

        XCTAssertEqual(history1, history2)
    }

    func testHistoryInequality() {
        let move1 = Move(playerId: UUID(), coordinate: Coordinate(row: 0, column: 0)!, result: .miss)
        let move2 = Move(playerId: UUID(), coordinate: Coordinate(row: 1, column: 1)!, result: .hit)

        let history1 = MoveHistory(moves: [move1])
        let history2 = MoveHistory(moves: [move2])

        XCTAssertNotEqual(history1, history2)
    }
}
