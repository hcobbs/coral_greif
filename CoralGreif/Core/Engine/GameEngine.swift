//
//  GameEngine.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import Foundation

// MARK: - Game Engine Delegate

/// Delegate protocol for receiving game engine events.
protocol GameEngineDelegate: AnyObject {
    /// Called when a turn begins.
    func gameEngine(_ engine: GameEngine, turnDidBeginFor playerId: UUID)

    /// Called when a turn ends.
    func gameEngine(_ engine: GameEngine, turnDidEndFor playerId: UUID)

    /// Called when an attack is executed.
    func gameEngine(_ engine: GameEngine, didExecuteAttack result: AttackResult, at coordinate: Coordinate, by playerId: UUID)

    /// Called when the game ends.
    func gameEngine(_ engine: GameEngine, gameDidEndWithWinner winnerId: UUID)

    /// Called when the turn timer updates.
    func gameEngine(_ engine: GameEngine, turnTimerDidUpdate remainingSeconds: Int)

    /// Called when a turn times out.
    func gameEngine(_ engine: GameEngine, turnDidTimeoutFor playerId: UUID)
}

// MARK: - Game Engine Error

/// Errors that can occur during game engine operations.
enum GameEngineError: Error, Equatable {
    case gameNotStarted
    case gameAlreadyStarted
    case gameAlreadyFinished
    case notYourTurn
    case invalidAttack
    case fleetNotComplete
    case invalidPlayer
}

// MARK: - Game Engine

/// Coordinates gameplay between players, manages turns, and enforces rules.
final class GameEngine {

    // MARK: - Properties

    /// The current game state.
    private(set) var gameState: GameState

    /// Delegate for receiving game events.
    weak var delegate: GameEngineDelegate?

    /// The turn manager for handling turn timing.
    private var turnManager: TurnManager?

    /// AI player, if one is participating.
    private var aiPlayer: AIPlayer?

    /// Configuration for turn duration.
    let turnDuration: TimeInterval

    /// Whether the game has been started.
    private(set) var isStarted: Bool = false

    // MARK: - Initialization

    /// Creates a new game engine with the given players.
    /// - Parameters:
    ///   - player1: The first player (typically human)
    ///   - player2: The second player (human or AI)
    ///   - turnDuration: Duration of each turn in seconds (default 20)
    ///   - aiPlayer: Optional AI player controller
    init(
        player1: Profile,
        player2: Profile,
        turnDuration: TimeInterval = 20.0,
        aiPlayer: AIPlayer? = nil
    ) {
        self.gameState = GameState(player1: player1, player2: player2)
        self.turnDuration = turnDuration
        self.aiPlayer = aiPlayer
    }

    /// Creates a game engine with an existing game state (for resuming games).
    /// - Parameters:
    ///   - gameState: The game state to resume
    ///   - turnDuration: Duration of each turn in seconds
    ///   - aiPlayer: Optional AI player controller
    init(
        gameState: GameState,
        turnDuration: TimeInterval = 20.0,
        aiPlayer: AIPlayer? = nil
    ) {
        self.gameState = gameState
        self.turnDuration = turnDuration
        self.aiPlayer = aiPlayer
        self.isStarted = gameState.phase == .battle
    }

    // MARK: - Setup Phase

    /// Places a ship for the specified player.
    /// - Parameters:
    ///   - ship: The ship to place
    ///   - playerId: The player placing the ship
    /// - Returns: Success or failure
    func placeShip(_ ship: Ship, for playerId: UUID) -> Result<Void, GameEngineError> {
        guard gameState.phase == .setup else {
            return .failure(.gameAlreadyStarted)
        }

        let result = gameState.placeShip(ship, for: playerId)
        switch result {
        case .success:
            return .success(())
        case .failure:
            return .failure(.invalidAttack)
        }
    }

    /// Removes a ship for the specified player.
    /// - Parameters:
    ///   - shipId: The ID of the ship to remove
    ///   - playerId: The player removing the ship
    /// - Returns: The removed ship or failure
    func removeShip(id shipId: UUID, for playerId: UUID) -> Result<Ship, GameEngineError> {
        guard gameState.phase == .setup else {
            return .failure(.gameAlreadyStarted)
        }

        let result = gameState.removeShip(id: shipId, for: playerId)
        switch result {
        case .success(let ship):
            return .success(ship)
        case .failure:
            return .failure(.invalidAttack)
        }
    }

    /// Checks if both players have complete fleets.
    var canStartBattle: Bool {
        return gameState.player1Board.isFleetComplete && gameState.player2Board.isFleetComplete
    }

    // MARK: - Battle Phase

    /// Starts the battle phase.
    /// - Returns: Success or failure
    func startBattle() -> Result<Void, GameEngineError> {
        guard gameState.phase == .setup else {
            if gameState.phase == .battle {
                return .failure(.gameAlreadyStarted)
            }
            return .failure(.gameAlreadyFinished)
        }

        guard canStartBattle else {
            return .failure(.fleetNotComplete)
        }

        let result = gameState.startBattle()
        switch result {
        case .success:
            isStarted = true
            startTurn()
            return .success(())
        case .failure:
            return .failure(.fleetNotComplete)
        }
    }

    /// Delay before starting the next turn (allows animation/pun reading time).
    private let turnTransitionDelay: TimeInterval = 3.0

    /// Executes an attack at the specified coordinate.
    /// - Parameters:
    ///   - coordinate: The target coordinate
    ///   - playerId: The attacking player
    /// - Returns: The attack result or failure
    func executeAttack(at coordinate: Coordinate, by playerId: UUID) -> Result<AttackResult, GameEngineError> {
        guard isStarted else {
            return .failure(.gameNotStarted)
        }

        guard !gameState.isFinished else {
            return .failure(.gameAlreadyFinished)
        }

        guard playerId == gameState.currentPlayerId else {
            return .failure(.notYourTurn)
        }

        let result = gameState.executeAttack(at: coordinate, by: playerId)

        switch result {
        case .success(let attackResult):
            // Stop the timer immediately after a successful attack
            turnManager?.stop()
            turnManager = nil

            delegate?.gameEngine(self, didExecuteAttack: attackResult, at: coordinate, by: playerId)

            if gameState.isFinished {
                endGame()
            } else {
                // Delay before starting next turn to allow animation and pun reading
                DispatchQueue.main.asyncAfter(deadline: .now() + turnTransitionDelay) { [weak self] in
                    self?.startTurn()
                }
            }

            return .success(attackResult)

        case .failure:
            return .failure(.invalidAttack)
        }
    }

    /// Forfeits the game for the specified player.
    /// - Parameter playerId: The forfeiting player
    /// - Returns: Success or failure
    func forfeit(playerId: UUID) -> Result<Void, GameEngineError> {
        guard isStarted else {
            return .failure(.gameNotStarted)
        }

        guard !gameState.isFinished else {
            return .failure(.gameAlreadyFinished)
        }

        let result = gameState.forfeit(playerId: playerId)
        switch result {
        case .success:
            endGame()
            return .success(())
        case .failure:
            return .failure(.invalidPlayer)
        }
    }

    // MARK: - Turn Management

    /// Starts a new turn.
    private func startTurn() {
        let currentPlayerId = gameState.currentPlayerId

        delegate?.gameEngine(self, turnDidBeginFor: currentPlayerId)

        // Start the turn timer
        turnManager?.stop()
        turnManager = TurnManager(duration: turnDuration)
        turnManager?.delegate = self
        turnManager?.start()

        // If it's the AI's turn, let it play
        if aiPlayer != nil && currentPlayerId == gameState.player2.id {
            performAIMove()
        }
    }

    /// Ends the current turn.
    private func endTurn() {
        turnManager?.stop()
        turnManager = nil

        delegate?.gameEngine(self, turnDidEndFor: gameState.currentPlayerId)
    }

    /// Handles a turn timeout.
    private func handleTimeout() {
        let currentPlayerId = gameState.currentPlayerId

        delegate?.gameEngine(self, turnDidTimeoutFor: currentPlayerId)

        // Execute a random valid attack
        let opponentBoard = gameState.opponentBoard(for: currentPlayerId)
        let validTargets = opponentBoard?.validTargets ?? []

        if let randomTarget = validTargets.randomElement() {
            _ = gameState.executeAttack(at: randomTarget, by: currentPlayerId, wasTimeout: true)

            if gameState.isFinished {
                endGame()
            } else {
                startTurn()
            }
        }
    }

    /// Ends the game.
    private func endGame() {
        turnManager?.stop()
        turnManager = nil

        if let winnerId = gameState.winnerId {
            delegate?.gameEngine(self, gameDidEndWithWinner: winnerId)
        }
    }

    // MARK: - AI

    /// Performs the AI's move after a brief delay.
    private func performAIMove() {
        guard let ai = aiPlayer else { return }
        guard gameState.currentPlayerId == gameState.player2.id else { return }

        // Get the opponent's board (player1's board from AI's perspective)
        guard let targetBoard = gameState.opponentBoard(for: gameState.player2.id) else { return }

        // Let the AI choose a target
        if let target = ai.chooseTarget(against: targetBoard, history: gameState.moveHistory) {
            // Add a small delay to make AI feel more natural
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                guard self.gameState.currentPlayerId == self.gameState.player2.id else { return }

                let result = self.gameState.executeAttack(at: target, by: self.gameState.player2.id)

                if case .success(let attackResult) = result {
                    // Notify AI of the result so it can update its state
                    ai.recordResult(attackResult, at: target)

                    self.delegate?.gameEngine(self, didExecuteAttack: attackResult, at: target, by: self.gameState.player2.id)

                    if self.gameState.isFinished {
                        self.endGame()
                    } else {
                        self.startTurn()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// The current player's ID.
    var currentPlayerId: UUID {
        return gameState.currentPlayerId
    }

    /// Whether the game is finished.
    var isFinished: Bool {
        return gameState.isFinished
    }

    /// The winner's ID, if the game is finished.
    var winnerId: UUID? {
        return gameState.winnerId
    }
}

// MARK: - TurnManagerDelegate

extension GameEngine: TurnManagerDelegate {
    func turnManager(_ manager: TurnManager, didUpdateRemainingTime seconds: Int) {
        delegate?.gameEngine(self, turnTimerDidUpdate: seconds)
    }

    func turnManagerDidTimeout(_ manager: TurnManager) {
        handleTimeout()
    }
}
