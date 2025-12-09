//
//  GameBoardView.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import SpriteKit
import UIKit

/// Delegate for game board interaction events.
/// Mirrors BoardViewDelegate for drop-in replacement.
protocol GameBoardViewDelegate: AnyObject {
    /// Called when a cell is tapped.
    func gameBoardView(_ view: GameBoardView, didTapCellAt coordinate: Coordinate)

    /// Called when a long press begins on a cell.
    func gameBoardView(_ view: GameBoardView, didLongPressAt coordinate: Coordinate)

    /// Called during a drag operation.
    func gameBoardView(_ view: GameBoardView, didDragTo coordinate: Coordinate)

    /// Called when a drag operation ends.
    func gameBoardView(_ view: GameBoardView, didEndDragAt coordinate: Coordinate?)
}

/// Optional delegate methods with default implementations.
extension GameBoardViewDelegate {
    func gameBoardView(_ view: GameBoardView, didLongPressAt coordinate: Coordinate) {}
    func gameBoardView(_ view: GameBoardView, didDragTo coordinate: Coordinate) {}
    func gameBoardView(_ view: GameBoardView, didEndDragAt coordinate: Coordinate?) {}
}

/// A UIView wrapper around GridScene for displaying game boards with SpriteKit.
/// Provides the same interface as BoardView for easy migration.
final class GameBoardView: UIView {

    // MARK: - Types

    /// Display mode for the board.
    enum DisplayMode {
        /// Shows all ships and cell states (player's own board)
        case full
        /// Hides ships, only shows hits and misses (opponent's board)
        case hidden
    }

    // MARK: - Properties

    weak var delegate: GameBoardViewDelegate?

    /// The board data to display.
    var board: Board? {
        didSet {
            gridScene.board = board
        }
    }

    /// Display mode for the board.
    var displayMode: DisplayMode = .full {
        didSet {
            gridScene.showShips = (displayMode == .full)
        }
    }

    /// Cells to highlight (for placement preview).
    var highlightedCells: [Coordinate] = [] {
        didSet {
            gridScene.highlightedCells = highlightedCells
        }
    }

    /// Whether highlighted cells represent valid placement.
    var highlightValid: Bool = true {
        didSet {
            gridScene.highlightValid = highlightValid
        }
    }

    /// Whether user interaction is enabled.
    var interactionEnabled: Bool = true {
        didSet {
            gridScene.interactionEnabled = interactionEnabled
        }
    }

    /// The underlying SKView.
    private let skView: SKView

    /// The grid scene being displayed.
    private let gridScene: GridScene

    // MARK: - Initialization

    override init(frame: CGRect) {
        skView = SKView(frame: .zero)
        gridScene = GridScene()

        super.init(frame: frame)

        setupSKView()
    }

    required init?(coder: NSCoder) {
        skView = SKView(frame: .zero)
        gridScene = GridScene()

        super.init(coder: coder)

        setupSKView()
    }

    // MARK: - Setup

    private func setupSKView() {
        skView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(skView)

        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: topAnchor),
            skView.leadingAnchor.constraint(equalTo: leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Configure SKView
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.backgroundColor = AppTheme.Colors.oceanDeep

        // Set up scene delegate
        gridScene.gridDelegate = self
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Present scene with correct size when view is laid out
        guard bounds.size.width > 0 && bounds.size.height > 0 else { return }

        if gridScene.view == nil {
            // First time setup - use the final bounds
            gridScene.size = bounds.size
            gridScene.scaleMode = .resizeFill
            skView.presentScene(gridScene)
        } else if gridScene.size != bounds.size {
            // Size changed - update scene size
            gridScene.size = bounds.size
        }
    }

    // MARK: - Animation Methods

    /// Animates a hit at the specified coordinate.
    func animateHit(at coordinate: Coordinate, completion: (() -> Void)? = nil) {
        gridScene.playHitEffect(at: coordinate) {
            completion?()
        }
    }

    /// Animates a miss at the specified coordinate.
    func animateMiss(at coordinate: Coordinate, completion: (() -> Void)? = nil) {
        gridScene.playMissEffect(at: coordinate) {
            completion?()
        }
    }

    /// Plays a ship sinking effect.
    func animateSink(shipId: UUID, completion: (() -> Void)? = nil) {
        gridScene.playSinkEffect(for: shipId, completion: completion)
    }
}

// MARK: - GridSceneDelegate

extension GameBoardView: GridSceneDelegate {
    func gridScene(_ scene: GridScene, didTapCellAt coordinate: Coordinate) {
        delegate?.gameBoardView(self, didTapCellAt: coordinate)
    }

    func gridScene(_ scene: GridScene, didLongPressAt coordinate: Coordinate) {
        delegate?.gameBoardView(self, didLongPressAt: coordinate)
    }

    func gridScene(_ scene: GridScene, didHighlightCellAt coordinate: Coordinate?) {
        if let coord = coordinate {
            delegate?.gameBoardView(self, didDragTo: coord)
        } else {
            delegate?.gameBoardView(self, didEndDragAt: nil)
        }
    }
}
