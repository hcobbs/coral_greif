//
//  AppCoordinator.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import UIKit

/// Coordinates navigation flow throughout the app.
final class AppCoordinator {

    // MARK: - Properties

    private let window: UIWindow
    private var navigationController: UINavigationController?

    /// The current game engine (persists across screens during a game)
    private var currentEngine: GameEngine?

    /// The current AI player (persists across screens during a game)
    private var currentAI: AIPlayer?

    /// The human player profile
    private var humanPlayer: Profile?

    // MARK: - Initialization

    init(window: UIWindow) {
        self.window = window
    }

    // MARK: - Start

    /// Starts the app flow by showing the main menu.
    func start() {
        let mainMenu = MainMenuViewController()
        mainMenu.delegate = self

        let nav = UINavigationController(rootViewController: mainMenu)
        nav.setNavigationBarHidden(true, animated: false)

        navigationController = nav
        window.rootViewController = nav
        window.makeKeyAndVisible()
    }

    // MARK: - Navigation

    /// Shows the setup screen for ship placement.
    /// - Parameter difficulty: The selected AI difficulty
    private func showSetup(difficulty: AIDifficulty) {
        // Create profiles
        let human = Profile(name: "Captain")
        let ai = Profile.aiPlayer(name: difficulty.displayName, avatarId: difficulty.rawValue)

        humanPlayer = human
        currentAI = AIFactory.create(difficulty: difficulty)
        currentEngine = GameEngine(
            player1: human,
            player2: ai,
            turnDuration: 20.0,
            aiPlayer: currentAI
        )

        // Place AI ships
        if let aiShips = currentAI?.generateShipPlacements(), let engine = currentEngine {
            for ship in aiShips {
                _ = engine.placeShip(ship, for: ai.id)
            }
        }

        let setupVC = SetupViewController(engine: currentEngine!, playerId: human.id)
        setupVC.delegate = self
        navigationController?.pushViewController(setupVC, animated: true)
    }

    /// Shows the battle screen.
    private func showBattle() {
        guard let engine = currentEngine, let human = humanPlayer else { return }

        let battleVC = BattleViewController(engine: engine, playerId: human.id)
        battleVC.delegate = self

        // Replace setup screen with battle screen
        navigationController?.setViewControllers([battleVC], animated: true)
    }

    /// Shows the game over screen.
    /// - Parameters:
    ///   - winnerId: The ID of the winning player
    ///   - engine: The game engine with final state
    private func showGameOver(winnerId: UUID, engine: GameEngine) {
        guard let human = humanPlayer else { return }

        let playerWon = winnerId == human.id
        let gameOverVC = GameOverViewController(
            playerWon: playerWon,
            gameState: engine.gameState
        )
        gameOverVC.delegate = self

        navigationController?.setViewControllers([gameOverVC], animated: true)
    }

    /// Returns to the main menu.
    private func returnToMainMenu() {
        // Clean up game state
        currentEngine = nil
        currentAI = nil
        humanPlayer = nil

        let mainMenu = MainMenuViewController()
        mainMenu.delegate = self
        navigationController?.setViewControllers([mainMenu], animated: true)
    }
}

// MARK: - MainMenuDelegate

extension AppCoordinator: MainMenuDelegate {
    func mainMenuDidSelectNewGame(_ viewController: MainMenuViewController, difficulty: AIDifficulty) {
        showSetup(difficulty: difficulty)
    }

    func mainMenuDidSelectSettings(_ viewController: MainMenuViewController) {
        // Settings screen would go here (future feature)
    }
}

// MARK: - SetupDelegate

extension AppCoordinator: SetupDelegate {
    func setupDidComplete(_ viewController: SetupViewController) {
        guard let engine = currentEngine else { return }

        // Start the battle
        let result = engine.startBattle()
        if case .success = result {
            showBattle()
        }
    }

    func setupDidCancel(_ viewController: SetupViewController) {
        returnToMainMenu()
    }
}

// MARK: - BattleDelegate

extension AppCoordinator: BattleDelegate {
    func battleDidEnd(_ viewController: BattleViewController, winnerId: UUID) {
        guard let engine = currentEngine else { return }
        showGameOver(winnerId: winnerId, engine: engine)
    }

    func battleDidForfeit(_ viewController: BattleViewController) {
        returnToMainMenu()
    }
}

// MARK: - GameOverDelegate

extension AppCoordinator: GameOverDelegate {
    func gameOverDidSelectRematch(_ viewController: GameOverViewController) {
        // Get the same difficulty for rematch
        guard let ai = currentAI else {
            returnToMainMenu()
            return
        }
        showSetup(difficulty: ai.difficulty)
    }

    func gameOverDidSelectMainMenu(_ viewController: GameOverViewController) {
        returnToMainMenu()
    }
}
