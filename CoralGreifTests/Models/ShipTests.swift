import XCTest
@testable import CoralGreif

// MARK: - Test Helpers

private func assertSuccess<E: Error>(_ result: Result<Void, E>, file: StaticString = #file, line: UInt = #line) {
    if case .failure(let error) = result {
        XCTFail("Expected success but got failure: \(error)", file: file, line: line)
    }
}

private func assertFailure<E: Error & Equatable>(
    _ result: Result<Void, E>,
    expectedError: E,
    file: StaticString = #file,
    line: UInt = #line
) {
    switch result {
    case .success:
        XCTFail("Expected failure but got success", file: file, line: line)
    case .failure(let error):
        XCTAssertEqual(error, expectedError, file: file, line: line)
    }
}

final class ShipTests: XCTestCase {

    // MARK: - Initialization Tests

    func testShipCreation() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)

        XCTAssertEqual(ship.type, .destroyer)
        XCTAssertEqual(ship.origin, origin)
        XCTAssertEqual(ship.orientation, .horizontal)
        XCTAssertTrue(ship.hits.isEmpty)
    }

    func testShipCreationWithSpecificId() {
        let origin = Coordinate(row: 0, column: 0)!
        let testId = UUID()
        let ship = Ship(id: testId, type: .carrier, origin: origin, orientation: .vertical)

        XCTAssertEqual(ship.id, testId)
    }

    // MARK: - Size Tests

    func testCarrierSize() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .carrier, origin: origin, orientation: .horizontal)
        XCTAssertEqual(ship.size, 5)
    }

    func testBattleshipSize() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .battleship, origin: origin, orientation: .horizontal)
        XCTAssertEqual(ship.size, 4)
    }

    func testCruiserSize() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .cruiser, origin: origin, orientation: .horizontal)
        XCTAssertEqual(ship.size, 3)
    }

    func testSubmarineSize() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .submarine, origin: origin, orientation: .horizontal)
        XCTAssertEqual(ship.size, 3)
    }

    func testDestroyerSize() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        XCTAssertEqual(ship.size, 2)
    }

    // MARK: - Coordinates Tests

    func testCoordinatesHorizontal() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .cruiser, origin: origin, orientation: .horizontal)
        let coords = ship.coordinates

        XCTAssertEqual(coords.count, 3)
        XCTAssertEqual(coords[0], Coordinate(row: 0, column: 0))
        XCTAssertEqual(coords[1], Coordinate(row: 0, column: 1))
        XCTAssertEqual(coords[2], Coordinate(row: 0, column: 2))
    }

    func testCoordinatesVertical() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .cruiser, origin: origin, orientation: .vertical)
        let coords = ship.coordinates

        XCTAssertEqual(coords.count, 3)
        XCTAssertEqual(coords[0], Coordinate(row: 0, column: 0))
        XCTAssertEqual(coords[1], Coordinate(row: 1, column: 0))
        XCTAssertEqual(coords[2], Coordinate(row: 2, column: 0))
    }

    func testCoordinatesPartiallyOutOfBounds() {
        let origin = Coordinate(row: 0, column: 8)!
        let ship = Ship(type: .cruiser, origin: origin, orientation: .horizontal)
        let coords = ship.coordinates

        // Should only have 2 valid coordinates (8, 9) since 10 is out of bounds
        XCTAssertEqual(coords.count, 2)
    }

    // MARK: - Valid Placement Tests

    func testIsValidPlacementTrue() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        XCTAssertTrue(ship.isValidPlacement())
    }

    func testIsValidPlacementFalseOutOfBounds() {
        let origin = Coordinate(row: 0, column: 9)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        XCTAssertFalse(ship.isValidPlacement())
    }

    func testIsValidPlacementCarrierAtEdge() {
        let origin = Coordinate(row: 0, column: 5)!
        let ship = Ship(type: .carrier, origin: origin, orientation: .horizontal)
        // Coordinates would be 5,6,7,8,9 - valid
        XCTAssertTrue(ship.isValidPlacement())
    }

    func testIsValidPlacementCarrierOverEdge() {
        let origin = Coordinate(row: 0, column: 6)!
        let ship = Ship(type: .carrier, origin: origin, orientation: .horizontal)
        // Coordinates would be 6,7,8,9,out - invalid
        XCTAssertFalse(ship.isValidPlacement())
    }

    // MARK: - Hit Tests

    func testRecordHitSuccess() {
        let origin = Coordinate(row: 0, column: 0)!
        var ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        let hitCoord = Coordinate(row: 0, column: 1)!

        let result = ship.recordHit(at: hitCoord)

        assertSuccess(result)
        XCTAssertTrue(ship.hits.contains(hitCoord))
        XCTAssertEqual(ship.hitCount, 1)
    }

    func testRecordHitNotOnShip() {
        let origin = Coordinate(row: 0, column: 0)!
        var ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        let hitCoord = Coordinate(row: 5, column: 5)!

        let result = ship.recordHit(at: hitCoord)

        assertFailure(result, expectedError: .coordinateNotOnShip)
        XCTAssertFalse(ship.hits.contains(hitCoord))
    }

    func testRecordHitAlreadyHit() {
        let origin = Coordinate(row: 0, column: 0)!
        var ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        let hitCoord = Coordinate(row: 0, column: 0)!

        _ = ship.recordHit(at: hitCoord)
        let result = ship.recordHit(at: hitCoord)

        assertFailure(result, expectedError: .alreadyHit)
        XCTAssertEqual(ship.hitCount, 1)
    }

    // MARK: - Sunk Tests

    func testIsSunkFalse() {
        let origin = Coordinate(row: 0, column: 0)!
        var ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        _ = ship.recordHit(at: origin)

        XCTAssertFalse(ship.isSunk)
    }

    func testIsSunkTrue() {
        let origin = Coordinate(row: 0, column: 0)!
        var ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        _ = ship.recordHit(at: Coordinate(row: 0, column: 0)!)
        _ = ship.recordHit(at: Coordinate(row: 0, column: 1)!)

        XCTAssertTrue(ship.isSunk)
    }

    func testRemainingHealth() {
        let origin = Coordinate(row: 0, column: 0)!
        var ship = Ship(type: .cruiser, origin: origin, orientation: .horizontal)

        XCTAssertEqual(ship.remainingHealth, 3)
        _ = ship.recordHit(at: origin)
        XCTAssertEqual(ship.remainingHealth, 2)
    }

    // MARK: - Occupies Tests

    func testOccupiesTrue() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)

        XCTAssertTrue(ship.occupies(Coordinate(row: 0, column: 0)!))
        XCTAssertTrue(ship.occupies(Coordinate(row: 0, column: 1)!))
    }

    func testOccupiesFalse() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)

        XCTAssertFalse(ship.occupies(Coordinate(row: 0, column: 2)!))
        XCTAssertFalse(ship.occupies(Coordinate(row: 1, column: 0)!))
    }

    // MARK: - Overlap Tests

    func testOverlapsTrue() {
        let origin1 = Coordinate(row: 0, column: 0)!
        let ship1 = Ship(type: .cruiser, origin: origin1, orientation: .horizontal)

        let origin2 = Coordinate(row: 0, column: 2)!
        let ship2 = Ship(type: .cruiser, origin: origin2, orientation: .vertical)

        XCTAssertTrue(ship1.overlaps(with: ship2))
    }

    func testOverlapsFalse() {
        let origin1 = Coordinate(row: 0, column: 0)!
        let ship1 = Ship(type: .destroyer, origin: origin1, orientation: .horizontal)

        let origin2 = Coordinate(row: 1, column: 0)!
        let ship2 = Ship(type: .destroyer, origin: origin2, orientation: .horizontal)

        XCTAssertFalse(ship1.overlaps(with: ship2))
    }

    func testOverlapsWithSelf() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship = Ship(type: .destroyer, origin: origin, orientation: .horizontal)

        XCTAssertTrue(ship.overlaps(with: ship))
    }

    // MARK: - Equatable Tests

    func testShipEqualityBySameId() {
        let origin = Coordinate(row: 0, column: 0)!
        let testId = UUID()
        let ship1 = Ship(id: testId, type: .destroyer, origin: origin, orientation: .horizontal)
        let ship2 = Ship(id: testId, type: .destroyer, origin: origin, orientation: .horizontal)

        XCTAssertEqual(ship1, ship2)
    }

    func testShipInequalityByDifferentId() {
        let origin = Coordinate(row: 0, column: 0)!
        let ship1 = Ship(type: .destroyer, origin: origin, orientation: .horizontal)
        let ship2 = Ship(type: .destroyer, origin: origin, orientation: .horizontal)

        XCTAssertNotEqual(ship1, ship2)
    }
}

// MARK: - ShipType Tests

final class ShipTypeTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(ShipType.allCases.count, 5)
    }

    func testCarrierProperties() {
        XCTAssertEqual(ShipType.carrier.size, 5)
        XCTAssertEqual(ShipType.carrier.displayName, "Carrier")
        XCTAssertEqual(ShipType.carrier.historicalName, "USS Enterprise")
    }

    func testBattleshipProperties() {
        XCTAssertEqual(ShipType.battleship.size, 4)
        XCTAssertEqual(ShipType.battleship.displayName, "Battleship")
        XCTAssertEqual(ShipType.battleship.historicalName, "USS Missouri")
    }

    func testCruiserProperties() {
        XCTAssertEqual(ShipType.cruiser.size, 3)
        XCTAssertEqual(ShipType.cruiser.displayName, "Cruiser")
        XCTAssertEqual(ShipType.cruiser.historicalName, "USS Indianapolis")
    }

    func testSubmarineProperties() {
        XCTAssertEqual(ShipType.submarine.size, 3)
        XCTAssertEqual(ShipType.submarine.displayName, "Submarine")
        XCTAssertEqual(ShipType.submarine.historicalName, "USS Wahoo")
    }

    func testDestroyerProperties() {
        XCTAssertEqual(ShipType.destroyer.size, 2)
        XCTAssertEqual(ShipType.destroyer.displayName, "Destroyer")
        XCTAssertEqual(ShipType.destroyer.historicalName, "USS Johnston")
    }

    func testCodableRoundTrip() throws {
        let original = ShipType.carrier
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ShipType.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}

// MARK: - ShipError Tests

final class ShipErrorTests: XCTestCase {

    func testShipErrorEquality() {
        XCTAssertEqual(ShipError.coordinateNotOnShip, ShipError.coordinateNotOnShip)
        XCTAssertEqual(ShipError.alreadyHit, ShipError.alreadyHit)
        XCTAssertEqual(ShipError.outOfBounds, ShipError.outOfBounds)
        XCTAssertEqual(ShipError.overlapping, ShipError.overlapping)
    }

    func testShipErrorInequality() {
        XCTAssertNotEqual(ShipError.coordinateNotOnShip, ShipError.alreadyHit)
    }

    func testShipErrorIsError() {
        let error: Error = ShipError.outOfBounds
        XCTAssertNotNil(error)
    }
}

// MARK: - FleetConfiguration Tests

final class FleetConfigurationTests: XCTestCase {

    func testStandardFleetShipCount() {
        XCTAssertEqual(FleetConfiguration.shipCount, 5)
    }

    func testStandardFleetTotalCells() {
        // 5 + 4 + 3 + 3 + 2 = 17
        XCTAssertEqual(FleetConfiguration.totalCells, 17)
    }

    func testStandardFleetContainsAllTypes() {
        let standard = FleetConfiguration.standard
        XCTAssertTrue(standard.contains(.carrier))
        XCTAssertTrue(standard.contains(.battleship))
        XCTAssertTrue(standard.contains(.cruiser))
        XCTAssertTrue(standard.contains(.submarine))
        XCTAssertTrue(standard.contains(.destroyer))
    }
}
