//
//  AIPlayer.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import Foundation

// MARK: - AI Difficulty

/// Difficulty levels for AI opponents.
enum AIDifficulty: String, CaseIterable, Codable, Sendable {
    case ensign = "Ensign"
    case commander = "Commander"
    case admiral = "Admiral"

    /// Display name for the difficulty.
    var displayName: String {
        return rawValue
    }

    /// Description of the difficulty.
    var description: String {
        switch self {
        case .ensign:
            return "Random targeting. Good for beginners."
        case .commander:
            return "Hunt and target strategy. Fair challenge."
        case .admiral:
            return "Probability-based targeting. Expert level."
        }
    }
}

// MARK: - AI Player Protocol

/// Protocol for AI opponents.
protocol AIPlayer: AnyObject {
    /// The difficulty level of this AI.
    var difficulty: AIDifficulty { get }

    /// Chooses a target coordinate for an attack.
    /// - Parameters:
    ///   - board: The opponent's board (visible state only, no ship positions)
    ///   - history: The move history for reference
    /// - Returns: The chosen coordinate, or nil if no valid targets
    func chooseTarget(against board: Board, history: MoveHistory) -> Coordinate?

    /// Records the result of an attack so the AI can update its strategy.
    /// - Parameters:
    ///   - result: The result of the attack
    ///   - coordinate: The coordinate that was attacked
    func recordResult(_ result: AttackResult, at coordinate: Coordinate)

    /// Resets the AI state for a new game.
    func reset()

    /// Generates a random valid ship placement for the AI's board.
    /// - Returns: An array of ships with valid placements
    func generateShipPlacements() -> [Ship]
}

// MARK: - Random AI (Ensign)

/// Simple AI that attacks randomly. Used for Ensign difficulty.
final class RandomAI: AIPlayer {
    let difficulty: AIDifficulty = .ensign

    func chooseTarget(against board: Board, history: MoveHistory) -> Coordinate? {
        let validTargets = board.validTargets
        return validTargets.randomElement()
    }

    func recordResult(_ result: AttackResult, at coordinate: Coordinate) {
        // Random AI doesn't learn from results
    }

    func reset() {
        // Nothing to reset
    }

    func generateShipPlacements() -> [Ship] {
        return ShipPlacer.generateRandomPlacements()
    }
}

// MARK: - Hunt/Target AI (Commander)

/// AI that uses hunt-and-target strategy. Used for Commander difficulty.
final class HuntTargetAI: AIPlayer {
    let difficulty: AIDifficulty = .commander

    // MARK: - State

    private enum Mode {
        case hunting
        case targeting(lastHit: Coordinate, direction: Direction?, hits: [Coordinate])
    }

    private var mode: Mode = .hunting
    private var attackedCells: Set<Coordinate> = []

    // MARK: - Target Selection

    func chooseTarget(against board: Board, history: MoveHistory) -> Coordinate? {
        let validTargets = board.validTargets.filter { !attackedCells.contains($0) }

        guard !validTargets.isEmpty else { return nil }

        switch mode {
        case .hunting:
            return chooseHuntTarget(from: validTargets)

        case .targeting(let lastHit, let direction, let hits):
            if let target = chooseTargetModeTarget(lastHit: lastHit, direction: direction, hits: hits, validTargets: validTargets) {
                return target
            }
            // Fallback to hunt mode if no valid adjacent targets
            return chooseHuntTarget(from: validTargets)
        }
    }

    /// Chooses a target in hunt mode (checkerboard pattern for efficiency).
    private func chooseHuntTarget(from validTargets: [Coordinate]) -> Coordinate? {
        // Prefer checkerboard pattern for optimal coverage
        let checkerboardTargets = validTargets.filter { ($0.row + $0.column) % 2 == 0 }

        if !checkerboardTargets.isEmpty {
            return checkerboardTargets.randomElement()
        }

        return validTargets.randomElement()
    }

    /// Chooses a target in target mode (following up on hits).
    private func chooseTargetModeTarget(
        lastHit: Coordinate,
        direction: Direction?,
        hits: [Coordinate],
        validTargets: [Coordinate]
    ) -> Coordinate? {
        // If we have a direction, continue in that direction
        if let dir = direction {
            if let nextTarget = lastHit.adjacent(in: dir), validTargets.contains(nextTarget) {
                return nextTarget
            }
            // Try opposite direction from first hit
            if let firstHit = hits.first, let oppositeTarget = firstHit.adjacent(in: dir.opposite), validTargets.contains(oppositeTarget) {
                return oppositeTarget
            }
        }

        // Try all adjacent cells to any hit
        for hit in hits {
            for dir in Direction.allCases {
                if let adjacent = hit.adjacent(in: dir), validTargets.contains(adjacent) {
                    return adjacent
                }
            }
        }

        return nil
    }

    // MARK: - Result Recording

    func recordResult(_ result: AttackResult, at coordinate: Coordinate) {
        attackedCells.insert(coordinate)

        switch result {
        case .miss:
            handleMiss(at: coordinate)
        case .hit:
            handleHit(at: coordinate)
        case .sunk:
            handleSunk()
        }
    }

    private func handleMiss(at coordinate: Coordinate) {
        switch mode {
        case .hunting:
            // Stay in hunt mode
            break
        case .targeting(_, let direction, let hits):
            // If we had a direction and missed, try opposite from first hit
            if direction != nil, let firstHit = hits.first {
                // Reset to target from first hit without direction
                mode = .targeting(lastHit: firstHit, direction: nil, hits: hits)
            }
            // If no more adjacent options, hunting will take over
        }
    }

    private func handleHit(at coordinate: Coordinate) {
        switch mode {
        case .hunting:
            // Switch to target mode
            mode = .targeting(lastHit: coordinate, direction: nil, hits: [coordinate])

        case .targeting(let lastHit, _, var hits):
            hits.append(coordinate)
            // Determine direction from last hit to this hit
            let direction = determineDirection(from: lastHit, to: coordinate)
            mode = .targeting(lastHit: coordinate, direction: direction, hits: hits)
        }
    }

    private func handleSunk() {
        // Ship sunk, return to hunt mode
        mode = .hunting
    }

    /// Determines the direction from one coordinate to an adjacent coordinate.
    private func determineDirection(from: Coordinate, to: Coordinate) -> Direction? {
        if to.row == from.row - 1 { return .up }
        if to.row == from.row + 1 { return .down }
        if to.column == from.column - 1 { return .left }
        if to.column == from.column + 1 { return .right }
        return nil
    }

    // MARK: - Reset

    func reset() {
        mode = .hunting
        attackedCells.removeAll()
    }

    // MARK: - Ship Placement

    func generateShipPlacements() -> [Ship] {
        return ShipPlacer.generateRandomPlacements()
    }
}

// MARK: - Probability AI (Admiral)

/// AI that uses probability calculations. Used for Admiral difficulty.
final class ProbabilityAI: AIPlayer {
    let difficulty: AIDifficulty = .admiral

    private var attackedCells: Set<Coordinate> = []
    private var hits: [Coordinate] = []
    private var remainingShipSizes: [Int] = [5, 4, 3, 3, 2]

    func chooseTarget(against board: Board, history: MoveHistory) -> Coordinate? {
        let validTargets = board.validTargets.filter { !attackedCells.contains($0) }

        guard !validTargets.isEmpty else { return nil }

        // If we have unsunk hits, prioritize adjacent cells
        if !hits.isEmpty {
            let adjacentTargets = findAdjacentTargets(to: hits, in: validTargets)
            if let best = adjacentTargets.max(by: { probability(for: $0) < probability(for: $1) }) {
                return best
            }
        }

        // Calculate probability for each cell
        let scored = validTargets.map { ($0, probability(for: $0)) }
        let maxScore = scored.max(by: { $0.1 < $1.1 })?.1 ?? 0

        // Choose randomly among highest probability cells
        let bestTargets = scored.filter { $0.1 == maxScore }.map { $0.0 }
        return bestTargets.randomElement()
    }

    private func findAdjacentTargets(to hits: [Coordinate], in validTargets: [Coordinate]) -> [Coordinate] {
        var adjacent: Set<Coordinate> = []

        for hit in hits {
            for direction in Direction.allCases {
                if let adj = hit.adjacent(in: direction), validTargets.contains(adj) {
                    adjacent.insert(adj)
                }
            }
        }

        return Array(adjacent)
    }

    /// Calculates the probability that a cell contains a ship.
    private func probability(for coordinate: Coordinate) -> Double {
        var score = 0.0

        for size in remainingShipSizes {
            // Check horizontal placements
            score += Double(countValidPlacements(at: coordinate, size: size, orientation: .horizontal))
            // Check vertical placements
            score += Double(countValidPlacements(at: coordinate, size: size, orientation: .vertical))
        }

        return score
    }

    /// Counts how many valid ship placements include this coordinate.
    private func countValidPlacements(at coordinate: Coordinate, size: Int, orientation: Orientation) -> Int {
        var count = 0

        for offset in 0..<size {
            let origin: Coordinate?

            if orientation == .horizontal {
                origin = Coordinate(row: coordinate.row, column: coordinate.column - offset)
            } else {
                origin = Coordinate(row: coordinate.row - offset, column: coordinate.column)
            }

            guard let start = origin else { continue }

            // Check if this placement is valid
            var valid = true
            for i in 0..<size {
                let checkCoord: Coordinate?
                if orientation == .horizontal {
                    checkCoord = Coordinate(row: start.row, column: start.column + i)
                } else {
                    checkCoord = Coordinate(row: start.row + i, column: start.column)
                }

                guard let coord = checkCoord else {
                    valid = false
                    break
                }

                // Cell must not be already attacked (and missed)
                if attackedCells.contains(coord) && !hits.contains(coord) {
                    valid = false
                    break
                }
            }

            if valid {
                count += 1
            }
        }

        return count
    }

    func recordResult(_ result: AttackResult, at coordinate: Coordinate) {
        attackedCells.insert(coordinate)

        switch result {
        case .miss:
            hits.removeAll { $0 == coordinate }
        case .hit:
            hits.append(coordinate)
        case .sunk(let shipType):
            // Remove the sunk ship from remaining sizes
            if let index = remainingShipSizes.firstIndex(of: shipType.size) {
                remainingShipSizes.remove(at: index)
            }
            // Remove hits that belong to this ship (approximate)
            hits.removeAll()
        }
    }

    func reset() {
        attackedCells.removeAll()
        hits.removeAll()
        remainingShipSizes = [5, 4, 3, 3, 2]
    }

    func generateShipPlacements() -> [Ship] {
        return ShipPlacer.generateRandomPlacements()
    }
}

// MARK: - Ship Placer

/// Utility for generating random ship placements.
enum ShipPlacer {

    /// Generates valid random placements for all ships.
    static func generateRandomPlacements() -> [Ship] {
        var board = Board()
        var ships: [Ship] = []

        for shipType in FleetConfiguration.standard {
            var placed = false
            var attempts = 0
            let maxAttempts = 100

            while !placed && attempts < maxAttempts {
                attempts += 1

                let row = Int.random(in: 0..<Coordinate.boardSize)
                let column = Int.random(in: 0..<Coordinate.boardSize)
                let orientation: Orientation = Bool.random() ? .horizontal : .vertical

                guard let origin = Coordinate(row: row, column: column) else { continue }

                let ship = Ship(type: shipType, origin: origin, orientation: orientation)

                if case .success = board.placeShip(ship) {
                    ships.append(ship)
                    placed = true
                }
            }

            if !placed {
                // Fallback: start over if we couldn't place a ship
                return generateRandomPlacements()
            }
        }

        return ships
    }
}

// MARK: - AI Factory

/// Factory for creating AI players.
enum AIFactory {

    /// Creates an AI player with the specified difficulty.
    static func create(difficulty: AIDifficulty) -> AIPlayer {
        switch difficulty {
        case .ensign:
            return RandomAI()
        case .commander:
            return HuntTargetAI()
        case .admiral:
            return ProbabilityAI()
        }
    }
}
