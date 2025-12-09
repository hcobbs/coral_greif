//
//  CoordinateTests.swift
//  Coral Greif Tests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
@testable import CoralGreif

final class CoordinateTests: XCTestCase {

    // MARK: - Initialization Tests

    func testValidCoordinateCreation() {
        let coord = Coordinate(row: 0, column: 0)
        XCTAssertNotNil(coord)
        XCTAssertEqual(coord?.row, 0)
        XCTAssertEqual(coord?.column, 0)
    }

    func testValidCoordinateAtMaxBounds() {
        let coord = Coordinate(row: 9, column: 9)
        XCTAssertNotNil(coord)
        XCTAssertEqual(coord?.row, 9)
        XCTAssertEqual(coord?.column, 9)
    }

    func testInvalidCoordinateNegativeRow() {
        let coord = Coordinate(row: -1, column: 5)
        XCTAssertNil(coord)
    }

    func testInvalidCoordinateNegativeColumn() {
        let coord = Coordinate(row: 5, column: -1)
        XCTAssertNil(coord)
    }

    func testInvalidCoordinateRowTooLarge() {
        let coord = Coordinate(row: 10, column: 5)
        XCTAssertNil(coord)
    }

    func testInvalidCoordinateColumnTooLarge() {
        let coord = Coordinate(row: 5, column: 10)
        XCTAssertNil(coord)
    }

    func testUncheckedInitialization() {
        let coord = Coordinate(uncheckedRow: 5, column: 5)
        XCTAssertEqual(coord.row, 5)
        XCTAssertEqual(coord.column, 5)
    }

    // MARK: - Board Size Tests

    func testBoardSizeIsCorrect() {
        XCTAssertEqual(Coordinate.boardSize, 10)
    }

    func testValidRangeIsCorrect() {
        XCTAssertEqual(Coordinate.validRange, 0..<10)
    }

    // MARK: - Adjacent Coordinate Tests

    func testAdjacentUp() {
        let coord = Coordinate(row: 5, column: 5)!
        let adjacent = coord.adjacent(in: .up)
        XCTAssertNotNil(adjacent)
        XCTAssertEqual(adjacent?.row, 4)
        XCTAssertEqual(adjacent?.column, 5)
    }

    func testAdjacentDown() {
        let coord = Coordinate(row: 5, column: 5)!
        let adjacent = coord.adjacent(in: .down)
        XCTAssertNotNil(adjacent)
        XCTAssertEqual(adjacent?.row, 6)
        XCTAssertEqual(adjacent?.column, 5)
    }

    func testAdjacentLeft() {
        let coord = Coordinate(row: 5, column: 5)!
        let adjacent = coord.adjacent(in: .left)
        XCTAssertNotNil(adjacent)
        XCTAssertEqual(adjacent?.row, 5)
        XCTAssertEqual(adjacent?.column, 4)
    }

    func testAdjacentRight() {
        let coord = Coordinate(row: 5, column: 5)!
        let adjacent = coord.adjacent(in: .right)
        XCTAssertNotNil(adjacent)
        XCTAssertEqual(adjacent?.row, 5)
        XCTAssertEqual(adjacent?.column, 6)
    }

    func testAdjacentUpAtTopEdge() {
        let coord = Coordinate(row: 0, column: 5)!
        let adjacent = coord.adjacent(in: .up)
        XCTAssertNil(adjacent)
    }

    func testAdjacentDownAtBottomEdge() {
        let coord = Coordinate(row: 9, column: 5)!
        let adjacent = coord.adjacent(in: .down)
        XCTAssertNil(adjacent)
    }

    func testAdjacentLeftAtLeftEdge() {
        let coord = Coordinate(row: 5, column: 0)!
        let adjacent = coord.adjacent(in: .left)
        XCTAssertNil(adjacent)
    }

    func testAdjacentRightAtRightEdge() {
        let coord = Coordinate(row: 5, column: 9)!
        let adjacent = coord.adjacent(in: .right)
        XCTAssertNil(adjacent)
    }

    func testAllAdjacentMiddle() {
        let coord = Coordinate(row: 5, column: 5)!
        let adjacent = coord.allAdjacent()
        XCTAssertEqual(adjacent.count, 4)
    }

    func testAllAdjacentCorner() {
        let coord = Coordinate(row: 0, column: 0)!
        let adjacent = coord.allAdjacent()
        XCTAssertEqual(adjacent.count, 2)
    }

    func testAllAdjacentEdge() {
        let coord = Coordinate(row: 0, column: 5)!
        let adjacent = coord.allAdjacent()
        XCTAssertEqual(adjacent.count, 3)
    }

    // MARK: - Adjacency Check Tests

    func testIsAdjacentTrue() {
        let coord1 = Coordinate(row: 5, column: 5)!
        let coord2 = Coordinate(row: 5, column: 6)!
        XCTAssertTrue(coord1.isAdjacent(to: coord2))
    }

    func testIsAdjacentFalseDiagonal() {
        let coord1 = Coordinate(row: 5, column: 5)!
        let coord2 = Coordinate(row: 6, column: 6)!
        XCTAssertFalse(coord1.isAdjacent(to: coord2))
    }

    func testIsAdjacentFalseSame() {
        let coord1 = Coordinate(row: 5, column: 5)!
        let coord2 = Coordinate(row: 5, column: 5)!
        XCTAssertFalse(coord1.isAdjacent(to: coord2))
    }

    func testIsAdjacentFalseDistant() {
        let coord1 = Coordinate(row: 0, column: 0)!
        let coord2 = Coordinate(row: 9, column: 9)!
        XCTAssertFalse(coord1.isAdjacent(to: coord2))
    }

    // MARK: - Hashable Tests

    func testHashableEquality() {
        let coord1 = Coordinate(row: 3, column: 7)!
        let coord2 = Coordinate(row: 3, column: 7)!
        XCTAssertEqual(coord1, coord2)
        XCTAssertEqual(coord1.hashValue, coord2.hashValue)
    }

    func testHashableInSet() {
        let coord1 = Coordinate(row: 3, column: 7)!
        let coord2 = Coordinate(row: 3, column: 7)!
        var set = Set<Coordinate>()
        set.insert(coord1)
        set.insert(coord2)
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Description Tests

    func testDescriptionA1() {
        let coord = Coordinate(row: 0, column: 0)!
        XCTAssertEqual(coord.description, "A1")
    }

    func testDescriptionJ10() {
        let coord = Coordinate(row: 9, column: 9)!
        XCTAssertEqual(coord.description, "J10")
    }

    func testDescriptionE5() {
        let coord = Coordinate(row: 4, column: 4)!
        XCTAssertEqual(coord.description, "E5")
    }

    // MARK: - Codable Tests

    func testCodableRoundTrip() throws {
        let original = Coordinate(row: 3, column: 7)!
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Coordinate.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}

// MARK: - Direction Tests

final class DirectionTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(Direction.allCases.count, 4)
    }

    func testUpDeltas() {
        XCTAssertEqual(Direction.up.rowDelta, -1)
        XCTAssertEqual(Direction.up.columnDelta, 0)
    }

    func testDownDeltas() {
        XCTAssertEqual(Direction.down.rowDelta, 1)
        XCTAssertEqual(Direction.down.columnDelta, 0)
    }

    func testLeftDeltas() {
        XCTAssertEqual(Direction.left.rowDelta, 0)
        XCTAssertEqual(Direction.left.columnDelta, -1)
    }

    func testRightDeltas() {
        XCTAssertEqual(Direction.right.rowDelta, 0)
        XCTAssertEqual(Direction.right.columnDelta, 1)
    }

    func testOppositeUp() {
        XCTAssertEqual(Direction.up.opposite, .down)
    }

    func testOppositeDown() {
        XCTAssertEqual(Direction.down.opposite, .up)
    }

    func testOppositeLeft() {
        XCTAssertEqual(Direction.left.opposite, .right)
    }

    func testOppositeRight() {
        XCTAssertEqual(Direction.right.opposite, .left)
    }
}

// MARK: - Orientation Tests

final class OrientationTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(Orientation.allCases.count, 2)
    }

    func testHorizontalDirection() {
        XCTAssertEqual(Orientation.horizontal.direction, .right)
    }

    func testVerticalDirection() {
        XCTAssertEqual(Orientation.vertical.direction, .down)
    }

    func testCodableRoundTrip() throws {
        let original = Orientation.horizontal
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Orientation.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
