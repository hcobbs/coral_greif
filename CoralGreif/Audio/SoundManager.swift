//
//  SoundManager.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import UIKit
import AVFoundation

/// Manages sound effects and haptic feedback for game events.
/// Uses interrupt-driven audio (AVAudioPlayer) rather than polling.
final class SoundManager {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Properties

    /// Whether sound effects are enabled
    var soundEnabled: Bool = true

    /// Whether haptic feedback is enabled
    var hapticsEnabled: Bool = true

    /// Audio players for different sound effects
    private var players: [SoundEffect: AVAudioPlayer] = [:]

    /// Haptic feedback generators
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // MARK: - Initialization

    private init() {
        prepareHaptics()
        configureAudioSession()
    }

    private func prepareHaptics() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session configuration failed, sounds will be disabled
            soundEnabled = false
        }
    }

    // MARK: - Sound Effects

    /// Plays a sound effect for the given game event.
    func play(_ effect: SoundEffect) {
        guard soundEnabled else { return }

        // Play system sound as fallback (no custom audio files)
        playSystemSound(for: effect)
    }

    private func playSystemSound(for effect: SoundEffect) {
        let soundID: SystemSoundID

        switch effect {
        case .hit:
            soundID = 1104  // Camera shutter
        case .miss:
            soundID = 1057  // Tock
        case .sunk:
            soundID = 1109  // Shake
        case .shipPlaced:
            soundID = 1104  // Pop
        case .buttonTap:
            soundID = 1104  // Click
        case .turnStart:
            soundID = 1113  // Alert
        case .turnTimeout:
            soundID = 1073  // Alarm
        case .victory:
            soundID = 1025  // Fanfare
        case .defeat:
            soundID = 1073  // Sad trombone equivalent
        case .gameStart:
            soundID = 1117  // Begin
        }

        AudioServicesPlaySystemSound(soundID)
    }

    // MARK: - Haptic Feedback

    /// Triggers haptic feedback for the given game event.
    func haptic(_ type: HapticType) {
        guard hapticsEnabled else { return }

        switch type {
        case .selection:
            selectionGenerator.selectionChanged()

        case .lightImpact:
            impactLight.impactOccurred()

        case .mediumImpact:
            impactMedium.impactOccurred()

        case .heavyImpact:
            impactHeavy.impactOccurred()

        case .success:
            notificationGenerator.notificationOccurred(.success)

        case .warning:
            notificationGenerator.notificationOccurred(.warning)

        case .error:
            notificationGenerator.notificationOccurred(.error)
        }
    }

    /// Plays combined sound and haptic for common game events.
    func playGameEvent(_ event: GameSoundEvent) {
        switch event {
        case .hit:
            play(.hit)
            haptic(.heavyImpact)

        case .miss:
            play(.miss)
            haptic(.lightImpact)

        case .sunk(let shipType):
            play(.sunk)
            // Multiple heavy impacts for dramatic effect
            haptic(.heavyImpact)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.haptic(.heavyImpact)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.haptic(.heavyImpact)
            }
            // Extra impact for larger ships
            if shipType.size >= 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.haptic(.heavyImpact)
                }
            }

        case .shipPlaced:
            play(.shipPlaced)
            haptic(.mediumImpact)

        case .buttonTap:
            play(.buttonTap)
            haptic(.selection)

        case .turnStart:
            play(.turnStart)
            haptic(.mediumImpact)

        case .turnTimeout:
            play(.turnTimeout)
            haptic(.warning)

        case .victory:
            play(.victory)
            haptic(.success)

        case .defeat:
            play(.defeat)
            haptic(.error)

        case .gameStart:
            play(.gameStart)
            haptic(.mediumImpact)

        case .invalidAction:
            haptic(.error)
        }
    }
}

// MARK: - Sound Effect Types

/// Individual sound effects that can be played.
enum SoundEffect {
    case hit
    case miss
    case sunk
    case shipPlaced
    case buttonTap
    case turnStart
    case turnTimeout
    case victory
    case defeat
    case gameStart
}

// MARK: - Haptic Types

/// Types of haptic feedback available.
enum HapticType {
    case selection
    case lightImpact
    case mediumImpact
    case heavyImpact
    case success
    case warning
    case error
}

// MARK: - Game Sound Events

/// Combined sound and haptic events for common game actions.
enum GameSoundEvent {
    case hit
    case miss
    case sunk(ShipType)
    case shipPlaced
    case buttonTap
    case turnStart
    case turnTimeout
    case victory
    case defeat
    case gameStart
    case invalidAction
}
