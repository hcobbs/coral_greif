//
//  GridScene.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import SpriteKit

/// Delegate for grid interaction events.
protocol GridSceneDelegate: AnyObject {
    /// Called when a cell is tapped.
    func gridScene(_ scene: GridScene, didTapCellAt coordinate: Coordinate)

    /// Called when a long press begins on a cell.
    func gridScene(_ scene: GridScene, didLongPressAt coordinate: Coordinate)

    /// Called when a cell is highlighted during drag.
    func gridScene(_ scene: GridScene, didHighlightCellAt coordinate: Coordinate?)
}

/// A SpriteKit scene that renders a 10x10 game grid.
final class GridScene: SKScene {

    // MARK: - Properties

    weak var gridDelegate: GridSceneDelegate?

    /// The board data to display.
    var board: Board? {
        didSet { updateGridDisplay() }
    }

    /// Whether to show ships on this grid.
    var showShips: Bool = true {
        didSet { updateGridDisplay() }
    }

    /// Whether user interaction is enabled.
    var interactionEnabled: Bool = true

    /// Cells to highlight (for placement preview).
    var highlightedCells: [Coordinate] = [] {
        didSet { updateHighlights() }
    }

    /// Whether highlighted cells represent valid placement.
    var highlightValid: Bool = true {
        didSet { updateHighlights() }
    }

    /// The size of each cell in points.
    private var cellSize: CGFloat = 0

    /// Container for grid cells.
    private let gridContainer = SKNode()

    /// Container for ships.
    private let shipContainer = SKNode()

    /// Container for markers (hits/misses).
    private let markerContainer = SKNode()

    /// Container for effects.
    private let effectContainer = SKNode()

    /// Container for highlights.
    private let highlightContainer = SKNode()

    /// Grid cell nodes indexed by coordinate.
    private var cellNodes: [Coordinate: SKShapeNode] = [:]

    /// Ship sprites indexed by ship ID.
    private var shipSprites: [UUID: ShipSprite] = [:]

    /// Currently highlighted cell.
    private var currentHighlight: Coordinate?

    /// Track if scene has been set up
    private var isSetUp = false

    /// Track if gestures have been set up
    private var gesturesSetUp = false

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        if !gesturesSetUp {
            setupGestureRecognizers()
            gesturesSetUp = true
        }
        // Only set up scene if we have a valid size
        if size.width > 10 && size.height > 10 {
            setupScene()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        // Set up or rebuild when we get a valid size
        guard size.width > 10 && size.height > 10 else { return }

        if !isSetUp {
            setupScene()
        } else if size != oldSize {
            rebuildGrid()
        }
    }

    // MARK: - Setup

    private func setupScene() {
        guard !isSetUp else { return }
        guard size.width > 10 && size.height > 10 else { return }
        isSetUp = true

        backgroundColor = AppTheme.Colors.oceanDeep

        // Calculate cell size based on scene size
        let boardSize = min(size.width, size.height) * 0.95
        cellSize = boardSize / CGFloat(Coordinate.boardSize)

        // Center the grid
        let gridOrigin = CGPoint(
            x: (size.width - boardSize) / 2,
            y: (size.height - boardSize) / 2
        )
        gridContainer.position = gridOrigin

        // Add containers in z-order
        addChild(gridContainer)
        gridContainer.addChild(shipContainer)
        gridContainer.addChild(highlightContainer)
        gridContainer.addChild(markerContainer)
        gridContainer.addChild(effectContainer)

        // Build the grid
        buildGrid()
    }

    /// Rebuilds the grid when size changes.
    private func rebuildGrid() {
        // Clear existing nodes from containers first
        shipContainer.removeAllChildren()
        markerContainer.removeAllChildren()
        highlightContainer.removeAllChildren()
        effectContainer.removeAllChildren()

        // Clear grid container (removes cells and the containers)
        gridContainer.removeAllChildren()
        cellNodes.removeAll()
        shipSprites.removeAll()

        // Re-add containers
        gridContainer.addChild(shipContainer)
        gridContainer.addChild(highlightContainer)
        gridContainer.addChild(markerContainer)
        gridContainer.addChild(effectContainer)

        // Recalculate cell size
        let boardSize = min(size.width, size.height) * 0.95
        cellSize = boardSize / CGFloat(Coordinate.boardSize)

        // Center the grid
        let gridOrigin = CGPoint(
            x: (size.width - boardSize) / 2,
            y: (size.height - boardSize) / 2
        )
        gridContainer.position = gridOrigin

        // Rebuild
        buildGrid()
        updateGridDisplay()
    }

    private func buildGrid() {
        // Create background
        let boardWidth = cellSize * CGFloat(Coordinate.boardSize)
        let background = SKShapeNode(rectOf: CGSize(width: boardWidth, height: boardWidth))
        background.position = CGPoint(x: boardWidth / 2, y: boardWidth / 2)
        background.fillColor = AppTheme.Colors.oceanLight
        background.strokeColor = .clear
        background.zPosition = -1
        gridContainer.addChild(background)

        // Create cells
        for row in 0..<Coordinate.boardSize {
            for col in 0..<Coordinate.boardSize {
                guard let coord = Coordinate(row: row, column: col) else { continue }
                let cell = createCellNode(at: coord)
                cellNodes[coord] = cell
                gridContainer.addChild(cell)
            }
        }

        // Draw grid lines
        drawGridLines()

        // Add coordinate labels
        addCoordinateLabels()
    }

    private func createCellNode(at coordinate: Coordinate) -> SKShapeNode {
        let rect = CGRect(
            x: CGFloat(coordinate.column) * cellSize,
            y: CGFloat(Coordinate.boardSize - 1 - coordinate.row) * cellSize,
            width: cellSize,
            height: cellSize
        )

        let node = SKShapeNode(rect: rect)
        node.fillColor = AppTheme.Colors.oceanLight
        node.strokeColor = .clear
        node.name = "cell_\(coordinate.column)_\(coordinate.row)"
        node.zPosition = 0

        return node
    }

    private func drawGridLines() {
        let lineColor = AppTheme.Colors.gridLine
        let boardWidth = cellSize * CGFloat(Coordinate.boardSize)

        // Vertical lines
        for i in 0...Coordinate.boardSize {
            let x = CGFloat(i) * cellSize
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: boardWidth))
            line.path = path
            line.strokeColor = lineColor
            line.lineWidth = 1
            line.zPosition = 5
            gridContainer.addChild(line)
        }

        // Horizontal lines
        for i in 0...Coordinate.boardSize {
            let y = CGFloat(i) * cellSize
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: boardWidth, y: y))
            line.path = path
            line.strokeColor = lineColor
            line.lineWidth = 1
            line.zPosition = 5
            gridContainer.addChild(line)
        }
    }

    private func addCoordinateLabels() {
        let labelFont = AppTheme.Fonts.caption()
        let labelColor = AppTheme.Colors.textSecondary

        // Column labels (A-J) at bottom
        for col in 0..<Coordinate.boardSize {
            let label = SKLabelNode(fontNamed: labelFont.fontName)
            label.text = String(UnicodeScalar(65 + col)!)  // A-J
            label.fontSize = labelFont.pointSize
            label.fontColor = labelColor
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .top
            label.position = CGPoint(
                x: (CGFloat(col) + 0.5) * cellSize,
                y: -8
            )
            label.zPosition = 10
            gridContainer.addChild(label)
        }

        // Row labels (1-10) at left
        for row in 0..<Coordinate.boardSize {
            let label = SKLabelNode(fontNamed: labelFont.fontName)
            label.text = "\(row + 1)"
            label.fontSize = labelFont.pointSize
            label.fontColor = labelColor
            label.horizontalAlignmentMode = .right
            label.verticalAlignmentMode = .center
            label.position = CGPoint(
                x: -8,
                y: (CGFloat(Coordinate.boardSize - 1 - row) + 0.5) * cellSize
            )
            label.zPosition = 10
            gridContainer.addChild(label)
        }
    }

    private func setupGestureRecognizers() {
        guard let view = view else { return }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        view.addGestureRecognizer(longPress)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    // MARK: - Display Updates

    private func updateGridDisplay() {
        guard let board = board else { return }

        // Update cell colors
        for row in 0..<Coordinate.boardSize {
            for col in 0..<Coordinate.boardSize {
                guard let coord = Coordinate(row: row, column: col),
                      let cellNode = cellNodes[coord] else { continue }

                let cell = board.cell(at: coord)
                updateCellNode(cellNode, for: cell)
            }
        }

        // Update ships
        updateShipDisplay()

        // Update markers
        updateMarkers()
    }

    private func updateCellNode(_ node: SKShapeNode, for cell: Cell) {
        switch cell.state {
        case .empty:
            node.fillColor = AppTheme.Colors.oceanLight
        case .ship:
            if showShips {
                node.fillColor = AppTheme.Colors.navySteel.withAlphaComponent(0.3)
            } else {
                node.fillColor = AppTheme.Colors.oceanLight
            }
        case .hit:
            node.fillColor = AppTheme.Colors.hitRed.withAlphaComponent(0.4)
        case .miss:
            node.fillColor = AppTheme.Colors.oceanLight
        }
    }

    private func updateShipDisplay() {
        guard let board = board, showShips else {
            shipContainer.removeAllChildren()
            shipSprites.removeAll()
            return
        }

        // Remove sprites for ships no longer on board
        for (shipId, sprite) in shipSprites {
            if board.ship(withId: shipId) == nil {
                sprite.removeFromParent()
                shipSprites.removeValue(forKey: shipId)
            }
        }

        // Add or update sprites for ships on board
        for ship in board.ships {
            if let existingSprite = shipSprites[ship.id] {
                // Update existing sprite damage state
                let newHitCount = ship.hitCount
                while existingSprite.hitCount < newHitCount {
                    existingSprite.recordHit()
                }
            } else {
                // Create new sprite
                let sprite = ShipSprite(
                    shipType: ship.type,
                    orientation: ship.orientation,
                    cellSize: cellSize
                )
                sprite.position = positionForShip(ship)
                sprite.zPosition = 2
                shipContainer.addChild(sprite)
                shipSprites[ship.id] = sprite
            }
        }
    }

    private func positionForShip(_ ship: Ship) -> CGPoint {
        let origin = ship.origin
        let shipLength = CGFloat(ship.type.size) * cellSize
        let halfCell = cellSize / 2

        // Convert to scene coordinates (y-flipped)
        let baseX = CGFloat(origin.column) * cellSize
        let baseY = CGFloat(Coordinate.boardSize - 1 - origin.row) * cellSize

        if ship.orientation == .horizontal {
            return CGPoint(
                x: baseX + shipLength / 2,
                y: baseY + halfCell
            )
        } else {
            return CGPoint(
                x: baseX + halfCell,
                y: baseY - shipLength / 2 + cellSize
            )
        }
    }

    private func updateMarkers() {
        markerContainer.removeAllChildren()

        guard let board = board else { return }

        for row in 0..<Coordinate.boardSize {
            for col in 0..<Coordinate.boardSize {
                guard let coord = Coordinate(row: row, column: col) else { continue }
                let cell = board.cell(at: coord)

                switch cell.state {
                case .hit:
                    if let marker = SymbolSprites.hitMarker(size: cellSize * 0.6) {
                        marker.position = centerOfCell(at: coord)
                        marker.zPosition = 20
                        markerContainer.addChild(marker)
                    }
                case .miss:
                    if let marker = SymbolSprites.missMarker(size: cellSize * 0.4) {
                        marker.position = centerOfCell(at: coord)
                        marker.zPosition = 20
                        markerContainer.addChild(marker)
                    }
                default:
                    break
                }
            }
        }
    }

    private func updateHighlights() {
        highlightContainer.removeAllChildren()

        let color = highlightValid ?
            AppTheme.Colors.validPlacement :
            AppTheme.Colors.invalidPlacement

        for coord in highlightedCells {
            let rect = CGRect(
                x: CGFloat(coord.column) * cellSize,
                y: CGFloat(Coordinate.boardSize - 1 - coord.row) * cellSize,
                width: cellSize,
                height: cellSize
            )
            let highlight = SKShapeNode(rect: rect)
            highlight.fillColor = color
            highlight.strokeColor = .clear
            highlight.zPosition = 15
            highlightContainer.addChild(highlight)
        }
    }

    // MARK: - Coordinate Conversion

    private func centerOfCell(at coordinate: Coordinate) -> CGPoint {
        return CGPoint(
            x: (CGFloat(coordinate.column) + 0.5) * cellSize,
            y: (CGFloat(Coordinate.boardSize - 1 - coordinate.row) + 0.5) * cellSize
        )
    }

    private func coordinateForPoint(_ point: CGPoint) -> Coordinate? {
        // Convert from scene coordinates to grid coordinates
        let localPoint = gridContainer.convert(point, from: self)

        let col = Int(localPoint.x / cellSize)
        let row = Coordinate.boardSize - 1 - Int(localPoint.y / cellSize)

        return Coordinate(row: row, column: col)
    }

    // MARK: - Effects

    /// Plays a hit effect at the specified coordinate.
    func playHitEffect(at coordinate: Coordinate, completion: (() -> Void)? = nil) {
        let position = centerOfCell(at: coordinate)
        ParticleEffects.playExplosion(at: position, in: effectContainer, completion: completion)
    }

    /// Plays a miss effect at the specified coordinate.
    func playMissEffect(at coordinate: Coordinate, completion: (() -> Void)? = nil) {
        let position = centerOfCell(at: coordinate)
        ParticleEffects.playSplash(at: position, in: effectContainer, completion: completion)
    }

    /// Plays a ship sinking effect.
    func playSinkEffect(for shipId: UUID, completion: (() -> Void)? = nil) {
        guard let sprite = shipSprites[shipId] else {
            completion?()
            return
        }

        sprite.playSinkAnimation {
            completion?()
        }
    }

    // MARK: - Gesture Handlers

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard interactionEnabled, let view = view else { return }

        let viewPoint = gesture.location(in: view)
        let scenePoint = convertPoint(fromView: viewPoint)

        if let coord = coordinateForPoint(scenePoint) {
            gridDelegate?.gridScene(self, didTapCellAt: coord)
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard interactionEnabled, let view = view else { return }

        if gesture.state == .began {
            let viewPoint = gesture.location(in: view)
            let scenePoint = convertPoint(fromView: viewPoint)

            if let coord = coordinateForPoint(scenePoint) {
                gridDelegate?.gridScene(self, didLongPressAt: coord)
            }
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard interactionEnabled, let view = view else { return }

        let viewPoint = gesture.location(in: view)
        let scenePoint = convertPoint(fromView: viewPoint)
        let coord = coordinateForPoint(scenePoint)

        switch gesture.state {
        case .changed:
            if coord != currentHighlight {
                currentHighlight = coord
                gridDelegate?.gridScene(self, didHighlightCellAt: coord)
            }
        case .ended, .cancelled:
            currentHighlight = nil
            gridDelegate?.gridScene(self, didHighlightCellAt: nil)
        default:
            break
        }
    }
}
