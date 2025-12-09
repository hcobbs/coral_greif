//
//  SetupViewController.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import UIKit

/// Delegate for setup screen events.
protocol SetupDelegate: AnyObject {
    func setupDidComplete(_ viewController: SetupViewController)
    func setupDidCancel(_ viewController: SetupViewController)
}

/// Screen for placing ships before battle.
final class SetupViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: SetupDelegate?

    private let engine: GameEngine
    private let playerId: UUID

    /// Ships remaining to place
    private var shipsToPlace: [ShipType]

    /// Currently selected ship type
    private var selectedShipType: ShipType?

    /// Current placement orientation
    private var currentOrientation: Orientation = .horizontal

    /// Preview coordinate for ship placement
    private var previewOrigin: Coordinate?

    // MARK: - UI Elements

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Deploy Your Fleet"
        label.applyHeadingStyle()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap a ship, then tap the board to place it.\nDouble-tap to rotate."
        label.applyBodyStyle()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var boardView: BoardView = {
        let view = BoardView()
        view.displayMode = .full
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var shipSelector: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var rotateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Rotate", for: .normal)
        button.applySecondaryStyle()
        button.addTarget(self, action: #selector(rotateTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var randomButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Random", for: .normal)
        button.applySecondaryStyle()
        button.addTarget(self, action: #selector(randomTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear", for: .normal)
        button.applySecondaryStyle()
        button.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Battle Stations!", for: .normal)
        button.applyPrimaryStyle()
        button.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retreat", for: .normal)
        button.setTitleColor(AppTheme.Colors.textSecondary, for: .normal)
        button.titleLabel?.font = AppTheme.Fonts.body()
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var shipButtons: [ShipType: UIButton] = [:]

    // MARK: - Initialization

    init(engine: GameEngine, playerId: UUID) {
        self.engine = engine
        self.playerId = playerId
        self.shipsToPlace = FleetConfiguration.standard
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupShipButtons()
        updateBoardView()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.oceanDeep

        view.addSubview(titleLabel)
        view.addSubview(instructionLabel)
        view.addSubview(boardView)
        view.addSubview(shipSelector)
        view.addSubview(rotateButton)
        view.addSubview(randomButton)
        view.addSubview(clearButton)
        view.addSubview(startButton)
        view.addSubview(cancelButton)

        let padding = AppTheme.Layout.padding

        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            titleLabel.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: padding),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            boardView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: padding),
            boardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            boardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            boardView.heightAnchor.constraint(equalTo: boardView.widthAnchor),

            shipSelector.topAnchor.constraint(equalTo: boardView.bottomAnchor, constant: padding),
            shipSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            shipSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            shipSelector.heightAnchor.constraint(equalToConstant: 60),

            rotateButton.topAnchor.constraint(equalTo: shipSelector.bottomAnchor, constant: padding),
            rotateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            randomButton.topAnchor.constraint(equalTo: shipSelector.bottomAnchor, constant: padding),
            randomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            clearButton.topAnchor.constraint(equalTo: shipSelector.bottomAnchor, constant: padding),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            startButton.topAnchor.constraint(equalTo: rotateButton.bottomAnchor, constant: padding * 2),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }

    private func setupShipButtons() {
        for shipType in FleetConfiguration.standard {
            let button = createShipButton(for: shipType)
            shipButtons[shipType] = button
            shipSelector.addArrangedSubview(button)
        }
    }

    private func createShipButton(for shipType: ShipType) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(shipType.abbreviation, for: .normal)
        button.setTitleColor(AppTheme.Colors.textPrimary, for: .normal)
        button.setTitleColor(AppTheme.Colors.textSecondary, for: .disabled)
        button.backgroundColor = AppTheme.Colors.navySteel
        button.layer.cornerRadius = 8
        button.titleLabel?.font = AppTheme.Fonts.caption()
        button.tag = shipType.size
        button.addTarget(self, action: #selector(shipButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    // MARK: - Actions

    @objc private func shipButtonTapped(_ sender: UIButton) {
        // Find the ship type by matching the button
        for (shipType, button) in shipButtons {
            if button == sender && shipsToPlace.contains(shipType) {
                selectShip(shipType)
                return
            }
        }
    }

    @objc private func rotateTapped() {
        currentOrientation = currentOrientation == .horizontal ? .vertical : .horizontal
        updatePreview()
    }

    @objc private func randomTapped() {
        // Clear existing placements
        clearAllShips()

        // Generate random placements
        let ships = ShipPlacer.generateRandomPlacements()
        for ship in ships {
            _ = engine.placeShip(ship, for: playerId)
        }

        shipsToPlace.removeAll()
        selectedShipType = nil
        updateBoardView()
        updateShipButtons()
        updateStartButton()
    }

    @objc private func clearTapped() {
        clearAllShips()
    }

    @objc private func startTapped() {
        delegate?.setupDidComplete(self)
    }

    @objc private func cancelTapped() {
        delegate?.setupDidCancel(self)
    }

    // MARK: - Ship Placement

    private func selectShip(_ shipType: ShipType) {
        selectedShipType = shipType

        // Highlight selected button
        for (type, button) in shipButtons {
            if type == shipType {
                button.layer.borderWidth = 2
                button.layer.borderColor = AppTheme.Colors.brassGold.cgColor
            } else {
                button.layer.borderWidth = 0
            }
        }

        instructionLabel.text = "Tap the board to place \(shipType.displayName)"
    }

    private func placeShip(at origin: Coordinate) {
        guard let shipType = selectedShipType else { return }

        let ship = Ship(type: shipType, origin: origin, orientation: currentOrientation)
        let result = engine.placeShip(ship, for: playerId)

        if case .success = result {
            // Remove from ships to place
            if let index = shipsToPlace.firstIndex(of: shipType) {
                shipsToPlace.remove(at: index)
            }

            selectedShipType = nil
            previewOrigin = nil
            boardView.highlightedCells = []

            updateBoardView()
            updateShipButtons()
            updateStartButton()

            // Auto-select next ship if available
            if let nextShip = shipsToPlace.first {
                selectShip(nextShip)
            } else {
                instructionLabel.text = "Fleet deployed! Ready for battle."
            }
        } else {
            // Invalid placement
            showInvalidPlacementFeedback()
        }
    }

    private func updatePreview() {
        guard let shipType = selectedShipType, let origin = previewOrigin else {
            boardView.highlightedCells = []
            return
        }

        let ship = Ship(type: shipType, origin: origin, orientation: currentOrientation)
        let coordinates = ship.coordinates

        // Check if placement is valid
        let isValid = ship.isValidPlacement() && !hasOverlap(ship: ship)

        boardView.highlightedCells = coordinates
        boardView.highlightValid = isValid
    }

    private func clearAllShips() {
        // Remove all placed ships
        if let board = engine.gameState.board(for: playerId) {
            for ship in board.ships {
                _ = engine.removeShip(id: ship.id, for: playerId)
            }
        }

        shipsToPlace = FleetConfiguration.standard
        selectedShipType = nil
        previewOrigin = nil
        boardView.highlightedCells = []

        updateBoardView()
        updateShipButtons()
        updateStartButton()

        // Auto-select first ship
        if let firstShip = shipsToPlace.first {
            selectShip(firstShip)
        }
    }

    /// Checks if the ship would overlap with existing placements.
    private func hasOverlap(ship: Ship) -> Bool {
        guard let board = engine.gameState.board(for: playerId) else { return false }
        for existingShip in board.ships {
            if ship.overlaps(with: existingShip) {
                return true
            }
        }
        return false
    }

    // MARK: - UI Updates

    private func updateBoardView() {
        boardView.board = engine.gameState.board(for: playerId)
    }

    private func updateShipButtons() {
        for (shipType, button) in shipButtons {
            let isPlaced = !shipsToPlace.contains(shipType)
            button.isEnabled = !isPlaced
            button.alpha = isPlaced ? 0.4 : 1.0
            button.layer.borderWidth = 0
        }
    }

    private func updateStartButton() {
        let canStart = engine.canStartBattle
        startButton.isEnabled = canStart
        startButton.alpha = canStart ? 1.0 : 0.5
    }

    private func showInvalidPlacementFeedback() {
        // Flash red on invalid cells
        boardView.highlightValid = false

        UIView.animate(withDuration: 0.2, animations: {
            self.boardView.alpha = 0.7
        }, completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.boardView.alpha = 1.0
            }
        })
    }
}

// MARK: - BoardViewDelegate

extension SetupViewController: BoardViewDelegate {
    func boardView(_ boardView: BoardView, didTapCellAt coordinate: Coordinate) {
        if selectedShipType != nil {
            placeShip(at: coordinate)
        } else {
            // Tap on placed ship to remove it
            if let board = engine.gameState.board(for: playerId) {
                for ship in board.ships {
                    if ship.coordinates.contains(coordinate) {
                        _ = engine.removeShip(id: ship.id, for: playerId)
                        shipsToPlace.append(ship.type)
                        updateBoardView()
                        updateShipButtons()
                        updateStartButton()
                        selectShip(ship.type)
                        return
                    }
                }
            }
        }
    }

    func boardView(_ boardView: BoardView, didLongPressAt coordinate: Coordinate) {
        previewOrigin = coordinate
        updatePreview()
    }

    func boardView(_ boardView: BoardView, didDragTo coordinate: Coordinate) {
        previewOrigin = coordinate
        updatePreview()
    }

    func boardView(_ boardView: BoardView, didEndDragAt coordinate: Coordinate?) {
        if let coord = coordinate, selectedShipType != nil {
            placeShip(at: coord)
        }
        previewOrigin = nil
        boardView.highlightedCells = []
    }
}

// MARK: - ShipType Extension

private extension ShipType {
    var abbreviation: String {
        switch self {
        case .carrier: return "CV"
        case .battleship: return "BB"
        case .cruiser: return "CA"
        case .submarine: return "SS"
        case .destroyer: return "DD"
        }
    }
}
