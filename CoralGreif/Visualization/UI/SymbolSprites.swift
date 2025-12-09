//
//  SymbolSprites.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import SpriteKit
import UIKit

/// Provides SF Symbol sprites for game UI elements.
/// Centralizes symbol configuration for consistent styling.
enum SymbolSprites {

    // MARK: - Symbol Definitions

    /// Available game symbols with their SF Symbol names.
    enum GameSymbol: String {
        // Attack markers
        case targetReticle = "scope"
        case hitMarker = "xmark.circle.fill"
        case missMarker = "circle"

        // Navigation and settings
        case settings = "gearshape"
        case back = "chevron.left"
        case menu = "line.3.horizontal"

        // Audio controls
        case soundOn = "speaker.wave.2"
        case soundOff = "speaker.slash"

        // Timer and status
        case timer = "clock"
        case warning = "exclamationmark.triangle"

        // Game outcome
        case victory = "flag.checkered"
        case defeat = "flag.fill"

        // Ship status
        case shipIntact = "shield.fill"
        case shipDamaged = "shield.lefthalf.filled"
        case shipSunk = "xmark.shield"

        // Actions
        case rotate = "rotate.right"
        case confirm = "checkmark.circle.fill"
        case cancel = "xmark.circle"
        case autoPlace = "shuffle"

        // Info
        case info = "info.circle"
        case help = "questionmark.circle"
    }

    // MARK: - Symbol Weight

    /// Symbol weight configurations.
    enum SymbolWeight {
        case light
        case regular
        case medium
        case semibold
        case bold

        var uiWeight: UIImage.SymbolWeight {
            switch self {
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }
    }

    // MARK: - UIImage Creation

    /// Creates a UIImage for the specified symbol.
    /// - Parameters:
    ///   - symbol: The game symbol to create
    ///   - pointSize: The point size for the symbol
    ///   - weight: The weight of the symbol
    ///   - tint: Optional tint color
    /// - Returns: Configured UIImage, or nil if symbol unavailable
    static func image(
        for symbol: GameSymbol,
        pointSize: CGFloat = 24,
        weight: SymbolWeight = .regular,
        tint: UIColor? = nil
    ) -> UIImage? {
        let config = UIImage.SymbolConfiguration(
            pointSize: pointSize,
            weight: weight.uiWeight
        )

        var image = UIImage(systemName: symbol.rawValue, withConfiguration: config)

        if let tint = tint {
            image = image?.withTintColor(tint, renderingMode: .alwaysOriginal)
        }

        return image
    }

    // MARK: - SKTexture Creation

    /// Creates an SKTexture for the specified symbol.
    /// - Parameters:
    ///   - symbol: The game symbol to create
    ///   - pointSize: The point size for the symbol
    ///   - weight: The weight of the symbol
    ///   - tint: The tint color (defaults to white)
    /// - Returns: SKTexture, or nil if symbol unavailable
    static func texture(
        for symbol: GameSymbol,
        pointSize: CGFloat = 24,
        weight: SymbolWeight = .regular,
        tint: UIColor = .white
    ) -> SKTexture? {
        guard let image = image(
            for: symbol,
            pointSize: pointSize,
            weight: weight,
            tint: tint
        ) else {
            return nil
        }

        return SKTexture(image: image)
    }

    // MARK: - SKSpriteNode Creation

    /// Creates an SKSpriteNode for the specified symbol.
    /// - Parameters:
    ///   - symbol: The game symbol to create
    ///   - pointSize: The point size for the symbol
    ///   - weight: The weight of the symbol
    ///   - tint: The tint color (defaults to theme primary text)
    /// - Returns: Configured SKSpriteNode, or nil if symbol unavailable
    static func sprite(
        for symbol: GameSymbol,
        pointSize: CGFloat = 24,
        weight: SymbolWeight = .regular,
        tint: UIColor = AppTheme.Colors.textPrimary
    ) -> SKSpriteNode? {
        guard let texture = texture(
            for: symbol,
            pointSize: pointSize,
            weight: weight,
            tint: tint
        ) else {
            return nil
        }

        let sprite = SKSpriteNode(texture: texture)
        sprite.name = "symbol_\(symbol.rawValue)"
        return sprite
    }

    // MARK: - Hit/Miss Markers

    /// Creates a hit marker sprite with standard game styling.
    /// - Parameter size: The size of the marker
    /// - Returns: Configured hit marker sprite
    static func hitMarker(size: CGFloat = 24) -> SKSpriteNode? {
        return sprite(
            for: .hitMarker,
            pointSize: size,
            weight: .bold,
            tint: AppTheme.Colors.hitRed
        )
    }

    /// Creates a miss marker sprite with standard game styling.
    /// - Parameter size: The size of the marker
    /// - Returns: Configured miss marker sprite
    static func missMarker(size: CGFloat = 20) -> SKSpriteNode? {
        return sprite(
            for: .missMarker,
            pointSize: size,
            weight: .regular,
            tint: AppTheme.Colors.missWhite
        )
    }

    /// Creates a target reticle sprite for attack cursor.
    /// - Parameter size: The size of the reticle
    /// - Returns: Configured reticle sprite
    static func targetReticle(size: CGFloat = 32) -> SKSpriteNode? {
        return sprite(
            for: .targetReticle,
            pointSize: size,
            weight: .medium,
            tint: AppTheme.Colors.brassGold
        )
    }

    // MARK: - Button Icons

    /// Creates a button icon with consistent styling.
    /// - Parameters:
    ///   - symbol: The symbol to use
    ///   - size: The size of the icon
    /// - Returns: Configured icon sprite
    static func buttonIcon(
        _ symbol: GameSymbol,
        size: CGFloat = 20
    ) -> SKSpriteNode? {
        return sprite(
            for: symbol,
            pointSize: size,
            weight: .semibold,
            tint: AppTheme.Colors.textPrimary
        )
    }
}

// MARK: - UIButton Extension

extension UIButton {

    /// Sets an SF Symbol as the button image.
    /// - Parameters:
    ///   - symbol: The game symbol to use
    ///   - pointSize: The point size
    ///   - weight: The symbol weight
    ///   - tint: The tint color
    func setSymbol(
        _ symbol: SymbolSprites.GameSymbol,
        pointSize: CGFloat = 24,
        weight: SymbolSprites.SymbolWeight = .regular,
        tint: UIColor? = nil
    ) {
        let image = SymbolSprites.image(
            for: symbol,
            pointSize: pointSize,
            weight: weight,
            tint: tint
        )
        setImage(image, for: .normal)
    }
}

// MARK: - UIImageView Extension

extension UIImageView {

    /// Sets an SF Symbol as the image view's image.
    /// - Parameters:
    ///   - symbol: The game symbol to use
    ///   - pointSize: The point size
    ///   - weight: The symbol weight
    ///   - tint: The tint color
    func setSymbol(
        _ symbol: SymbolSprites.GameSymbol,
        pointSize: CGFloat = 24,
        weight: SymbolSprites.SymbolWeight = .regular,
        tint: UIColor? = nil
    ) {
        image = SymbolSprites.image(
            for: symbol,
            pointSize: pointSize,
            weight: weight,
            tint: tint
        )
    }
}
