//
//  SymbolSpritesTests.swift
//  CoralGreifTests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
import SpriteKit
@testable import CoralGreif

final class SymbolSpritesTests: XCTestCase {

    // MARK: - Image Creation Tests

    func testImageCreationForAllSymbols() {
        let symbols: [SymbolSprites.GameSymbol] = [
            .targetReticle, .hitMarker, .missMarker,
            .settings, .back, .menu,
            .soundOn, .soundOff,
            .timer, .warning,
            .victory, .defeat,
            .shipIntact, .shipDamaged, .shipSunk,
            .rotate, .confirm, .cancel, .autoPlace,
            .info, .help
        ]

        for symbol in symbols {
            let image = SymbolSprites.image(for: symbol)
            XCTAssertNotNil(image, "Image for \(symbol) should be created")
        }
    }

    func testImageWithCustomPointSize() {
        let smallImage = SymbolSprites.image(for: .targetReticle, pointSize: 16)
        let largeImage = SymbolSprites.image(for: .targetReticle, pointSize: 64)

        XCTAssertNotNil(smallImage, "Small image should be created")
        XCTAssertNotNil(largeImage, "Large image should be created")

        if let small = smallImage, let large = largeImage {
            XCTAssertLessThan(small.size.width, large.size.width,
                              "Larger point size should produce larger image")
        }
    }

    func testImageWithDifferentWeights() {
        let weights: [SymbolSprites.SymbolWeight] = [.light, .regular, .medium, .semibold, .bold]

        for weight in weights {
            let image = SymbolSprites.image(for: .settings, weight: weight)
            XCTAssertNotNil(image, "Image with \(weight) weight should be created")
        }
    }

    func testImageWithTint() {
        let tintedImage = SymbolSprites.image(for: .hitMarker, tint: .red)
        XCTAssertNotNil(tintedImage, "Tinted image should be created")
    }

    // MARK: - Texture Creation Tests

    func testTextureCreation() {
        let texture = SymbolSprites.texture(for: .targetReticle)
        XCTAssertNotNil(texture, "Texture should be created")
    }

    func testTextureWithCustomParameters() {
        let texture = SymbolSprites.texture(
            for: .hitMarker,
            pointSize: 32,
            weight: .bold,
            tint: .orange
        )
        XCTAssertNotNil(texture, "Texture with custom parameters should be created")
    }

    // MARK: - Sprite Creation Tests

    func testSpriteCreation() {
        let sprite = SymbolSprites.sprite(for: .missMarker)
        XCTAssertNotNil(sprite, "Sprite should be created")
        XCTAssertNotNil(sprite?.texture, "Sprite should have texture")
    }

    func testSpriteHasCorrectName() {
        let sprite = SymbolSprites.sprite(for: .targetReticle)
        XCTAssertEqual(sprite?.name, "symbol_scope", "Sprite should have correct name")
    }

    func testSpriteWithCustomTint() {
        let sprite = SymbolSprites.sprite(for: .settings, tint: .green)
        XCTAssertNotNil(sprite, "Sprite with custom tint should be created")
    }

    // MARK: - Convenience Method Tests

    func testHitMarkerCreation() {
        let marker = SymbolSprites.hitMarker()
        XCTAssertNotNil(marker, "Hit marker should be created")
    }

    func testHitMarkerWithCustomSize() {
        let smallMarker = SymbolSprites.hitMarker(size: 16)
        let largeMarker = SymbolSprites.hitMarker(size: 48)

        XCTAssertNotNil(smallMarker, "Small hit marker should be created")
        XCTAssertNotNil(largeMarker, "Large hit marker should be created")
    }

    func testMissMarkerCreation() {
        let marker = SymbolSprites.missMarker()
        XCTAssertNotNil(marker, "Miss marker should be created")
    }

    func testMissMarkerWithCustomSize() {
        let marker = SymbolSprites.missMarker(size: 32)
        XCTAssertNotNil(marker, "Miss marker with custom size should be created")
    }

    func testTargetReticleCreation() {
        let reticle = SymbolSprites.targetReticle()
        XCTAssertNotNil(reticle, "Target reticle should be created")
    }

    func testTargetReticleWithCustomSize() {
        let reticle = SymbolSprites.targetReticle(size: 48)
        XCTAssertNotNil(reticle, "Target reticle with custom size should be created")
    }

    func testButtonIconCreation() {
        let icon = SymbolSprites.buttonIcon(.settings)
        XCTAssertNotNil(icon, "Button icon should be created")
    }

    func testButtonIconForVariousSymbols() {
        let symbols: [SymbolSprites.GameSymbol] = [
            .settings, .back, .menu, .soundOn, .soundOff,
            .confirm, .cancel, .rotate, .autoPlace
        ]

        for symbol in symbols {
            let icon = SymbolSprites.buttonIcon(symbol)
            XCTAssertNotNil(icon, "Button icon for \(symbol) should be created")
        }
    }

    // MARK: - Symbol Weight Conversion Tests

    func testSymbolWeightConversion() {
        XCTAssertEqual(SymbolSprites.SymbolWeight.light.uiWeight, .light)
        XCTAssertEqual(SymbolSprites.SymbolWeight.regular.uiWeight, .regular)
        XCTAssertEqual(SymbolSprites.SymbolWeight.medium.uiWeight, .medium)
        XCTAssertEqual(SymbolSprites.SymbolWeight.semibold.uiWeight, .semibold)
        XCTAssertEqual(SymbolSprites.SymbolWeight.bold.uiWeight, .bold)
    }

    // MARK: - UIButton Extension Tests

    func testUIButtonSetSymbol() {
        let button = UIButton()
        button.setSymbol(.settings)
        XCTAssertNotNil(button.image(for: .normal), "Button should have symbol image")
    }

    func testUIButtonSetSymbolWithParameters() {
        let button = UIButton()
        button.setSymbol(.confirm, pointSize: 32, weight: .bold, tint: .green)
        XCTAssertNotNil(button.image(for: .normal), "Button should have customized symbol image")
    }

    // MARK: - UIImageView Extension Tests

    func testUIImageViewSetSymbol() {
        let imageView = UIImageView()
        imageView.setSymbol(.timer)
        XCTAssertNotNil(imageView.image, "Image view should have symbol image")
    }

    func testUIImageViewSetSymbolWithParameters() {
        let imageView = UIImageView()
        imageView.setSymbol(.warning, pointSize: 48, weight: .semibold, tint: .orange)
        XCTAssertNotNil(imageView.image, "Image view should have customized symbol image")
    }
}
