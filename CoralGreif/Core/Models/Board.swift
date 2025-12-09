import Foundation

/// Represents a player's game board with a 10x10 grid and ship placements.
struct Board: Equatable, Sendable {
    /// The 10x10 grid of cells.
    private(set) var grid: [[Cell]]

    /// Ships placed on this board.
    private(set) var ships: [Ship]

    /// Creates a new empty board.
    init() {
        var grid: [[Cell]] = []
        for row in 0..<Coordinate.boardSize {
            var rowCells: [Cell] = []
            for column in 0..<Coordinate.boardSize {
                let coord = Coordinate(uncheckedRow: row, column: column)
                rowCells.append(Cell(coordinate: coord))
            }
            grid.append(rowCells)
        }
        self.grid = grid
        self.ships = []
    }

    // MARK: - Cell Access

    /// Gets the cell at the given coordinate.
    /// - Parameter coordinate: The coordinate to look up
    /// - Returns: The cell at that coordinate
    func cell(at coordinate: Coordinate) -> Cell {
        return grid[coordinate.row][coordinate.column]
    }

    /// Gets the cell at the given coordinate (mutable).
    private mutating func mutableCell(at coordinate: Coordinate) -> Cell {
        return grid[coordinate.row][coordinate.column]
    }

    /// Updates a cell at the given coordinate.
    private mutating func updateCell(at coordinate: Coordinate, with cell: Cell) {
        grid[coordinate.row][coordinate.column] = cell
    }

    // MARK: - Ship Placement

    /// Places a ship on the board.
    /// - Parameter ship: The ship to place
    /// - Returns: Result indicating success or the error that occurred
    mutating func placeShip(_ ship: Ship) -> Result<Void, BoardError> {
        // Validate ship placement is within bounds
        guard ship.isValidPlacement() else {
            return .failure(.shipOutOfBounds)
        }

        // Check for overlaps with existing ships
        for existingShip in ships {
            if ship.overlaps(with: existingShip) {
                return .failure(.shipOverlap)
            }
        }

        // Place ship on grid
        for coordinate in ship.coordinates {
            var cell = grid[coordinate.row][coordinate.column]
            let result = cell.placeShip(id: ship.id)
            if case .failure = result {
                return .failure(.cellOccupied)
            }
            updateCell(at: coordinate, with: cell)
        }

        ships.append(ship)
        return .success(())
    }

    /// Removes a ship from the board.
    /// - Parameter shipId: The ID of the ship to remove
    /// - Returns: Result indicating success or failure
    mutating func removeShip(id shipId: UUID) -> Result<Ship, BoardError> {
        guard let index = ships.firstIndex(where: { $0.id == shipId }) else {
            return .failure(.shipNotFound)
        }

        let ship = ships[index]

        // Clear ship from grid
        for coordinate in ship.coordinates {
            var cell = grid[coordinate.row][coordinate.column]
            cell.removeShip()
            updateCell(at: coordinate, with: cell)
        }

        ships.remove(at: index)
        return .success(ship)
    }

    /// Removes all ships from the board.
    mutating func clearAllShips() {
        for ship in ships {
            for coordinate in ship.coordinates {
                var cell = grid[coordinate.row][coordinate.column]
                cell.removeShip()
                updateCell(at: coordinate, with: cell)
            }
        }
        ships.removeAll()
    }

    // MARK: - Attack Handling

    /// Receives an attack at the given coordinate.
    /// - Parameter coordinate: The coordinate being attacked
    /// - Returns: The result of the attack
    mutating func receiveAttack(at coordinate: Coordinate) -> Result<AttackResult, BoardError> {
        var cell = grid[coordinate.row][coordinate.column]

        // Try to attack the cell
        let cellResult = cell.receiveAttack()
        switch cellResult {
        case .failure(let error):
            if error == .alreadyAttacked {
                return .failure(.alreadyAttacked)
            }
            return .failure(.invalidAttack)

        case .success(let outcome):
            updateCell(at: coordinate, with: cell)

            switch outcome {
            case .miss:
                return .success(.miss)

            case .hit:
                // Find which ship was hit and record it
                if let shipIndex = ships.firstIndex(where: { $0.occupies(coordinate) }) {
                    var ship = ships[shipIndex]
                    _ = ship.recordHit(at: coordinate)
                    ships[shipIndex] = ship

                    if ship.isSunk {
                        return .success(.sunk(ship.type))
                    } else {
                        return .success(.hit)
                    }
                }
                return .success(.hit)
            }
        }
    }

    // MARK: - Query Methods

    /// Whether all ships on this board have been sunk.
    var allShipsSunk: Bool {
        guard !ships.isEmpty else { return false }
        return ships.allSatisfy { $0.isSunk }
    }

    /// The number of ships still afloat.
    var shipsRemaining: Int {
        return ships.filter { !$0.isSunk }.count
    }

    /// The number of ships that have been sunk.
    var shipsSunk: Int {
        return ships.filter { $0.isSunk }.count
    }

    /// Total hits received on this board.
    var totalHits: Int {
        return ships.reduce(0) { $0 + $1.hitCount }
    }

    /// Total misses on this board.
    var totalMisses: Int {
        var count = 0
        for row in grid {
            for cell in row {
                if cell.state == .miss {
                    count += 1
                }
            }
        }
        return count
    }

    /// All coordinates that are valid attack targets.
    var validTargets: [Coordinate] {
        var targets: [Coordinate] = []
        for row in grid {
            for cell in row {
                if cell.isValidTarget {
                    targets.append(cell.coordinate)
                }
            }
        }
        return targets
    }

    /// Whether the board has all required ships placed.
    var isFleetComplete: Bool {
        let requiredTypes = Set(FleetConfiguration.standard)
        let placedTypes = Set(ships.map { $0.type })
        return requiredTypes == placedTypes
    }

    /// Gets the ship at a given coordinate, if any.
    func ship(at coordinate: Coordinate) -> Ship? {
        return ships.first { $0.occupies(coordinate) }
    }

    /// Gets a ship by its ID.
    func ship(withId id: UUID) -> Ship? {
        return ships.first { $0.id == id }
    }
}

// MARK: - BoardError

/// Errors that can occur during board operations.
enum BoardError: Error, Equatable, Sendable {
    /// Ship placement extends beyond board boundaries
    case shipOutOfBounds
    /// Ship overlaps with another ship
    case shipOverlap
    /// Cell is already occupied
    case cellOccupied
    /// Coordinate has already been attacked
    case alreadyAttacked
    /// Ship with given ID not found
    case shipNotFound
    /// Invalid attack (general error)
    case invalidAttack
}

// MARK: - AttackResult

/// The result of an attack on the board.
enum AttackResult: Equatable, Sendable {
    /// Attack missed all ships
    case miss
    /// Attack hit a ship but didn't sink it
    case hit
    /// Attack sunk a ship
    case sunk(ShipType)
}
