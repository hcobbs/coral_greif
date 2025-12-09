//
//  CellTests.swift
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

final class CellTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitialState() {
        let coord = Coordinate(row: 0, column: 0)!
        let cell = Cell(coordinate: coord)

        XCTAssertEqual(cell.coordinate, coord)
        XCTAssertNil(cell.shipId)
        XCTAssertFalse(cell.isAttacked)
        XCTAssertEqual(cell.state, .empty)
    }

    func testHasShipInitiallyFalse() {
        let coord = Coordinate(row: 0, column: 0)!
        let cell = Cell(coordinate: coord)
        XCTAssertFalse(cell.hasShip)
    }

    func testIsValidTargetInitiallyTrue() {
        let coord = Coordinate(row: 0, column: 0)!
        let cell = Cell(coordinate: coord)
        XCTAssertTrue(cell.isValidTarget)
    }

    // MARK: - Ship Placement Tests

    func testPlaceShipSuccess() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell = Cell(coordinate: coord)
        let shipId = UUID()

        let result = cell.placeShip(id: shipId)

        assertSuccess(result)
        XCTAssertEqual(cell.shipId, shipId)
        XCTAssertTrue(cell.hasShip)
        XCTAssertEqual(cell.state, .ship)
    }

    func testPlaceShipOnOccupiedCell() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell = Cell(coordinate: coord)
        let shipId1 = UUID()
        let shipId2 = UUID()

        _ = cell.placeShip(id: shipId1)
        let result = cell.placeShip(id: shipId2)

        assertFailure(result, expectedError: .alreadyOccupied)
        XCTAssertEqual(cell.shipId, shipId1)
    }

    func testRemoveShip() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell = Cell(coordinate: coord)
        let shipId = UUID()

        _ = cell.placeShip(id: shipId)
        cell.removeShip()

        XCTAssertNil(cell.shipId)
        XCTAssertFalse(cell.hasShip)
        XCTAssertEqual(cell.state, .empty)
    }

    // MARK: - Attack Tests

    func testAttackEmptyCell() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell = Cell(coordinate: coord)

        let result = cell.receiveAttack()

        XCTAssertEqual(try? result.get(), .miss)
        XCTAssertTrue(cell.isAttacked)
        XCTAssertEqual(cell.state, .miss)
        XCTAssertFalse(cell.isValidTarget)
    }

    func testAttackCellWithShip() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell = Cell(coordinate: coord)
        let shipId = UUID()
        _ = cell.placeShip(id: shipId)

        let result = cell.receiveAttack()

        XCTAssertEqual(try? result.get(), .hit)
        XCTAssertTrue(cell.isAttacked)
        XCTAssertEqual(cell.state, .hit)
        XCTAssertFalse(cell.isValidTarget)
    }

    func testAttackAlreadyAttackedCell() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell = Cell(coordinate: coord)
        _ = cell.receiveAttack()

        let result = cell.receiveAttack()

        if case .failure(let error) = result {
            XCTAssertEqual(error, .alreadyAttacked)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testAttackAlreadyHitCell() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell = Cell(coordinate: coord)
        _ = cell.placeShip(id: UUID())
        _ = cell.receiveAttack()

        let result = cell.receiveAttack()

        if case .failure(let error) = result {
            XCTAssertEqual(error, .alreadyAttacked)
        } else {
            XCTFail("Expected failure")
        }
    }

    // MARK: - State Tests

    func testStateEmpty() {
        let coord = Coordinate(row: 0, column: 0)!
        let cell = Cell(coordinate: coord)
        XCTAssertEqual(cell.state, .empty)
    }

    func testStateShip() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell = Cell(coordinate: coord)
        _ = cell.placeShip(id: UUID())
        XCTAssertEqual(cell.state, .ship)
    }

    func testStateMiss() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell = Cell(coordinate: coord)
        _ = cell.receiveAttack()
        XCTAssertEqual(cell.state, .miss)
    }

    func testStateHit() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell = Cell(coordinate: coord)
        _ = cell.placeShip(id: UUID())
        _ = cell.receiveAttack()
        XCTAssertEqual(cell.state, .hit)
    }

    // MARK: - Equatable Tests

    func testCellEquality() {
        let coord = Coordinate(row: 0, column: 0)!
        let cell1 = Cell(coordinate: coord)
        let cell2 = Cell(coordinate: coord)
        XCTAssertEqual(cell1, cell2)
    }

    func testCellInequalityDifferentCoordinate() {
        let coord1 = Coordinate(row: 0, column: 0)!
        let coord2 = Coordinate(row: 1, column: 1)!
        let cell1 = Cell(coordinate: coord1)
        let cell2 = Cell(coordinate: coord2)
        XCTAssertNotEqual(cell1, cell2)
    }

    func testCellInequalityDifferentShip() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell1 = Cell(coordinate: coord)
        let cell2 = Cell(coordinate: coord)
        _ = cell1.placeShip(id: UUID())
        XCTAssertNotEqual(cell1, cell2)
    }

    func testCellInequalityDifferentAttackState() {
        let coord = Coordinate(row: 0, column: 0)!
        var cell1 = Cell(coordinate: coord)
        let cell2 = Cell(coordinate: coord)
        _ = cell1.receiveAttack()
        XCTAssertNotEqual(cell1, cell2)
    }
}

// MARK: - CellState Tests

final class CellStateTests: XCTestCase {

    func testCellStateEquality() {
        XCTAssertEqual(CellState.empty, CellState.empty)
        XCTAssertEqual(CellState.ship, CellState.ship)
        XCTAssertEqual(CellState.hit, CellState.hit)
        XCTAssertEqual(CellState.miss, CellState.miss)
    }

    func testCellStateInequality() {
        XCTAssertNotEqual(CellState.empty, CellState.ship)
        XCTAssertNotEqual(CellState.hit, CellState.miss)
    }
}

// MARK: - AttackOutcome Tests

final class AttackOutcomeTests: XCTestCase {

    func testAttackOutcomeEquality() {
        XCTAssertEqual(AttackOutcome.hit, AttackOutcome.hit)
        XCTAssertEqual(AttackOutcome.miss, AttackOutcome.miss)
    }

    func testAttackOutcomeInequality() {
        XCTAssertNotEqual(AttackOutcome.hit, AttackOutcome.miss)
    }
}

// MARK: - CellError Tests

final class CellErrorTests: XCTestCase {

    func testCellErrorEquality() {
        XCTAssertEqual(CellError.alreadyOccupied, CellError.alreadyOccupied)
        XCTAssertEqual(CellError.alreadyAttacked, CellError.alreadyAttacked)
    }

    func testCellErrorInequality() {
        XCTAssertNotEqual(CellError.alreadyOccupied, CellError.alreadyAttacked)
    }

    func testCellErrorIsError() {
        let error: Error = CellError.alreadyOccupied
        XCTAssertNotNil(error)
    }
}
