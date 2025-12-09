//
//  ShipPaths.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import CoreGraphics

/// Provides CGPath silhouettes for WWII Pacific theater ship types.
/// All paths are normalized to a unit coordinate system where:
/// - Width spans from 0.0 to 1.0 (ship length)
/// - Height spans from 0.0 to 1.0 (ship beam)
/// Scale the path to fit the desired cell dimensions.
enum ShipPaths {

    // MARK: - Public API

    /// Returns the silhouette path for a given ship type.
    /// - Parameter type: The ship type
    /// - Returns: A CGPath representing the ship silhouette in unit coordinates
    static func path(for type: ShipType) -> CGPath {
        switch type {
        case .carrier:
            return carrierPath()
        case .battleship:
            return battleshipPath()
        case .cruiser:
            return cruiserPath()
        case .submarine:
            return submarinePath()
        case .destroyer:
            return destroyerPath()
        }
    }

    /// Returns a scaled path for a ship type to fit a given size.
    /// - Parameters:
    ///   - type: The ship type
    ///   - size: The target size in points
    /// - Returns: A scaled CGPath
    static func scaledPath(for type: ShipType, fitting size: CGSize) -> CGPath {
        let basePath = path(for: type)
        var transform = CGAffineTransform(scaleX: size.width, y: size.height)
        if let scaled = basePath.copy(using: &transform) {
            return scaled
        }
        return basePath
    }

    // MARK: - Carrier (5 cells)
    // USS Enterprise style: Flat flight deck with island superstructure

    private static func carrierPath() -> CGPath {
        let path = CGMutablePath()

        // Main flight deck hull
        path.move(to: CGPoint(x: 0.02, y: 0.35))

        // Bow (angled for flight deck)
        path.addLine(to: CGPoint(x: 0.08, y: 0.25))
        path.addLine(to: CGPoint(x: 0.12, y: 0.20))
        path.addLine(to: CGPoint(x: 0.12, y: 0.80))
        path.addLine(to: CGPoint(x: 0.08, y: 0.75))
        path.addLine(to: CGPoint(x: 0.02, y: 0.65))

        // Close bow
        path.closeSubpath()

        // Main deck rectangle
        path.addRect(CGRect(x: 0.12, y: 0.18, width: 0.80, height: 0.64))

        // Stern
        path.move(to: CGPoint(x: 0.92, y: 0.18))
        path.addLine(to: CGPoint(x: 0.98, y: 0.25))
        path.addLine(to: CGPoint(x: 0.98, y: 0.75))
        path.addLine(to: CGPoint(x: 0.92, y: 0.82))
        path.closeSubpath()

        // Island superstructure (starboard side)
        path.addRect(CGRect(x: 0.55, y: 0.70, width: 0.15, height: 0.20))

        // Island tower
        path.addRect(CGRect(x: 0.58, y: 0.85, width: 0.08, height: 0.10))

        return path
    }

    // MARK: - Battleship (4 cells)
    // USS Missouri style: Heavy hull with turrets fore and aft

    private static func battleshipPath() -> CGPath {
        let path = CGMutablePath()

        // Main hull
        path.move(to: CGPoint(x: 0.02, y: 0.50))

        // Bow (pointed)
        path.addLine(to: CGPoint(x: 0.15, y: 0.25))
        path.addLine(to: CGPoint(x: 0.15, y: 0.75))
        path.closeSubpath()

        // Hull body
        path.addRect(CGRect(x: 0.15, y: 0.22, width: 0.70, height: 0.56))

        // Stern
        path.move(to: CGPoint(x: 0.85, y: 0.22))
        path.addLine(to: CGPoint(x: 0.95, y: 0.30))
        path.addLine(to: CGPoint(x: 0.98, y: 0.50))
        path.addLine(to: CGPoint(x: 0.95, y: 0.70))
        path.addLine(to: CGPoint(x: 0.85, y: 0.78))
        path.closeSubpath()

        // Forward turret (twin barrels represented as rectangle)
        path.addRect(CGRect(x: 0.20, y: 0.32, width: 0.12, height: 0.36))

        // Bridge superstructure
        path.addRect(CGRect(x: 0.40, y: 0.28, width: 0.20, height: 0.44))
        path.addRect(CGRect(x: 0.45, y: 0.20, width: 0.10, height: 0.12))

        // Aft turret
        path.addRect(CGRect(x: 0.68, y: 0.32, width: 0.12, height: 0.36))

        return path
    }

    // MARK: - Cruiser (3 cells)
    // USS Indianapolis style: Streamlined hull with turret stack

    private static func cruiserPath() -> CGPath {
        let path = CGMutablePath()

        // Streamlined bow
        path.move(to: CGPoint(x: 0.02, y: 0.50))
        path.addCurve(
            to: CGPoint(x: 0.18, y: 0.22),
            control1: CGPoint(x: 0.05, y: 0.35),
            control2: CGPoint(x: 0.10, y: 0.22)
        )

        // Top of hull
        path.addLine(to: CGPoint(x: 0.85, y: 0.22))

        // Stern
        path.addCurve(
            to: CGPoint(x: 0.98, y: 0.50),
            control1: CGPoint(x: 0.92, y: 0.22),
            control2: CGPoint(x: 0.98, y: 0.35)
        )
        path.addCurve(
            to: CGPoint(x: 0.85, y: 0.78),
            control1: CGPoint(x: 0.98, y: 0.65),
            control2: CGPoint(x: 0.92, y: 0.78)
        )

        // Bottom of hull
        path.addLine(to: CGPoint(x: 0.18, y: 0.78))

        // Close back to bow
        path.addCurve(
            to: CGPoint(x: 0.02, y: 0.50),
            control1: CGPoint(x: 0.10, y: 0.78),
            control2: CGPoint(x: 0.05, y: 0.65)
        )

        path.closeSubpath()

        // Forward turret
        path.addRect(CGRect(x: 0.18, y: 0.35, width: 0.10, height: 0.30))

        // Bridge
        path.addRect(CGRect(x: 0.38, y: 0.30, width: 0.15, height: 0.40))
        path.addRect(CGRect(x: 0.42, y: 0.22, width: 0.07, height: 0.10))

        // Aft turret
        path.addRect(CGRect(x: 0.65, y: 0.35, width: 0.10, height: 0.30))

        return path
    }

    // MARK: - Submarine (3 cells)
    // USS Wahoo style: Cylindrical hull with conning tower

    private static func submarinePath() -> CGPath {
        let path = CGMutablePath()

        // Cigar-shaped hull
        path.move(to: CGPoint(x: 0.02, y: 0.50))

        // Bow curve
        path.addCurve(
            to: CGPoint(x: 0.15, y: 0.30),
            control1: CGPoint(x: 0.02, y: 0.38),
            control2: CGPoint(x: 0.08, y: 0.30)
        )

        // Top of hull
        path.addLine(to: CGPoint(x: 0.85, y: 0.30))

        // Stern curve
        path.addCurve(
            to: CGPoint(x: 0.98, y: 0.50),
            control1: CGPoint(x: 0.92, y: 0.30),
            control2: CGPoint(x: 0.98, y: 0.38)
        )
        path.addCurve(
            to: CGPoint(x: 0.85, y: 0.70),
            control1: CGPoint(x: 0.98, y: 0.62),
            control2: CGPoint(x: 0.92, y: 0.70)
        )

        // Bottom of hull
        path.addLine(to: CGPoint(x: 0.15, y: 0.70))

        // Close back to bow
        path.addCurve(
            to: CGPoint(x: 0.02, y: 0.50),
            control1: CGPoint(x: 0.08, y: 0.70),
            control2: CGPoint(x: 0.02, y: 0.62)
        )

        path.closeSubpath()

        // Conning tower
        path.move(to: CGPoint(x: 0.40, y: 0.30))
        path.addLine(to: CGPoint(x: 0.42, y: 0.15))
        path.addLine(to: CGPoint(x: 0.58, y: 0.15))
        path.addLine(to: CGPoint(x: 0.60, y: 0.30))
        path.closeSubpath()

        // Periscope/mast
        path.addRect(CGRect(x: 0.48, y: 0.05, width: 0.04, height: 0.12))

        return path
    }

    // MARK: - Destroyer (2 cells)
    // USS Johnston style: Low profile, dual stacks

    private static func destroyerPath() -> CGPath {
        let path = CGMutablePath()

        // Sleek bow
        path.move(to: CGPoint(x: 0.02, y: 0.50))
        path.addLine(to: CGPoint(x: 0.20, y: 0.28))

        // Top of hull
        path.addLine(to: CGPoint(x: 0.88, y: 0.28))

        // Stern
        path.addLine(to: CGPoint(x: 0.98, y: 0.38))
        path.addLine(to: CGPoint(x: 0.98, y: 0.62))
        path.addLine(to: CGPoint(x: 0.88, y: 0.72))

        // Bottom of hull
        path.addLine(to: CGPoint(x: 0.20, y: 0.72))

        // Close back to bow
        path.closeSubpath()

        // Forward gun turret
        path.addRect(CGRect(x: 0.18, y: 0.38, width: 0.08, height: 0.24))

        // Bridge
        path.addRect(CGRect(x: 0.32, y: 0.32, width: 0.12, height: 0.36))
        path.addRect(CGRect(x: 0.35, y: 0.24, width: 0.06, height: 0.10))

        // Forward stack
        path.addRect(CGRect(x: 0.48, y: 0.20, width: 0.06, height: 0.14))

        // Aft stack
        path.addRect(CGRect(x: 0.58, y: 0.20, width: 0.06, height: 0.14))

        // Aft gun
        path.addRect(CGRect(x: 0.72, y: 0.38, width: 0.08, height: 0.24))

        return path
    }
}
