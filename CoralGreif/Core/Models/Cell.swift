//
//  Cell.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import Foundation

/// Represents the state of a single cell on the game board.
struct Cell: Equatable, Sendable {
    /// The coordinate of this cell on the board.
    let coordinate: Coordinate

    /// Whether this cell contains part of a ship.
    private(set) var shipId: UUID?

    /// Whether this cell has been attacked.
    private(set) var isAttacked: Bool

    /// Creates a new cell at the given coordinate.
    /// - Parameter coordinate: The cell's position on the board
    init(coordinate: Coordinate) {
        self.coordinate = coordinate
        self.shipId = nil
        self.isAttacked = false
    }

    /// The current display state of this cell.
    var state: CellState {
        if isAttacked {
            if shipId != nil {
                return .hit
            } else {
                return .miss
            }
        } else {
            if shipId != nil {
                return .ship
            } else {
                return .empty
            }
        }
    }

    /// Whether this cell contains a ship (regardless of attack state).
    var hasShip: Bool {
        return shipId != nil
    }

    /// Whether this cell is a valid attack target (not yet attacked).
    var isValidTarget: Bool {
        return !isAttacked
    }

    /// Places a ship on this cell.
    /// - Parameter shipId: The UUID of the ship occupying this cell
    /// - Returns: Result indicating success or failure
    mutating func placeShip(id: UUID) -> Result<Void, CellError> {
        guard shipId == nil else {
            return .failure(.alreadyOccupied)
        }
        shipId = id
        return .success(())
    }

    /// Records an attack on this cell.
    /// - Returns: The result of the attack
    mutating func receiveAttack() -> Result<AttackOutcome, CellError> {
        guard !isAttacked else {
            return .failure(.alreadyAttacked)
        }
        isAttacked = true
        if shipId != nil {
            return .success(.hit)
        } else {
            return .success(.miss)
        }
    }

    /// Removes the ship from this cell (used during ship placement reset).
    mutating func removeShip() {
        shipId = nil
    }
}

// MARK: - CellState

/// The visual/logical state of a cell for display purposes.
enum CellState: Equatable, Sendable {
    /// No ship, not attacked
    case empty
    /// Contains ship, not attacked
    case ship
    /// Attacked, had ship (hit)
    case hit
    /// Attacked, no ship (miss)
    case miss
}

// MARK: - AttackOutcome

/// The immediate result of attacking a cell.
enum AttackOutcome: Equatable, Sendable {
    case hit
    case miss
}

// MARK: - CellError

/// Errors that can occur during cell operations.
enum CellError: Error, Equatable, Sendable {
    /// Attempted to place a ship on an occupied cell
    case alreadyOccupied
    /// Attempted to attack an already-attacked cell
    case alreadyAttacked
}
