//
//  Move.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import Foundation

/// Represents a single move (attack) in the game.
struct Move: Identifiable, Equatable, Codable, Sendable {
    /// Unique identifier for this move.
    let id: UUID

    /// The ID of the player who made this move.
    let playerId: UUID

    /// The coordinate that was attacked.
    let coordinate: Coordinate

    /// The result of the attack.
    let result: AttackResult

    /// When the move was made.
    let timestamp: Date

    /// Whether this move was made due to timeout (auto-generated).
    let wasTimeout: Bool

    /// Creates a new move record.
    /// - Parameters:
    ///   - playerId: The ID of the attacking player
    ///   - coordinate: The attacked coordinate
    ///   - result: The outcome of the attack
    ///   - wasTimeout: Whether this was an auto-generated timeout move
    init(playerId: UUID, coordinate: Coordinate, result: AttackResult, wasTimeout: Bool = false) {
        self.id = UUID()
        self.playerId = playerId
        self.coordinate = coordinate
        self.result = result
        self.timestamp = Date()
        self.wasTimeout = wasTimeout
    }

    /// Creates a move with specific values (for testing or loading saved data).
    init(
        id: UUID,
        playerId: UUID,
        coordinate: Coordinate,
        result: AttackResult,
        timestamp: Date,
        wasTimeout: Bool
    ) {
        self.id = id
        self.playerId = playerId
        self.coordinate = coordinate
        self.result = result
        self.timestamp = timestamp
        self.wasTimeout = wasTimeout
    }

    /// Whether this move was a hit (hit or sunk).
    var isHit: Bool {
        switch result {
        case .hit, .sunk:
            return true
        case .miss:
            return false
        }
    }

    /// Whether this move sunk a ship.
    var didSink: Bool {
        if case .sunk = result {
            return true
        }
        return false
    }

    /// The ship type that was sunk, if any.
    var sunkShipType: ShipType? {
        if case .sunk(let shipType) = result {
            return shipType
        }
        return nil
    }
}

// MARK: - Codable conformance for AttackResult

extension AttackResult: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case shipType
    }

    private enum ResultType: String, Codable {
        case miss
        case hit
        case sunk
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ResultType.self, forKey: .type)

        switch type {
        case .miss:
            self = .miss
        case .hit:
            self = .hit
        case .sunk:
            let shipType = try container.decode(ShipType.self, forKey: .shipType)
            self = .sunk(shipType)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .miss:
            try container.encode(ResultType.miss, forKey: .type)
        case .hit:
            try container.encode(ResultType.hit, forKey: .type)
        case .sunk(let shipType):
            try container.encode(ResultType.sunk, forKey: .type)
            try container.encode(shipType, forKey: .shipType)
        }
    }
}

// MARK: - MoveHistory

/// A collection of moves representing the history of a game.
struct MoveHistory: Equatable, Sendable {
    /// All moves in chronological order.
    private(set) var moves: [Move]

    /// Creates an empty move history.
    init() {
        self.moves = []
    }

    /// Creates a move history with existing moves.
    init(moves: [Move]) {
        self.moves = moves
    }

    /// Adds a move to the history.
    mutating func add(_ move: Move) {
        moves.append(move)
    }

    /// The total number of moves.
    var count: Int {
        return moves.count
    }

    /// Whether the history is empty.
    var isEmpty: Bool {
        return moves.isEmpty
    }

    /// The last move made, if any.
    var lastMove: Move? {
        return moves.last
    }

    /// All moves made by a specific player.
    func moves(by playerId: UUID) -> [Move] {
        return moves.filter { $0.playerId == playerId }
    }

    /// The number of hits by a specific player.
    func hits(by playerId: UUID) -> Int {
        return moves(by: playerId).filter { $0.isHit }.count
    }

    /// The number of misses by a specific player.
    func misses(by playerId: UUID) -> Int {
        return moves(by: playerId).filter { !$0.isHit }.count
    }

    /// The number of ships sunk by a specific player.
    func shipsSunk(by playerId: UUID) -> Int {
        return moves(by: playerId).filter { $0.didSink }.count
    }

    /// Count of consecutive misses for a player (from most recent).
    func consecutiveMisses(by playerId: UUID) -> Int {
        let playerMoves = moves(by: playerId)
        var count = 0
        for move in playerMoves.reversed() {
            if move.isHit {
                break
            }
            count += 1
        }
        return count
    }

    /// All coordinates that have been attacked.
    var attackedCoordinates: Set<Coordinate> {
        return Set(moves.map { $0.coordinate })
    }
}
