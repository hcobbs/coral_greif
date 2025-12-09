//
//  BoardTests.swift
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

final class BoardTests: XCTestCase {

    // MARK: - Initialization Tests

    func testBoardInitialization() {
        let board = Board()

        XCTAssertEqual(board.grid.count, 10)
        for row in board.grid {
            XCTAssertEqual(row.count, 10)
        }
        XCTAssertTrue(board.ships.isEmpty)
    }

    func testAllCellsInitializedCorrectly() {
        let board = Board()

        for row in 0..<10 {
            for column in 0..<10 {
                let coord = Coordinate(row: row, column: column)!
                let cell = board.cell(at: coord)
                XCTAssertEqual(cell.coordinate, coord)
                XCTAssertEqual(cell.state, .empty)
            }
        }
    }

    // MARK: - Cell Access Tests

    func testCellAccess() {
        let board = Board()
        let coord = Coordinate(row: 5, column: 5)!
        let cell = board.cell(at: coord)

        XCTAssertEqual(cell.coordinate, coord)
    }

    // MARK: - Ship Placement Tests

    func testPlaceShipSuccess() {
        var board = Board()
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)

        let result = board.placeShip(ship)

        assertSuccess(result)
        XCTAssertEqual(board.ships.count, 1)
        XCTAssertEqual(board.cell(at: origin).state, .ship)
        XCTAssertEqual(board.cell(at: Coordinate(row: 0, column: 1)!).state, .ship)
    }

    func testPlaceShipOutOfBounds() {
        var board = Board()
        let origin = Coordinate(row: 0, column: 9)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)

        let result = board.placeShip(ship)

        assertFailure(result, expectedError: .shipOutOfBounds)
        XCTAssertTrue(board.ships.isEmpty)
    }

    func testPlaceShipOverlap() {
        var board = Board()
        let origin1 = Coordinate(row: 0, column: 0)!
        let ship1 = Ship(type: .cruiser, origin: origin1, orientation: .horizontal)

        let origin2 = Coordinate(row: 0, column: 2)!
        let ship2 = Ship(type: .cruiser, origin: origin2, orientation: .vertical)

        _ = board.placeShip(ship1)
        let result = board.placeShip(ship2)

        assertFailure(result, expectedError: .shipOverlap)
        XCTAssertEqual(board.ships.count, 1)
    }

    func testPlaceMultipleShipsNoOverlap() {
        var board = Board()
        let ship1 = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        let ship2 = Ship(type: .cruiser, origin: Coordinate(row: 2, column: 0)!, orientation: .horizontal)

        _ = board.placeShip(ship1)
        let result = board.placeShip(ship2)

        assertSuccess(result)
        XCTAssertEqual(board.ships.count, 2)
    }

    func testPlaceAllStandardFleet() {
        var board = Board()

        let carrier = Ship(type: .carrier, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        let battleship = Ship(type: .battleship, origin: Coordinate(row: 1, column: 0)!, orientation: .horizontal)
        let cruiser = Ship(type: .cruiser, origin: Coordinate(row: 2, column: 0)!, orientation: .horizontal)
        let submarine = Ship(type: .submarine, origin: Coordinate(row: 3, column: 0)!, orientation: .horizontal)
        let destroyer = Ship(type: .destroyer, origin: Coordinate(row: 4, column: 0)!, orientation: .horizontal)

        assertSuccess(board.placeShip(carrier))
        assertSuccess(board.placeShip(battleship))
        assertSuccess(board.placeShip(cruiser))
        assertSuccess(board.placeShip(submarine))
        assertSuccess(board.placeShip(destroyer))

        XCTAssertTrue(board.isFleetComplete)
    }

    // MARK: - Ship Removal Tests

    func testRemoveShipSuccess() {
        var board = Board()
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        _ = board.placeShip(ship)

        let result = board.removeShip(id: ship.id)

        if case .success(let removedShip) = result {
            XCTAssertEqual(removedShip.id, ship.id)
        } else {
            XCTFail("Expected success")
        }
        XCTAssertTrue(board.ships.isEmpty)
        XCTAssertEqual(board.cell(at: origin).state, .empty)
    }

    func testRemoveShipNotFound() {
        var board = Board()
        let result = board.removeShip(id: UUID())

        if case .failure(let error) = result {
            XCTAssertEqual(error, .shipNotFound)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testClearAllShips() {
        var board = Board()
        let ship1 = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        let ship2 = Ship(type: .cruiser, origin: Coordinate(row: 2, column: 0)!, orientation: .horizontal)
        _ = board.placeShip(ship1)
        _ = board.placeShip(ship2)

        board.clearAllShips()

        XCTAssertTrue(board.ships.isEmpty)
        XCTAssertEqual(board.cell(at: Coordinate(row: 0, column: 0)!).state, .empty)
        XCTAssertEqual(board.cell(at: Coordinate(row: 2, column: 0)!).state, .empty)
    }

    // MARK: - Attack Tests

    func testAttackMiss() {
        var board = Board()
        let coord = Coordinate(row: 5, column: 5)!

        let result = board.receiveAttack(at: coord)

        XCTAssertEqual(try? result.get(), .miss)
        XCTAssertEqual(board.cell(at: coord).state, .miss)
    }

    func testAttackHit() {
        var board = Board()
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .cruiser, origin: origin, orientation: .horizontal)
        _ = board.placeShip(ship)

        let result = board.receiveAttack(at: origin)

        XCTAssertEqual(try? result.get(), .hit)
        XCTAssertEqual(board.cell(at: origin).state, .hit)
    }

    func testAttackSunk() {
        var board = Board()
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        _ = board.placeShip(ship)

        _ = board.receiveAttack(at: Coordinate(row: 0, column: 0)!)
        let result = board.receiveAttack(at: Coordinate(row: 0, column: 1)!)

        XCTAssertEqual(try? result.get(), .sunk(.destroyer))
    }

    func testAttackAlreadyAttacked() {
        var board = Board()
        let coord = Coordinate(row: 5, column: 5)!
        _ = board.receiveAttack(at: coord)

        let result = board.receiveAttack(at: coord)

        if case .failure(let error) = result {
            XCTAssertEqual(error, .alreadyAttacked)
        } else {
            XCTFail("Expected failure")
        }
    }

    // MARK: - Query Tests

    func testAllShipsSunkFalseWithNoShips() {
        let board = Board()
        XCTAssertFalse(board.allShipsSunk)
    }

    func testAllShipsSunkFalseWithActiveShips() {
        var board = Board()
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        _ = board.placeShip(ship)

        XCTAssertFalse(board.allShipsSunk)
    }

    func testAllShipsSunkTrue() {
        var board = Board()
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        _ = board.placeShip(ship)
        _ = board.receiveAttack(at: Coordinate(row: 0, column: 0)!)
        _ = board.receiveAttack(at: Coordinate(row: 0, column: 1)!)

        XCTAssertTrue(board.allShipsSunk)
    }

    func testShipsRemaining() {
        var board = Board()
        let ship1 = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        let ship2 = Ship(type: .cruiser, origin: Coordinate(row: 2, column: 0)!, orientation: .horizontal)
        _ = board.placeShip(ship1)
        _ = board.placeShip(ship2)

        XCTAssertEqual(board.shipsRemaining, 2)

        // Sink destroyer
        _ = board.receiveAttack(at: Coordinate(row: 0, column: 0)!)
        _ = board.receiveAttack(at: Coordinate(row: 0, column: 1)!)

        XCTAssertEqual(board.shipsRemaining, 1)
    }

    func testShipsSunk() {
        var board = Board()
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        _ = board.placeShip(ship)

        XCTAssertEqual(board.shipsSunk, 0)

        _ = board.receiveAttack(at: Coordinate(row: 0, column: 0)!)
        _ = board.receiveAttack(at: Coordinate(row: 0, column: 1)!)

        XCTAssertEqual(board.shipsSunk, 1)
    }

    func testTotalHits() {
        var board = Board()
        let ship = Ship(type: .cruiser, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        _ = board.placeShip(ship)

        XCTAssertEqual(board.totalHits, 0)

        _ = board.receiveAttack(at: Coordinate(row: 0, column: 0)!)
        XCTAssertEqual(board.totalHits, 1)

        _ = board.receiveAttack(at: Coordinate(row: 0, column: 1)!)
        XCTAssertEqual(board.totalHits, 2)
    }

    func testTotalMisses() {
        var board = Board()

        XCTAssertEqual(board.totalMisses, 0)

        _ = board.receiveAttack(at: Coordinate(row: 5, column: 5)!)
        XCTAssertEqual(board.totalMisses, 1)

        _ = board.receiveAttack(at: Coordinate(row: 6, column: 6)!)
        XCTAssertEqual(board.totalMisses, 2)
    }

    func testValidTargets() {
        var board = Board()
        let initialTargets = board.validTargets

        XCTAssertEqual(initialTargets.count, 100)

        _ = board.receiveAttack(at: Coordinate(row: 0, column: 0)!)
        XCTAssertEqual(board.validTargets.count, 99)
    }

    func testIsFleetCompleteFalse() {
        var board = Board()
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        _ = board.placeShip(ship)

        XCTAssertFalse(board.isFleetComplete)
    }

    func testShipAtCoordinate() {
        var board = Board()
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        _ = board.placeShip(ship)

        let foundShip = board.ship(at: origin)
        XCTAssertNotNil(foundShip)
        XCTAssertEqual(foundShip?.id, ship.id)

        let noShip = board.ship(at: Coordinate(row: 5, column: 5)!)
        XCTAssertNil(noShip)
    }

    func testShipWithId() {
        var board = Board()
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        _ = board.placeShip(ship)

        let foundShip = board.ship(withId: ship.id)
        XCTAssertNotNil(foundShip)
        XCTAssertEqual(foundShip?.type, .destroyer)

        let noShip = board.ship(withId: UUID())
        XCTAssertNil(noShip)
    }

    // MARK: - Equatable Tests

    func testBoardEquality() {
        let board1 = Board()
        let board2 = Board()

        XCTAssertEqual(board1, board2)
    }

    func testBoardInequalityAfterPlacement() {
        var board1 = Board()
        let board2 = Board()
        let ship = Ship(type: .destroyer, origin: Coordinate(row: 0, column: 0)!, orientation: .horizontal)
        _ = board1.placeShip(ship)

        XCTAssertNotEqual(board1, board2)
    }
}

// MARK: - BoardError Tests

final class BoardErrorTests: XCTestCase {

    func testBoardErrorEquality() {
        XCTAssertEqual(BoardError.shipOutOfBounds, BoardError.shipOutOfBounds)
        XCTAssertEqual(BoardError.shipOverlap, BoardError.shipOverlap)
        XCTAssertEqual(BoardError.cellOccupied, BoardError.cellOccupied)
        XCTAssertEqual(BoardError.alreadyAttacked, BoardError.alreadyAttacked)
        XCTAssertEqual(BoardError.shipNotFound, BoardError.shipNotFound)
        XCTAssertEqual(BoardError.invalidAttack, BoardError.invalidAttack)
    }

    func testBoardErrorInequality() {
        XCTAssertNotEqual(BoardError.shipOutOfBounds, BoardError.shipOverlap)
    }

    func testBoardErrorIsError() {
        let error: Error = BoardError.shipOutOfBounds
        XCTAssertNotNil(error)
    }
}

// MARK: - AttackResult Tests

final class AttackResultTests: XCTestCase {

    func testAttackResultEquality() {
        XCTAssertEqual(AttackResult.miss, AttackResult.miss)
        XCTAssertEqual(AttackResult.hit, AttackResult.hit)
        XCTAssertEqual(AttackResult.sunk(.destroyer), AttackResult.sunk(.destroyer))
    }

    func testAttackResultInequality() {
        XCTAssertNotEqual(AttackResult.miss, AttackResult.hit)
        XCTAssertNotEqual(AttackResult.sunk(.destroyer), AttackResult.sunk(.carrier))
    }
}
