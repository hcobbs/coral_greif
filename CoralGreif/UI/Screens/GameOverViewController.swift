//
//  GameOverViewController.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import UIKit

/// Delegate for game over screen events.
protocol GameOverDelegate: AnyObject {
    func gameOverDidSelectRematch(_ viewController: GameOverViewController)
    func gameOverDidSelectMainMenu(_ viewController: GameOverViewController)
}

/// Screen displayed when the game ends.
final class GameOverViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: GameOverDelegate?

    private let playerWon: Bool
    private let gameState: GameState
    private let punGenerator = PunGenerator.shared

    // MARK: - UI Elements

    private lazy var resultLabel: UILabel = {
        let label = UILabel()
        label.applyTitleStyle()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.applyHeadingStyle()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var punLabel: UILabel = {
        let label = UILabel()
        label.applyBodyStyle()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var statsContainer: UIView = {
        let view = UIView()
        view.applyCardStyle()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var statsLabel: UILabel = {
        let label = UILabel()
        label.font = AppTheme.Fonts.monospace()
        label.textColor = AppTheme.Colors.textPrimary
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var rematchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Rematch", for: .normal)
        button.applyPrimaryStyle()
        button.addTarget(self, action: #selector(rematchTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Main Menu", for: .normal)
        button.applySecondaryStyle()
        button.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Initialization

    init(playerWon: Bool, gameState: GameState) {
        self.playerWon = playerWon
        self.gameState = gameState
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayResults()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.oceanDeep

        view.addSubview(resultLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(punLabel)
        view.addSubview(statsContainer)
        statsContainer.addSubview(statsLabel)
        view.addSubview(rematchButton)
        view.addSubview(menuButton)

        let padding = AppTheme.Layout.padding

        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            punLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: padding),
            punLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding * 2),
            punLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding * 2),

            statsContainer.topAnchor.constraint(equalTo: punLabel.bottomAnchor, constant: padding * 2),
            statsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            statsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            statsLabel.topAnchor.constraint(equalTo: statsContainer.topAnchor, constant: padding),
            statsLabel.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: padding),
            statsLabel.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -padding),
            statsLabel.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: -padding),

            rematchButton.bottomAnchor.constraint(equalTo: menuButton.topAnchor, constant: -padding),
            rematchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rematchButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),

            menuButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding * 2),
            menuButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            menuButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }

    // MARK: - Display

    private func displayResults() {
        if playerWon {
            resultLabel.text = "VICTORY"
            resultLabel.textColor = AppTheme.Colors.victoryGreen
            subtitleLabel.text = "Enemy fleet destroyed!"
            subtitleLabel.textColor = AppTheme.Colors.brassGold
            punLabel.text = punGenerator.pun(for: .onVictory)
        } else {
            resultLabel.text = "DEFEAT"
            resultLabel.textColor = AppTheme.Colors.hitRed
            subtitleLabel.text = "Your fleet has been sunk."
            subtitleLabel.textColor = AppTheme.Colors.textSecondary
            punLabel.text = punGenerator.pun(for: .onDefeat)
        }

        statsLabel.text = buildStatsText()
    }

    private func buildStatsText() -> String {
        let history = gameState.moveHistory
        let playerId = gameState.player1.id
        let opponentId = gameState.player2.id

        let playerMoves = history.moves(by: playerId)
        let opponentMoves = history.moves(by: opponentId)

        let playerHits = playerMoves.filter { $0.result != .miss }.count
        let playerMisses = playerMoves.filter { $0.result == .miss }.count
        let playerTotal = playerHits + playerMisses
        let playerAccuracy = playerTotal > 0 ? Int((Double(playerHits) / Double(playerTotal)) * 100) : 0

        let opponentHits = opponentMoves.filter { $0.result != .miss }.count
        let opponentMisses = opponentMoves.filter { $0.result == .miss }.count
        let opponentTotal = opponentHits + opponentMisses
        let opponentAccuracy = opponentTotal > 0 ? Int((Double(opponentHits) / Double(opponentTotal)) * 100) : 0

        let playerShipsSunk = countSunkShips(in: gameState.player2Board)
        let opponentShipsSunk = countSunkShips(in: gameState.player1Board)

        return """
        BATTLE REPORT

        Your Stats:
          Shots Fired: \(playerTotal)
          Hits: \(playerHits)
          Misses: \(playerMisses)
          Accuracy: \(playerAccuracy)%
          Ships Sunk: \(playerShipsSunk)

        Enemy Stats:
          Shots Fired: \(opponentTotal)
          Hits: \(opponentHits)
          Misses: \(opponentMisses)
          Accuracy: \(opponentAccuracy)%
          Ships Sunk: \(opponentShipsSunk)

        Total Turns: \(gameState.totalTurns)
        """
    }

    private func countSunkShips(in board: Board) -> Int {
        return board.ships.filter { $0.isSunk }.count
    }

    // MARK: - Actions

    @objc private func rematchTapped() {
        delegate?.gameOverDidSelectRematch(self)
    }

    @objc private func menuTapped() {
        delegate?.gameOverDidSelectMainMenu(self)
    }
}
