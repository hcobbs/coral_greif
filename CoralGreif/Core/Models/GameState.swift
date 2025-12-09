//
//  GameState.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import Foundation

/// Represents the complete state of a game at any point in time.
struct GameState: Equatable, Sendable {
    /// Unique identifier for this game.
    let id: UUID

    /// The first player (typically the human player).
    let player1: Profile

    /// The second player (typically the AI).
    let player2: Profile

    /// Player 1's board.
    private(set) var player1Board: Board

    /// Player 2's board.
    private(set) var player2Board: Board

    /// The ID of the player whose turn it is.
    private(set) var currentPlayerId: UUID

    /// The current phase of the game.
    private(set) var phase: GamePhase

    /// History of all moves.
    private(set) var moveHistory: MoveHistory

    /// When the game was created.
    let createdAt: Date

    /// When the game ended (nil if still in progress).
    private(set) var endedAt: Date?

    /// The ID of the winning player (nil if game not finished or draw).
    private(set) var winnerId: UUID?

    /// Creates a new game with two players.
    /// - Parameters:
    ///   - player1: The first player
    ///   - player2: The second player
    ///   - firstPlayerId: The ID of the player who goes first (random if nil)
    init(player1: Profile, player2: Profile, firstPlayerId: UUID? = nil) {
        self.id = UUID()
        self.player1 = player1
        self.player2 = player2
        self.player1Board = Board()
        self.player2Board = Board()

        // Determine first player (random if not specified)
        if let first = firstPlayerId {
            self.currentPlayerId = first
        } else {
            self.currentPlayerId = Bool.random() ? player1.id : player2.id
        }

        self.phase = .setup
        self.moveHistory = MoveHistory()
        self.createdAt = Date()
        self.endedAt = nil
        self.winnerId = nil
    }

    /// Creates a game state with all values specified (for testing or loading saves).
    init(
        id: UUID,
        player1: Profile,
        player2: Profile,
        player1Board: Board,
        player2Board: Board,
        currentPlayerId: UUID,
        phase: GamePhase,
        moveHistory: MoveHistory,
        createdAt: Date,
        endedAt: Date?,
        winnerId: UUID?
    ) {
        self.id = id
        self.player1 = player1
        self.player2 = player2
        self.player1Board = player1Board
        self.player2Board = player2Board
        self.currentPlayerId = currentPlayerId
        self.phase = phase
        self.moveHistory = moveHistory
        self.createdAt = createdAt
        self.endedAt = endedAt
        self.winnerId = winnerId
    }

    // MARK: - Player Accessors

    /// The current player whose turn it is.
    var currentPlayer: Profile {
        return currentPlayerId == player1.id ? player1 : player2
    }

    /// The opponent of the current player.
    var opponentPlayer: Profile {
        return currentPlayerId == player1.id ? player2 : player1
    }

    /// Gets a player by their ID.
    func player(withId id: UUID) -> Profile? {
        if player1.id == id { return player1 }
        if player2.id == id { return player2 }
        return nil
    }

    /// Gets a player's board.
    func board(for playerId: UUID) -> Board? {
        if playerId == player1.id { return player1Board }
        if playerId == player2.id { return player2Board }
        return nil
    }

    /// Gets the opponent's board for a given player.
    func opponentBoard(for playerId: UUID) -> Board? {
        if playerId == player1.id { return player2Board }
        if playerId == player2.id { return player1Board }
        return nil
    }

    // MARK: - Game State Queries

    /// Whether the game is still in progress.
    var isInProgress: Bool {
        return phase != .finished
    }

    /// Whether it's the setup phase.
    var isSetupPhase: Bool {
        return phase == .setup
    }

    /// Whether it's the battle phase.
    var isBattlePhase: Bool {
        return phase == .battle
    }

    /// Whether the game has finished.
    var isFinished: Bool {
        return phase == .finished
    }

    /// The winning player, if the game is finished.
    var winner: Profile? {
        guard let winnerId = winnerId else { return nil }
        return player(withId: winnerId)
    }

    /// The losing player, if the game is finished.
    var loser: Profile? {
        guard let winnerId = winnerId else { return nil }
        return winnerId == player1.id ? player2 : player1
    }

    /// Total number of turns played.
    var totalTurns: Int {
        return moveHistory.count
    }

    // MARK: - Mutations

    /// Places a ship on a player's board.
    /// - Parameters:
    ///   - ship: The ship to place
    ///   - playerId: The ID of the player whose board to modify
    /// - Returns: Result indicating success or failure
    mutating func placeShip(_ ship: Ship, for playerId: UUID) -> Result<Void, GameError> {
        guard phase == .setup else {
            return .failure(.invalidPhase)
        }

        if playerId == player1.id {
            let result = player1Board.placeShip(ship)
            return result.mapError { _ in GameError.shipPlacementFailed }
        } else if playerId == player2.id {
            let result = player2Board.placeShip(ship)
            return result.mapError { _ in GameError.shipPlacementFailed }
        } else {
            return .failure(.playerNotFound)
        }
    }

    /// Removes a ship from a player's board.
    /// - Parameters:
    ///   - shipId: The ID of the ship to remove
    ///   - playerId: The ID of the player whose board to modify
    /// - Returns: The removed ship or failure
    mutating func removeShip(id shipId: UUID, for playerId: UUID) -> Result<Ship, GameError> {
        guard phase == .setup else {
            return .failure(.invalidPhase)
        }

        if playerId == player1.id {
            let result = player1Board.removeShip(id: shipId)
            return result.mapError { _ in GameError.shipPlacementFailed }
        } else if playerId == player2.id {
            let result = player2Board.removeShip(id: shipId)
            return result.mapError { _ in GameError.shipPlacementFailed }
        } else {
            return .failure(.playerNotFound)
        }
    }

    /// Transitions from setup to battle phase.
    /// - Returns: Result indicating success or failure
    mutating func startBattle() -> Result<Void, GameError> {
        guard phase == .setup else {
            return .failure(.invalidPhase)
        }

        guard player1Board.isFleetComplete && player2Board.isFleetComplete else {
            return .failure(.fleetIncomplete)
        }

        phase = .battle
        return .success(())
    }

    /// Executes an attack.
    /// - Parameters:
    ///   - coordinate: The coordinate to attack
    ///   - playerId: The attacking player's ID
    ///   - wasTimeout: Whether this was a timeout-forced move
    /// - Returns: The attack result
    mutating func executeAttack(
        at coordinate: Coordinate,
        by playerId: UUID,
        wasTimeout: Bool = false
    ) -> Result<AttackResult, GameError> {
        guard phase == .battle else {
            return .failure(.invalidPhase)
        }

        guard playerId == currentPlayerId else {
            return .failure(.notYourTurn)
        }

        // Attack opponent's board
        var targetBoard: Board
        if playerId == player1.id {
            targetBoard = player2Board
        } else {
            targetBoard = player1Board
        }

        let attackResult = targetBoard.receiveAttack(at: coordinate)

        switch attackResult {
        case .failure(let error):
            if error == .alreadyAttacked {
                return .failure(.alreadyAttacked)
            }
            return .failure(.invalidAttack)

        case .success(let result):
            // Update the board
            if playerId == player1.id {
                player2Board = targetBoard
            } else {
                player1Board = targetBoard
            }

            // Record the move
            let move = Move(
                playerId: playerId,
                coordinate: coordinate,
                result: result,
                wasTimeout: wasTimeout
            )
            moveHistory.add(move)

            // Check for win condition
            if targetBoard.allShipsSunk {
                phase = .finished
                winnerId = playerId
                endedAt = Date()
            } else {
                // Switch turns
                switchTurn()
            }

            return .success(result)
        }
    }

    /// Switches to the other player's turn.
    private mutating func switchTurn() {
        currentPlayerId = currentPlayerId == player1.id ? player2.id : player1.id
    }

    /// Forfeits the game for a player.
    /// - Parameter playerId: The player who is forfeiting
    /// - Returns: Result indicating success or failure
    mutating func forfeit(playerId: UUID) -> Result<Void, GameError> {
        guard isInProgress else {
            return .failure(.gameAlreadyFinished)
        }

        guard playerId == player1.id || playerId == player2.id else {
            return .failure(.playerNotFound)
        }

        phase = .finished
        winnerId = playerId == player1.id ? player2.id : player1.id
        endedAt = Date()
        return .success(())
    }
}

// MARK: - GamePhase

/// The phases of a game.
enum GamePhase: Equatable, Codable, Sendable {
    /// Players are placing their ships.
    case setup
    /// Players are taking turns attacking.
    case battle
    /// The game has ended.
    case finished
}

// MARK: - GameError

/// Errors that can occur during game operations.
enum GameError: Error, Equatable, Sendable {
    /// Action not allowed in current phase
    case invalidPhase
    /// Player not found in this game
    case playerNotFound
    /// Ship placement failed
    case shipPlacementFailed
    /// Fleet is not complete
    case fleetIncomplete
    /// Not this player's turn
    case notYourTurn
    /// Coordinate already attacked
    case alreadyAttacked
    /// Invalid attack
    case invalidAttack
    /// Game has already finished
    case gameAlreadyFinished
}
