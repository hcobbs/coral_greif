//
//  BoardView.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import UIKit

/// Delegate for board interaction events.
protocol BoardViewDelegate: AnyObject {
    /// Called when a cell is tapped.
    func boardView(_ boardView: BoardView, didTapCellAt coordinate: Coordinate)

    /// Called when a long press begins on a cell.
    func boardView(_ boardView: BoardView, didLongPressAt coordinate: Coordinate)

    /// Called during a drag operation.
    func boardView(_ boardView: BoardView, didDragTo coordinate: Coordinate)

    /// Called when a drag operation ends.
    func boardView(_ boardView: BoardView, didEndDragAt coordinate: Coordinate?)
}

/// Optional delegate methods
extension BoardViewDelegate {
    func boardView(_ boardView: BoardView, didLongPressAt coordinate: Coordinate) {}
    func boardView(_ boardView: BoardView, didDragTo coordinate: Coordinate) {}
    func boardView(_ boardView: BoardView, didEndDragAt coordinate: Coordinate?) {}
}

/// A view that displays a 10x10 game board grid.
final class BoardView: UIView {

    // MARK: - Types

    /// Display mode for the board
    enum DisplayMode {
        /// Shows all ships and cell states (player's own board)
        case full
        /// Hides ships, only shows hits and misses (opponent's board)
        case hidden
    }

    // MARK: - Properties

    weak var delegate: BoardViewDelegate?

    /// The board data to display
    var board: Board? {
        didSet { setNeedsDisplay() }
    }

    /// Display mode for the board
    var displayMode: DisplayMode = .full {
        didSet { setNeedsDisplay() }
    }

    /// Cells to highlight (for placement preview)
    var highlightedCells: [Coordinate] = [] {
        didSet { setNeedsDisplay() }
    }

    /// Whether highlighted cells represent valid placement
    var highlightValid: Bool = true {
        didSet { setNeedsDisplay() }
    }

    /// Whether user interaction is enabled
    var interactionEnabled: Bool = true

    /// Calculated cell size
    private var cellSize: CGFloat {
        return bounds.width / CGFloat(Coordinate.boardSize)
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
        backgroundColor = AppTheme.Colors.oceanDeep
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
        backgroundColor = AppTheme.Colors.oceanDeep
    }

    // MARK: - Setup

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        addGestureRecognizer(longPress)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        drawGrid(in: context)
        drawCells(in: context)
        drawHighlights(in: context)
        drawGridLines(in: context)
        drawLabels(in: context)
    }

    private func drawGrid(in context: CGContext) {
        // Fill background
        context.setFillColor(AppTheme.Colors.oceanLight.cgColor)
        context.fill(bounds)
    }

    private func drawCells(in context: CGContext) {
        guard let board = board else { return }

        for row in 0..<Coordinate.boardSize {
            for col in 0..<Coordinate.boardSize {
                guard let coord = Coordinate(row: row, column: col) else { continue }
                let cell = board.cell(at: coord)
                let cellRect = rectForCell(at: coord)

                drawCell(cell, at: cellRect, in: context)
            }
        }
    }

    private func drawCell(_ cell: Cell, at rect: CGRect, in context: CGContext) {
        let insetRect = rect.insetBy(dx: 1, dy: 1)

        switch cell.state {
        case .empty:
            // Draw water
            context.setFillColor(AppTheme.Colors.oceanLight.cgColor)
            context.fill(insetRect)

        case .ship:
            if displayMode == .full {
                // Draw ship segment
                context.setFillColor(AppTheme.Colors.navySteel.cgColor)
                context.fill(insetRect)
            } else {
                // Hidden mode: show as water
                context.setFillColor(AppTheme.Colors.oceanLight.cgColor)
                context.fill(insetRect)
            }

        case .hit:
            // Draw hit marker
            context.setFillColor(AppTheme.Colors.hitRed.cgColor)
            context.fill(insetRect)

            // Draw X marker
            drawHitMarker(in: insetRect, context: context)

        case .miss:
            // Draw miss marker
            context.setFillColor(AppTheme.Colors.oceanLight.cgColor)
            context.fill(insetRect)

            // Draw circle marker
            drawMissMarker(in: insetRect, context: context)

        }
    }

    private func drawHitMarker(in rect: CGRect, context: CGContext) {
        let inset = rect.width * 0.25
        let markerRect = rect.insetBy(dx: inset, dy: inset)

        context.setStrokeColor(AppTheme.Colors.textPrimary.cgColor)
        context.setLineWidth(3)

        // Draw X
        context.move(to: CGPoint(x: markerRect.minX, y: markerRect.minY))
        context.addLine(to: CGPoint(x: markerRect.maxX, y: markerRect.maxY))
        context.move(to: CGPoint(x: markerRect.maxX, y: markerRect.minY))
        context.addLine(to: CGPoint(x: markerRect.minX, y: markerRect.maxY))
        context.strokePath()
    }

    private func drawMissMarker(in rect: CGRect, context: CGContext) {
        let inset = rect.width * 0.35
        let markerRect = rect.insetBy(dx: inset, dy: inset)

        context.setFillColor(AppTheme.Colors.missWhite.cgColor)
        context.fillEllipse(in: markerRect)
    }

    private func drawHighlights(in context: CGContext) {
        guard !highlightedCells.isEmpty else { return }

        let color = highlightValid ?
            AppTheme.Colors.validPlacement.cgColor :
            AppTheme.Colors.invalidPlacement.cgColor

        context.setFillColor(color)

        for coord in highlightedCells {
            let rect = rectForCell(at: coord)
            context.fill(rect)
        }
    }

    private func drawGridLines(in context: CGContext) {
        context.setStrokeColor(AppTheme.Colors.gridLine.cgColor)
        context.setLineWidth(AppTheme.Layout.gridLineWidth)

        // Vertical lines
        for i in 0...Coordinate.boardSize {
            let x = CGFloat(i) * cellSize
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: bounds.height))
        }

        // Horizontal lines
        for i in 0...Coordinate.boardSize {
            let y = CGFloat(i) * cellSize
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: bounds.width, y: y))
        }

        context.strokePath()
    }

    private func drawLabels(in context: CGContext) {
        // Column labels (A-J) are drawn above the board
        // Row labels (1-10) are drawn to the left of the board
        // These would be in a containing view, not here
    }

    // MARK: - Coordinate Conversion

    private func rectForCell(at coordinate: Coordinate) -> CGRect {
        let x = CGFloat(coordinate.column) * cellSize
        let y = CGFloat(coordinate.row) * cellSize
        return CGRect(x: x, y: y, width: cellSize, height: cellSize)
    }

    /// Converts a point in the view to a board coordinate.
    func coordinate(for point: CGPoint) -> Coordinate? {
        let col = Int(point.x / cellSize)
        let row = Int(point.y / cellSize)
        return Coordinate(row: row, column: col)
    }

    // MARK: - Gesture Handlers

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard interactionEnabled else { return }

        let point = gesture.location(in: self)
        guard let coord = coordinate(for: point) else { return }

        delegate?.boardView(self, didTapCellAt: coord)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard interactionEnabled else { return }

        let point = gesture.location(in: self)
        guard let coord = coordinate(for: point) else { return }

        if gesture.state == .began {
            delegate?.boardView(self, didLongPressAt: coord)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard interactionEnabled else { return }

        let point = gesture.location(in: self)
        let coord = coordinate(for: point)

        switch gesture.state {
        case .changed:
            if let coord = coord {
                delegate?.boardView(self, didDragTo: coord)
            }
        case .ended, .cancelled:
            delegate?.boardView(self, didEndDragAt: coord)
        default:
            break
        }
    }

    // MARK: - Animation

    /// Animates a hit at the specified coordinate.
    func animateHit(at coordinate: Coordinate, completion: (() -> Void)? = nil) {
        let rect = rectForCell(at: coordinate)
        let flash = UIView(frame: rect)
        flash.backgroundColor = AppTheme.Colors.hitRed
        flash.alpha = 0
        addSubview(flash)

        UIView.animate(withDuration: 0.15, animations: {
            flash.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.15, animations: {
                flash.alpha = 0
            }, completion: { _ in
                flash.removeFromSuperview()
                self.setNeedsDisplay()
                completion?()
            })
        })
    }

    /// Animates a miss at the specified coordinate.
    func animateMiss(at coordinate: Coordinate, completion: (() -> Void)? = nil) {
        let rect = rectForCell(at: coordinate)
        let splash = UIView(frame: rect)
        splash.backgroundColor = AppTheme.Colors.missWhite.withAlphaComponent(0.5)
        splash.alpha = 0
        addSubview(splash)

        UIView.animate(withDuration: 0.2, animations: {
            splash.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, animations: {
                splash.alpha = 0
            }, completion: { _ in
                splash.removeFromSuperview()
                self.setNeedsDisplay()
                completion?()
            })
        })
    }
}
