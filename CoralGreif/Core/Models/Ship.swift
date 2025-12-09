import Foundation

/// Represents a ship on the game board.
/// Ships are placed at an origin coordinate and extend in a direction based on orientation.
struct Ship: Identifiable, Equatable, Sendable {
    /// Unique identifier for this ship instance.
    let id: UUID

    /// The type of ship (determines size and display name).
    let type: ShipType

    /// The origin coordinate (bow of the ship).
    let origin: Coordinate

    /// The orientation (horizontal extends right, vertical extends down).
    let orientation: Orientation

    /// Coordinates that have been hit.
    private(set) var hits: Set<Coordinate>

    /// Creates a new ship.
    /// - Parameters:
    ///   - type: The ship type
    ///   - origin: The starting coordinate
    ///   - orientation: The direction the ship extends
    init(type: ShipType, origin: Coordinate, orientation: Orientation) {
        self.id = UUID()
        self.type = type
        self.origin = origin
        self.orientation = orientation
        self.hits = Set()
    }

    /// Creates a ship with a specific ID (for testing or deserialization).
    init(id: UUID, type: ShipType, origin: Coordinate, orientation: Orientation) {
        self.id = id
        self.type = type
        self.origin = origin
        self.orientation = orientation
        self.hits = Set()
    }

    /// The size (length) of this ship.
    var size: Int {
        return type.size
    }

    /// All coordinates occupied by this ship.
    var coordinates: [Coordinate] {
        var coords: [Coordinate] = []
        var current: Coordinate? = origin
        for _ in 0..<size {
            guard let coord = current else { break }
            coords.append(coord)
            current = coord.adjacent(in: orientation.direction)
        }
        return coords
    }

    /// Whether all positions of this ship have been hit.
    var isSunk: Bool {
        return hits.count >= size
    }

    /// The number of hits this ship has taken.
    var hitCount: Int {
        return hits.count
    }

    /// The number of remaining unhit positions.
    var remainingHealth: Int {
        return size - hits.count
    }

    /// Records a hit at the given coordinate.
    /// - Parameter coordinate: The coordinate that was hit
    /// - Returns: Result indicating success or failure
    mutating func recordHit(at coordinate: Coordinate) -> Result<Void, ShipError> {
        guard coordinates.contains(coordinate) else {
            return .failure(.coordinateNotOnShip)
        }
        guard !hits.contains(coordinate) else {
            return .failure(.alreadyHit)
        }
        hits.insert(coordinate)
        return .success(())
    }

    /// Checks if this ship occupies the given coordinate.
    func occupies(_ coordinate: Coordinate) -> Bool {
        return coordinates.contains(coordinate)
    }

    /// Validates that this ship can be placed (all coordinates are within bounds).
    func isValidPlacement() -> Bool {
        return coordinates.count == size
    }

    /// Checks if this ship overlaps with another ship.
    func overlaps(with other: Ship) -> Bool {
        let myCoords = Set(coordinates)
        let otherCoords = Set(other.coordinates)
        return !myCoords.isDisjoint(with: otherCoords)
    }
}

// MARK: - ShipType

/// WWII Pacific theater ship types with their sizes.
enum ShipType: String, CaseIterable, Codable, Sendable {
    /// Aircraft Carrier (USS Enterprise style) - 5 cells
    case carrier = "Carrier"
    /// Battleship (USS Missouri style) - 4 cells
    case battleship = "Battleship"
    /// Cruiser (USS Indianapolis style) - 3 cells
    case cruiser = "Cruiser"
    /// Submarine (USS Wahoo style) - 3 cells
    case submarine = "Submarine"
    /// Destroyer (USS Johnston style) - 2 cells
    case destroyer = "Destroyer"

    /// The length of this ship type in cells.
    var size: Int {
        switch self {
        case .carrier: return 5
        case .battleship: return 4
        case .cruiser: return 3
        case .submarine: return 3
        case .destroyer: return 2
        }
    }

    /// Display name for UI.
    var displayName: String {
        return rawValue
    }

    /// Historical reference ship name.
    var historicalName: String {
        switch self {
        case .carrier: return "USS Enterprise"
        case .battleship: return "USS Missouri"
        case .cruiser: return "USS Indianapolis"
        case .submarine: return "USS Wahoo"
        case .destroyer: return "USS Johnston"
        }
    }
}

// MARK: - ShipError

/// Errors that can occur during ship operations.
enum ShipError: Error, Equatable, Sendable {
    /// The coordinate is not part of this ship
    case coordinateNotOnShip
    /// The coordinate has already been hit
    case alreadyHit
    /// The ship placement extends beyond board bounds
    case outOfBounds
    /// The ship overlaps with another ship
    case overlapping
}

// MARK: - Fleet Configuration

/// Standard fleet configuration for a Battleship game.
struct FleetConfiguration: Sendable {
    /// The ship types required for a standard game.
    static let standard: [ShipType] = [
        .carrier,
        .battleship,
        .cruiser,
        .submarine,
        .destroyer
    ]

    /// Total number of cells occupied by a standard fleet.
    static var totalCells: Int {
        return standard.reduce(0) { $0 + $1.size }
    }

    /// Total number of ships in a standard fleet.
    static var shipCount: Int {
        return standard.count
    }
}
