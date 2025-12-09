//
//  ShipPathsTests.swift
//  CoralGreifTests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
@testable import CoralGreif

final class ShipPathsTests: XCTestCase {

    // MARK: - Path Generation Tests

    func testPathForCarrier() {
        let path = ShipPaths.path(for: .carrier)
        XCTAssertFalse(path.isEmpty, "Carrier path should not be empty")
        XCTAssertFalse(path.boundingBox.isEmpty, "Carrier path should have non-empty bounds")
    }

    func testPathForBattleship() {
        let path = ShipPaths.path(for: .battleship)
        XCTAssertFalse(path.isEmpty, "Battleship path should not be empty")
        XCTAssertFalse(path.boundingBox.isEmpty, "Battleship path should have non-empty bounds")
    }

    func testPathForCruiser() {
        let path = ShipPaths.path(for: .cruiser)
        XCTAssertFalse(path.isEmpty, "Cruiser path should not be empty")
        XCTAssertFalse(path.boundingBox.isEmpty, "Cruiser path should have non-empty bounds")
    }

    func testPathForSubmarine() {
        let path = ShipPaths.path(for: .submarine)
        XCTAssertFalse(path.isEmpty, "Submarine path should not be empty")
        XCTAssertFalse(path.boundingBox.isEmpty, "Submarine path should have non-empty bounds")
    }

    func testPathForDestroyer() {
        let path = ShipPaths.path(for: .destroyer)
        XCTAssertFalse(path.isEmpty, "Destroyer path should not be empty")
        XCTAssertFalse(path.boundingBox.isEmpty, "Destroyer path should have non-empty bounds")
    }

    // MARK: - Unit Coordinate Tests

    func testPathsAreInUnitCoordinates() {
        for shipType in ShipType.allCases {
            let path = ShipPaths.path(for: shipType)
            let bounds = path.boundingBox

            // Paths should be roughly within 0-1 range (with small margins)
            XCTAssertGreaterThanOrEqual(bounds.minX, -0.1, "\(shipType) path minX should be near 0")
            XCTAssertLessThanOrEqual(bounds.maxX, 1.1, "\(shipType) path maxX should be near 1")
            XCTAssertGreaterThanOrEqual(bounds.minY, -0.1, "\(shipType) path minY should be near 0")
            XCTAssertLessThanOrEqual(bounds.maxY, 1.1, "\(shipType) path maxY should be near 1")
        }
    }

    // MARK: - Scaled Path Tests

    func testScaledPathProducesCorrectSize() {
        let targetSize = CGSize(width: 200, height: 40)
        let scaledPath = ShipPaths.scaledPath(for: .carrier, fitting: targetSize)
        let bounds = scaledPath.boundingBox

        // Scaled path should approximately match target size
        XCTAssertGreaterThan(bounds.width, targetSize.width * 0.8, "Scaled width too small")
        XCTAssertLessThan(bounds.width, targetSize.width * 1.2, "Scaled width too large")
        XCTAssertGreaterThan(bounds.height, targetSize.height * 0.5, "Scaled height too small")
        XCTAssertLessThan(bounds.height, targetSize.height * 1.5, "Scaled height too large")
    }

    func testScaledPathForAllShipTypes() {
        let targetSize = CGSize(width: 100, height: 30)

        for shipType in ShipType.allCases {
            let scaledPath = ShipPaths.scaledPath(for: shipType, fitting: targetSize)
            XCTAssertFalse(scaledPath.isEmpty, "Scaled \(shipType) path should not be empty")
            XCTAssertFalse(scaledPath.boundingBox.isEmpty, "Scaled \(shipType) should have bounds")
        }
    }

    // MARK: - Path Consistency Tests

    func testPathsAreConsistentAcrossCalls() {
        for shipType in ShipType.allCases {
            let path1 = ShipPaths.path(for: shipType)
            let path2 = ShipPaths.path(for: shipType)

            let bounds1 = path1.boundingBox
            let bounds2 = path2.boundingBox

            XCTAssertEqual(bounds1.width, bounds2.width, accuracy: 0.001,
                           "\(shipType) paths should be consistent")
            XCTAssertEqual(bounds1.height, bounds2.height, accuracy: 0.001,
                           "\(shipType) paths should be consistent")
        }
    }

    // MARK: - All Ship Types Covered

    func testAllShipTypesHavePaths() {
        for shipType in ShipType.allCases {
            let path = ShipPaths.path(for: shipType)
            XCTAssertFalse(path.isEmpty, "Ship type \(shipType) should have a path")
        }
    }
}
