//
//  AppTheme.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import UIKit

/// Central theme configuration for the app's visual appearance.
/// Uses WWII Pacific naval aesthetic with deep ocean blues and military greens.
enum AppTheme {

    // MARK: - Colors

    enum Colors {
        /// Deep ocean blue for backgrounds
        static let oceanDeep = UIColor(red: 0.05, green: 0.15, blue: 0.30, alpha: 1.0)

        /// Lighter ocean blue for grid cells
        static let oceanLight = UIColor(red: 0.10, green: 0.25, blue: 0.45, alpha: 1.0)

        /// Navy steel for ship colors
        static let navySteel = UIColor(red: 0.35, green: 0.40, blue: 0.45, alpha: 1.0)

        /// Hit marker red
        static let hitRed = UIColor(red: 0.85, green: 0.20, blue: 0.15, alpha: 1.0)

        /// Miss marker white
        static let missWhite = UIColor(red: 0.90, green: 0.92, blue: 0.95, alpha: 1.0)

        /// Sunk ship dark
        static let sunkDark = UIColor(red: 0.25, green: 0.12, blue: 0.10, alpha: 1.0)

        /// Sunk ship color (alias for SpriteKit compatibility)
        static let sunkShip = sunkDark

        /// Gold accent for highlights and buttons
        static let brassGold = UIColor(red: 0.80, green: 0.65, blue: 0.30, alpha: 1.0)

        /// Success green
        static let victoryGreen = UIColor(red: 0.20, green: 0.60, blue: 0.30, alpha: 1.0)

        /// Warning/timeout orange
        static let warningOrange = UIColor(red: 0.90, green: 0.55, blue: 0.15, alpha: 1.0)

        /// Text primary (off-white)
        static let textPrimary = UIColor(red: 0.95, green: 0.95, blue: 0.92, alpha: 1.0)

        /// Text secondary (dimmed)
        static let textSecondary = UIColor(red: 0.70, green: 0.72, blue: 0.75, alpha: 1.0)

        /// Grid line color
        static let gridLine = UIColor(red: 0.25, green: 0.35, blue: 0.50, alpha: 0.8)

        /// Valid placement highlight
        static let validPlacement = UIColor(red: 0.20, green: 0.60, blue: 0.30, alpha: 0.5)

        /// Invalid placement highlight
        static let invalidPlacement = UIColor(red: 0.85, green: 0.20, blue: 0.15, alpha: 0.5)
    }

    // MARK: - Fonts

    enum Fonts {
        /// Large title font (main menu, game over)
        static func title() -> UIFont {
            return UIFont.systemFont(ofSize: 36, weight: .bold)
        }

        /// Heading font (section headers)
        static func heading() -> UIFont {
            return UIFont.systemFont(ofSize: 24, weight: .semibold)
        }

        /// Body font (descriptions, puns)
        static func body() -> UIFont {
            return UIFont.systemFont(ofSize: 17, weight: .regular)
        }

        /// Caption font (grid labels, small text)
        static func caption() -> UIFont {
            return UIFont.systemFont(ofSize: 13, weight: .medium)
        }

        /// Monospace font (coordinates, stats)
        static func monospace() -> UIFont {
            return UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        }

        /// Timer display font
        static func timer() -> UIFont {
            return UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .bold)
        }
    }

    // MARK: - Layout

    enum Layout {
        /// Standard padding
        static let padding: CGFloat = 16

        /// Small padding
        static let paddingSmall: CGFloat = 8

        /// Large padding
        static let paddingLarge: CGFloat = 24

        /// Corner radius for buttons and cards
        static let cornerRadius: CGFloat = 12

        /// Grid cell size (calculated based on screen)
        static func cellSize(for boardWidth: CGFloat) -> CGFloat {
            return (boardWidth - (padding * 2)) / CGFloat(Coordinate.boardSize)
        }

        /// Standard button height
        static let buttonHeight: CGFloat = 50

        /// Grid line width
        static let gridLineWidth: CGFloat = 1.0
    }

    // MARK: - Animation

    enum Animation {
        /// Standard animation duration
        static let standard: TimeInterval = 0.3

        /// Quick animation duration
        static let quick: TimeInterval = 0.15

        /// Hit explosion duration
        static let hitExplosion: TimeInterval = 0.5

        /// Ship sinking duration
        static let sinkDuration: TimeInterval = 1.0
    }
}

// MARK: - UIButton Styling

extension UIButton {
    /// Applies primary button styling (gold background)
    func applyPrimaryStyle() {
        backgroundColor = AppTheme.Colors.brassGold
        setTitleColor(AppTheme.Colors.oceanDeep, for: .normal)
        titleLabel?.font = AppTheme.Fonts.heading()
        layer.cornerRadius = AppTheme.Layout.cornerRadius
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
    }

    /// Applies secondary button styling (outlined)
    func applySecondaryStyle() {
        backgroundColor = .clear
        setTitleColor(AppTheme.Colors.textPrimary, for: .normal)
        titleLabel?.font = AppTheme.Fonts.body()
        layer.cornerRadius = AppTheme.Layout.cornerRadius
        layer.borderWidth = 2
        layer.borderColor = AppTheme.Colors.textSecondary.cgColor
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
    }

    /// Applies danger button styling (red)
    func applyDangerStyle() {
        backgroundColor = AppTheme.Colors.hitRed
        setTitleColor(AppTheme.Colors.textPrimary, for: .normal)
        titleLabel?.font = AppTheme.Fonts.heading()
        layer.cornerRadius = AppTheme.Layout.cornerRadius
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
    }
}

// MARK: - UILabel Styling

extension UILabel {
    /// Applies title styling
    func applyTitleStyle() {
        font = AppTheme.Fonts.title()
        textColor = AppTheme.Colors.textPrimary
        textAlignment = .center
    }

    /// Applies heading styling
    func applyHeadingStyle() {
        font = AppTheme.Fonts.heading()
        textColor = AppTheme.Colors.textPrimary
        textAlignment = .center
    }

    /// Applies body styling
    func applyBodyStyle() {
        font = AppTheme.Fonts.body()
        textColor = AppTheme.Colors.textSecondary
        textAlignment = .center
        numberOfLines = 0
    }
}

// MARK: - UIView Styling

extension UIView {
    /// Applies card styling (rounded corners, subtle shadow)
    func applyCardStyle() {
        backgroundColor = AppTheme.Colors.oceanLight
        layer.cornerRadius = AppTheme.Layout.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.3
    }
}
