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
    private let soundManager = SoundManager.shared

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

    private lazy var timerView: CircularTimerView = {
        let view = CircularTimerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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

    private lazy var enemyBoardView: GameBoardView = {
        let view = GameBoardView()
        view.displayMode = .hidden
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var fleetStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "Your Fleet Status"
        label.font = AppTheme.Fonts.caption()
        label.textColor = AppTheme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var fleetStatusView: FleetStatusView = {
        let view = FleetStatusView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var forfeitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Surrender", for: .normal)
        button.applySecondaryStyle()
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

        view.addSubview(timerView)
        view.addSubview(turnLabel)
        view.addSubview(punLabel)
        view.addSubview(enemyBoardLabel)
        view.addSubview(enemyBoardView)
        view.addSubview(statsView)
        view.addSubview(fleetStatusLabel)
        view.addSubview(fleetStatusView)
        view.addSubview(forfeitButton)

        let padding = AppTheme.Layout.padding
        let smallPadding = AppTheme.Layout.paddingSmall

        NSLayoutConstraint.activate([
            // Timer in upper right
            timerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: smallPadding),
            timerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            timerView.widthAnchor.constraint(equalToConstant: 44),
            timerView.heightAnchor.constraint(equalToConstant: 44),

            // Turn label on the left, with space for timer
            turnLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: smallPadding),
            turnLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            turnLabel.trailingAnchor.constraint(lessThanOrEqualTo: timerView.leadingAnchor, constant: -padding),

            // Pun below turn label
            punLabel.topAnchor.constraint(equalTo: turnLabel.bottomAnchor, constant: smallPadding),
            punLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            punLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            enemyBoardLabel.topAnchor.constraint(equalTo: punLabel.bottomAnchor, constant: smallPadding),
            enemyBoardLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            enemyBoardView.topAnchor.constraint(equalTo: enemyBoardLabel.bottomAnchor, constant: smallPadding),
            enemyBoardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            enemyBoardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            enemyBoardView.heightAnchor.constraint(equalTo: enemyBoardView.widthAnchor),

            statsView.topAnchor.constraint(equalTo: enemyBoardView.bottomAnchor, constant: smallPadding),
            statsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            statsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            fleetStatusLabel.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: smallPadding),
            fleetStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            fleetStatusView.topAnchor.constraint(equalTo: fleetStatusLabel.bottomAnchor, constant: smallPadding),
            fleetStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            fleetStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            forfeitButton.topAnchor.constraint(equalTo: fleetStatusView.bottomAnchor, constant: smallPadding),
            forfeitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            forfeitButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -smallPadding)
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
        if isPlayer {
            // Player attacked enemy - animate on enemy board
            switch result {
            case .miss:
                soundManager.playGameEvent(.miss)
                enemyBoardView.animateMiss(at: coordinate) { [weak self] in
                    self?.showPun(for: .onMiss)
                }

            case .hit:
                soundManager.playGameEvent(.hit)
                enemyBoardView.animateHit(at: coordinate) { [weak self] in
                    self?.showPun(for: .onHit)
                }

            case .sunk(let shipType):
                soundManager.playGameEvent(.sunk(shipType))
                enemyBoardView.animateHit(at: coordinate) { [weak self] in
                    self?.showSunkMessage(shipType: shipType, byPlayer: isPlayer)
                }
            }
        } else {
            // Enemy attacked player - just play sound and show pun (fleet status updates automatically)
            switch result {
            case .miss:
                soundManager.playGameEvent(.miss)
                showPun(for: .onMiss)

            case .hit:
                soundManager.playGameEvent(.hit)
                showPun(for: .onGettingHit)

            case .sunk(let shipType):
                soundManager.playGameEvent(.sunk(shipType))
                showSunkMessage(shipType: shipType, byPlayer: isPlayer)
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
        fleetStatusView.update(with: engine.gameState.board(for: playerId))
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
        let progress = CGFloat(seconds) / CGFloat(engine.turnDuration)
        timerView.setProgress(progress, warning: seconds <= 5)
    }

    // MARK: - Feedback

    private func showStartPun() {
        soundManager.playGameEvent(.gameStart)
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
        soundManager.playGameEvent(.invalidAction)
        punLabel.text = "Already fired there, Captain!"
    }

    private func showTimeoutWarning() {
        soundManager.playGameEvent(.turnTimeout)
        punLabel.text = punGenerator.pun(for: .onTimeout)
        punLabel.textColor = AppTheme.Colors.warningOrange

        UIView.animate(withDuration: 0.5) {
            self.punLabel.textColor = AppTheme.Colors.textSecondary
        }
    }
}

// MARK: - GameBoardViewDelegate

extension BattleViewController: GameBoardViewDelegate {
    func gameBoardView(_ view: GameBoardView, didTapCellAt coordinate: Coordinate) {
        guard view == enemyBoardView && canInteract else { return }
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
            showTurnTransition(isPlayerTurn: true)
        } else {
            punLabel.text = "Enemy is targeting..."
            showTurnTransition(isPlayerTurn: false)
        }
    }

    private func showTurnTransition(isPlayerTurn: Bool) {
        // Create overlay
        let overlay = UIView()
        overlay.backgroundColor = AppTheme.Colors.oceanDeep.withAlphaComponent(0.9)
        overlay.alpha = 0
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)

        // Turn label
        let label = UILabel()
        label.text = isPlayerTurn ? "Your Turn" : "Enemy Turn"
        label.font = AppTheme.Fonts.title()
        label.textColor = isPlayerTurn ? AppTheme.Colors.brassGold : AppTheme.Colors.hitRed
        label.textAlignment = .center
        label.alpha = 0
        label.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(label)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])

        // Animate in
        UIView.animate(withDuration: 0.2, animations: {
            overlay.alpha = 1
            label.alpha = 1
            label.transform = .identity
        }) { _ in
            // Hold
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                // Animate out
                UIView.animate(withDuration: 0.2, animations: {
                    overlay.alpha = 0
                    label.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }) { _ in
                    overlay.removeFromSuperview()
                }
            }
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
        // Show appropriate pun and play sound
        if winnerId == playerId {
            soundManager.playGameEvent(.victory)
            punLabel.text = punGenerator.pun(for: .onVictory)
        } else {
            soundManager.playGameEvent(.defeat)
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

// MARK: - Circular Timer View

/// A circular countdown timer that shows progress as an arc.
final class CircularTimerView: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private let trackColor = AppTheme.Colors.navySteel.withAlphaComponent(0.3)
    private let normalColor = AppTheme.Colors.brassGold
    private let warningColor = AppTheme.Colors.warningOrange

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePaths()
    }

    private func setupLayers() {
        // Track layer (background circle)
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = 4
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        // Progress layer (foreground arc)
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = normalColor.cgColor
        progressLayer.lineWidth = 4
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 1.0
        layer.addSublayer(progressLayer)
    }

    private func updatePaths() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 4

        // Start from top (12 o'clock) and go clockwise
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }

    /// Sets the timer progress.
    /// - Parameters:
    ///   - progress: Value from 0.0 (empty) to 1.0 (full)
    ///   - warning: Whether to show warning color
    func setProgress(_ progress: CGFloat, warning: Bool) {
        progressLayer.strokeEnd = max(0, min(1, progress))
        progressLayer.strokeColor = warning ? warningColor.cgColor : normalColor.cgColor
    }
}
