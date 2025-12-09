//
//  Coordinate.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import Foundation

/// Represents a position on the game board.
/// Valid coordinates are 0-9 for both row and column (10x10 grid).
struct Coordinate: Hashable, Codable, Sendable {
    let row: Int
    let column: Int

    /// Board dimensions (classic Battleship is 10x10)
    static let boardSize = 10
    static let validRange = 0..<boardSize

    /// Creates a coordinate with validation.
    /// - Parameters:
    ///   - row: Row index (0-9)
    ///   - column: Column index (0-9)
    /// - Returns: A valid Coordinate or nil if out of bounds
    init?(row: Int, column: Int) {
        guard Self.validRange.contains(row),
              Self.validRange.contains(column) else {
            return nil
        }
        self.row = row
        self.column = column
    }

    /// Creates a coordinate without validation. Use only when bounds are guaranteed.
    /// - Parameters:
    ///   - row: Row index
    ///   - column: Column index
    init(uncheckedRow row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    /// Returns the coordinate adjacent in the given direction, if valid.
    func adjacent(in direction: Direction) -> Coordinate? {
        let newRow = row + direction.rowDelta
        let newColumn = column + direction.columnDelta
        return Coordinate(row: newRow, column: newColumn)
    }

    /// Returns all valid adjacent coordinates.
    func allAdjacent() -> [Coordinate] {
        return Direction.allCases.compactMap { adjacent(in: $0) }
    }

    /// Checks if this coordinate is adjacent to another.
    func isAdjacent(to other: Coordinate) -> Bool {
        let rowDiff = abs(row - other.row)
        let colDiff = abs(column - other.column)
        return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1)
    }
}

// MARK: - Direction

/// Cardinal directions for adjacent coordinate lookup.
enum Direction: CaseIterable, Sendable {
    case up
    case down
    case left
    case right

    var rowDelta: Int {
        switch self {
        case .up: return -1
        case .down: return 1
        case .left, .right: return 0
        }
    }

    var columnDelta: Int {
        switch self {
        case .left: return -1
        case .right: return 1
        case .up, .down: return 0
        }
    }

    /// Returns the opposite direction.
    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
}

// MARK: - Orientation

/// Ship placement orientation.
enum Orientation: CaseIterable, Codable, Sendable {
    case horizontal
    case vertical

    /// The direction of ship extension from origin.
    var direction: Direction {
        switch self {
        case .horizontal: return .right
        case .vertical: return .down
        }
    }
}

// MARK: - CustomStringConvertible

extension Coordinate: CustomStringConvertible {
    var description: String {
        let columnLetter = String(UnicodeScalar(65 + column)!)
        return "\(columnLetter)\(row + 1)"
    }
}
