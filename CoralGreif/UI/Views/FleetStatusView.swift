//
//  FleetStatusView.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import UIKit

/// Displays the status of a player's fleet in a grid with ship silhouettes.
final class FleetStatusView: UIView {

    // MARK: - Properties

    /// Top row: Carrier, Battleship, Cruiser
    private lazy var topRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// Bottom row: Submarine, Destroyer
    private lazy var bottomRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var shipCells: [ShipType: ShipGridCell] = [:]

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = AppTheme.Colors.oceanLight.withAlphaComponent(0.3)
        layer.cornerRadius = 8

        addSubview(topRow)
        addSubview(bottomRow)

        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            topRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            topRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            bottomRow.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 8),
            bottomRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            bottomRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            bottomRow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            topRow.heightAnchor.constraint(equalTo: bottomRow.heightAnchor)
        ])

        // Top row: larger ships
        for shipType in [ShipType.carrier, .battleship, .cruiser] {
            let cell = ShipGridCell(shipType: shipType)
            shipCells[shipType] = cell
            topRow.addArrangedSubview(cell)
        }

        // Bottom row: smaller ships (with spacers for centering)
        let leftSpacer = UIView()
        leftSpacer.translatesAutoresizingMaskIntoConstraints = false
        let rightSpacer = UIView()
        rightSpacer.translatesAutoresizingMaskIntoConstraints = false

        bottomRow.addArrangedSubview(leftSpacer)
        for shipType in [ShipType.submarine, .destroyer] {
            let cell = ShipGridCell(shipType: shipType)
            shipCells[shipType] = cell
            bottomRow.addArrangedSubview(cell)
        }
        bottomRow.addArrangedSubview(rightSpacer)

        // Make spacers equal width
        leftSpacer.widthAnchor.constraint(equalTo: rightSpacer.widthAnchor).isActive = true
    }

    // MARK: - Public Methods

    /// Updates the fleet status display based on the current board state.
    func update(with board: Board?) {
        guard let board = board else {
            for cell in shipCells.values {
                cell.update(hits: 0, isSunk: false)
            }
            return
        }

        for ship in board.ships {
            if let cell = shipCells[ship.type] {
                cell.update(hits: ship.hitCount, isSunk: ship.isSunk)
            }
        }
    }
}

// MARK: - Ship Grid Cell

/// A grid cell showing a ship silhouette with damage state.
private final class ShipGridCell: UIView {

    private let shipType: ShipType
    private let shipShapeLayer = CAShapeLayer()

    private lazy var shipContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var healthStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var healthSegments: [UIView] = []

    init(shipType: ShipType) {
        self.shipType = shipType
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateShipPath()
    }

    private func setupUI() {
        addSubview(shipContainer)
        addSubview(healthStack)

        // Set up ship shape layer
        shipShapeLayer.fillColor = AppTheme.Colors.navySteel.cgColor
        shipShapeLayer.strokeColor = AppTheme.Colors.textPrimary.cgColor
        shipShapeLayer.lineWidth = 1
        shipContainer.layer.addSublayer(shipShapeLayer)

        NSLayoutConstraint.activate([
            shipContainer.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            shipContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            shipContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            shipContainer.heightAnchor.constraint(equalToConstant: 28),

            healthStack.topAnchor.constraint(equalTo: shipContainer.bottomAnchor, constant: 4),
            healthStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            healthStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            healthStack.heightAnchor.constraint(equalToConstant: 8),
            healthStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])

        // Create discrete health segments for each hit point
        for _ in 0..<shipType.size {
            let segment = UIView()
            segment.backgroundColor = AppTheme.Colors.validPlacement
            segment.layer.cornerRadius = 2
            healthSegments.append(segment)
            healthStack.addArrangedSubview(segment)
        }
    }

    private func updateShipPath() {
        let bounds = shipContainer.bounds
        guard bounds.width > 0 && bounds.height > 0 else { return }

        let path = ShipPaths.scaledPath(for: shipType, fitting: bounds.size)
        shipShapeLayer.path = path
        shipShapeLayer.frame = bounds
    }

    func update(hits: Int, isSunk: Bool) {
        // Update each health segment
        for (index, segment) in healthSegments.enumerated() {
            if index < hits {
                segment.backgroundColor = AppTheme.Colors.hitRed
            } else {
                segment.backgroundColor = AppTheme.Colors.validPlacement
            }
        }

        // Update ship color based on status
        if isSunk {
            shipShapeLayer.fillColor = AppTheme.Colors.hitRed.withAlphaComponent(0.4).cgColor
            shipShapeLayer.strokeColor = AppTheme.Colors.hitRed.cgColor
            alpha = 0.6
        } else if hits > 0 {
            shipShapeLayer.fillColor = AppTheme.Colors.warningOrange.withAlphaComponent(0.4).cgColor
            shipShapeLayer.strokeColor = AppTheme.Colors.warningOrange.cgColor
            alpha = 1.0
        } else {
            shipShapeLayer.fillColor = AppTheme.Colors.navySteel.cgColor
            shipShapeLayer.strokeColor = AppTheme.Colors.textPrimary.cgColor
            alpha = 1.0
        }
    }
}
