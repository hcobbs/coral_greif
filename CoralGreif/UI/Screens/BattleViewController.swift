//
//  BattleViewController.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import UIKit

/// Delegate for battle screen events.
protocol BattleDelegate: AnyObject {
    func battleDidEnd(_ viewController: BattleViewController, winnerId: UUID)
    func battleDidForfeit(_ viewController: BattleViewController)
}

/// The main battle screen where gameplay occurs.
final class BattleViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: BattleDelegate?

    private let engine: GameEngine
    private let playerId: UUID
    private let punGenerator = PunGenerator.shared

    /// Whether the player can interact (their turn)
    private var canInteract: Bool {
        return engine.currentPlayerId == playerId && !engine.isFinished
    }

    // MARK: - UI Elements

    private lazy var turnLabel: UILabel = {
        let label = UILabel()
        label.applyHeadingStyle()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.font = AppTheme.Fonts.timer()
        label.textColor = AppTheme.Colors.textPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var punLabel: UILabel = {
        let label = UILabel()
        label.applyBodyStyle()
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var enemyBoardLabel: UILabel = {
        let label = UILabel()
        label.text = "Enemy Waters"
        label.font = AppTheme.Fonts.caption()
        label.textColor = AppTheme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var enemyBoardView: BoardView = {
        let view = BoardView()
        view.displayMode = .hidden
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var playerBoardLabel: UILabel = {
        let label = UILabel()
        label.text = "Your Fleet"
        label.font = AppTheme.Fonts.caption()
        label.textColor = AppTheme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var playerBoardView: BoardView = {
        let view = BoardView()
        view.displayMode = .full
        view.interactionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var forfeitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Surrender", for: .normal)
        button.setTitleColor(AppTheme.Colors.textSecondary, for: .normal)
        button.titleLabel?.font = AppTheme.Fonts.caption()
        button.addTarget(self, action: #selector(forfeitTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var statsView: BattleStatsView = {
        let view = BattleStatsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initialization

    init(engine: GameEngine, playerId: UUID) {
        self.engine = engine
        self.playerId = playerId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEngine()
        updateUI()
        showStartPun()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.oceanDeep

        view.addSubview(turnLabel)
        view.addSubview(timerLabel)
        view.addSubview(punLabel)
        view.addSubview(enemyBoardLabel)
        view.addSubview(enemyBoardView)
        view.addSubview(playerBoardLabel)
        view.addSubview(playerBoardView)
        view.addSubview(forfeitButton)
        view.addSubview(statsView)

        let padding = AppTheme.Layout.padding
        let smallPadding = AppTheme.Layout.paddingSmall

        NSLayoutConstraint.activate([
            turnLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: smallPadding),
            turnLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            timerLabel.topAnchor.constraint(equalTo: turnLabel.bottomAnchor, constant: smallPadding),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            punLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: smallPadding),
            punLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            punLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            enemyBoardLabel.topAnchor.constraint(equalTo: punLabel.bottomAnchor, constant: padding),
            enemyBoardLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            enemyBoardView.topAnchor.constraint(equalTo: enemyBoardLabel.bottomAnchor, constant: smallPadding),
            enemyBoardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            enemyBoardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            enemyBoardView.heightAnchor.constraint(equalTo: enemyBoardView.widthAnchor),

            statsView.topAnchor.constraint(equalTo: enemyBoardView.bottomAnchor, constant: padding),
            statsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            statsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            playerBoardLabel.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: padding),
            playerBoardLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            playerBoardView.topAnchor.constraint(equalTo: playerBoardLabel.bottomAnchor, constant: smallPadding),
            playerBoardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding * 3),
            playerBoardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding * 3),
            playerBoardView.heightAnchor.constraint(equalTo: playerBoardView.widthAnchor),

            forfeitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -smallPadding),
            forfeitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupEngine() {
        engine.delegate = self
    }

    // MARK: - Actions

    @objc private func forfeitTapped() {
        let alert = UIAlertController(
            title: "Surrender?",
            message: "Are you sure you want to surrender? This will end the battle.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Surrender", style: .destructive) { [weak self] _ in
            self?.performForfeit()
        })

        present(alert, animated: true)
    }

    private func performForfeit() {
        let result = engine.forfeit(playerId: playerId)
        if case .success = result {
            delegate?.battleDidForfeit(self)
        }
    }

    // MARK: - Game Logic

    private func executeAttack(at coordinate: Coordinate) {
        let result = engine.executeAttack(at: coordinate, by: playerId)

        switch result {
        case .success(let attackResult):
            handleAttackResult(attackResult, at: coordinate, isPlayer: true)

        case .failure:
            // Invalid attack (already attacked, etc.)
            showInvalidAttackFeedback()
        }
    }

    private func handleAttackResult(_ result: AttackResult, at coordinate: Coordinate, isPlayer: Bool) {
        let boardView = isPlayer ? enemyBoardView : playerBoardView

        switch result {
        case .miss:
            boardView.animateMiss(at: coordinate) { [weak self] in
                self?.showPun(for: .onMiss)
            }

        case .hit:
            boardView.animateHit(at: coordinate) { [weak self] in
                self?.showPun(for: .onHit)
            }

        case .sunk(let shipType):
            boardView.animateHit(at: coordinate) { [weak self] in
                self?.showSunkMessage(shipType: shipType, byPlayer: isPlayer)
            }
        }

        updateBoards()
        updateStats()
    }

    // MARK: - UI Updates

    private func updateUI() {
        updateTurnLabel()
        updateBoards()
        updateStats()
        updateInteraction()
    }

    private func updateTurnLabel() {
        if engine.currentPlayerId == playerId {
            turnLabel.text = "Your Turn"
            turnLabel.textColor = AppTheme.Colors.brassGold
        } else {
            turnLabel.text = "Enemy Turn"
            turnLabel.textColor = AppTheme.Colors.textSecondary
        }
    }

    private func updateBoards() {
        enemyBoardView.board = engine.gameState.opponentBoard(for: playerId)
        playerBoardView.board = engine.gameState.board(for: playerId)
    }

    private func updateStats() {
        let history = engine.gameState.moveHistory
        let playerMoves = history.moves(by: playerId)
        let opponentId = engine.gameState.currentPlayerId == playerId ?
            engine.gameState.opponentPlayer.id : engine.gameState.currentPlayer.id
        let opponentMoves = history.moves(by: opponentId)

        let playerHits = playerMoves.filter { $0.result != .miss }.count
        let playerMisses = playerMoves.filter { $0.result == .miss }.count
        let enemyHits = opponentMoves.filter { $0.result != .miss }.count

        // Count remaining ships
        let playerShipsRemaining = engine.gameState.board(for: playerId)?.ships.filter { !$0.isSunk }.count ?? 0
        let enemyShipsRemaining = engine.gameState.opponentBoard(for: playerId)?.ships.filter { !$0.isSunk }.count ?? 0

        statsView.update(
            playerHits: playerHits,
            playerMisses: playerMisses,
            playerShipsRemaining: playerShipsRemaining,
            enemyHits: enemyHits,
            enemyShipsRemaining: enemyShipsRemaining
        )
    }

    private func updateInteraction() {
        enemyBoardView.interactionEnabled = canInteract
        enemyBoardView.alpha = canInteract ? 1.0 : 0.8
    }

    private func updateTimer(_ seconds: Int) {
        timerLabel.text = String(format: "%02d", seconds)

        if seconds <= 5 {
            timerLabel.textColor = AppTheme.Colors.warningOrange
        } else {
            timerLabel.textColor = AppTheme.Colors.textPrimary
        }
    }

    // MARK: - Feedback

    private func showStartPun() {
        punLabel.text = punGenerator.pun(for: .onGameStart)
    }

    private func showPun(for category: PunCategory) {
        punLabel.text = punGenerator.pun(for: category)
    }

    private func showSunkMessage(shipType: ShipType, byPlayer: Bool) {
        if byPlayer {
            punLabel.text = "You sunk their \(shipType.displayName)! \(punGenerator.pun(for: .onSunk(shipType)))"
        } else {
            punLabel.text = "They sunk your \(shipType.displayName)!"
        }
    }

    private func showInvalidAttackFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        punLabel.text = "Already fired there, Captain!"
    }

    private func showTimeoutWarning() {
        punLabel.text = punGenerator.pun(for: .onTimeout)
        punLabel.textColor = AppTheme.Colors.warningOrange

        UIView.animate(withDuration: 0.5) {
            self.punLabel.textColor = AppTheme.Colors.textSecondary
        }
    }
}

// MARK: - BoardViewDelegate

extension BattleViewController: BoardViewDelegate {
    func boardView(_ boardView: BoardView, didTapCellAt coordinate: Coordinate) {
        guard boardView == enemyBoardView && canInteract else { return }
        executeAttack(at: coordinate)
    }
}

// MARK: - GameEngineDelegate

extension BattleViewController: GameEngineDelegate {
    func gameEngine(_ engine: GameEngine, turnDidBeginFor turnPlayerId: UUID) {
        updateTurnLabel()
        updateInteraction()

        if turnPlayerId == playerId {
            punLabel.text = "Fire when ready!"
        } else {
            punLabel.text = "Enemy is targeting..."
        }
    }

    func gameEngine(_ engine: GameEngine, turnDidEndFor turnPlayerId: UUID) {
        // Turn ended, update will come from turnDidBegin
    }

    func gameEngine(_ engine: GameEngine, didExecuteAttack result: AttackResult, at coordinate: Coordinate, by attackerId: UUID) {
        let isPlayer = attackerId == playerId
        handleAttackResult(result, at: coordinate, isPlayer: isPlayer)
    }

    func gameEngine(_ engine: GameEngine, gameDidEndWithWinner winnerId: UUID) {
        // Show appropriate pun
        if winnerId == playerId {
            punLabel.text = punGenerator.pun(for: .onVictory)
        } else {
            punLabel.text = punGenerator.pun(for: .onDefeat)
        }

        // Delay before showing game over screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.delegate?.battleDidEnd(self, winnerId: winnerId)
        }
    }

    func gameEngine(_ engine: GameEngine, turnTimerDidUpdate remainingSeconds: Int) {
        updateTimer(remainingSeconds)
    }

    func gameEngine(_ engine: GameEngine, turnDidTimeoutFor turnPlayerId: UUID) {
        if turnPlayerId == playerId {
            showTimeoutWarning()
        }
    }
}

// MARK: - Battle Stats View

/// Displays battle statistics between the boards.
final class BattleStatsView: UIView {

    private lazy var playerHitsLabel: UILabel = {
        let label = UILabel()
        label.font = AppTheme.Fonts.monospace()
        label.textColor = AppTheme.Colors.textPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var playerShipsLabel: UILabel = {
        let label = UILabel()
        label.font = AppTheme.Fonts.caption()
        label.textColor = AppTheme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var enemyShipsLabel: UILabel = {
        let label = UILabel()
        label.font = AppTheme.Fonts.caption()
        label.textColor = AppTheme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(playerHitsLabel)
        addSubview(playerShipsLabel)
        addSubview(enemyShipsLabel)

        NSLayoutConstraint.activate([
            playerHitsLabel.topAnchor.constraint(equalTo: topAnchor),
            playerHitsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            playerShipsLabel.topAnchor.constraint(equalTo: playerHitsLabel.bottomAnchor, constant: 4),
            playerShipsLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            playerShipsLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            enemyShipsLabel.topAnchor.constraint(equalTo: playerHitsLabel.bottomAnchor, constant: 4),
            enemyShipsLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            enemyShipsLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func update(playerHits: Int, playerMisses: Int, playerShipsRemaining: Int, enemyHits: Int, enemyShipsRemaining: Int) {
        let totalShots = playerHits + playerMisses
        let accuracy = totalShots > 0 ? Int((Double(playerHits) / Double(totalShots)) * 100) : 0

        playerHitsLabel.text = "Hits: \(playerHits) | Accuracy: \(accuracy)%"
        playerShipsLabel.text = "Your Ships: \(playerShipsRemaining)/5"
        enemyShipsLabel.text = "Enemy Ships: \(enemyShipsRemaining)/5"
    }
}
