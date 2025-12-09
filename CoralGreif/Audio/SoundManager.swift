//
//  SoundManager.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import UIKit
import AVFoundation

/// Manages sound effects and haptic feedback for game events.
/// Uses synthesized audio via AVAudioEngine for naval battle sounds.
final class SoundManager {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Properties

    /// Whether sound effects are enabled
    var soundEnabled: Bool = true

    /// Whether haptic feedback is enabled
    var hapticsEnabled: Bool = true

    /// Audio engine for synthesized sounds
    private let audioEngine = AVAudioEngine()

    /// Mixer node for controlling overall volume
    private let mixerNode = AVAudioMixerNode()

    /// Player nodes for playing synthesized buffers
    private var playerNodes: [AVAudioPlayerNode] = []
    private let maxPlayers = 4

    /// Haptic feedback generators
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    /// Standard audio format for synthesized sounds
    private let audioFormat: AVAudioFormat

    // MARK: - Initialization

    private init() {
        // Initialize audio format (44.1kHz stereo)
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        prepareHaptics()
        configureAudioEngine()
    }

    private func prepareHaptics() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    private func configureAudioEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            // Attach mixer node
            audioEngine.attach(mixerNode)
            audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: audioFormat)

            // Create player nodes
            for _ in 0..<maxPlayers {
                let player = AVAudioPlayerNode()
                audioEngine.attach(player)
                audioEngine.connect(player, to: mixerNode, format: audioFormat)
                playerNodes.append(player)
            }

            // Start engine
            try audioEngine.start()
        } catch {
            soundEnabled = false
        }
    }

    // MARK: - Sound Effects

    /// Plays a sound effect for the given game event.
    func play(_ effect: SoundEffect) {
        guard soundEnabled else { return }

        let buffer = createSoundBuffer(for: effect)
        playBuffer(buffer)
    }

    /// Finds an available player and plays the buffer.
    private func playBuffer(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer = buffer else { return }

        // Find an available player (not playing)
        for player in playerNodes {
            if !player.isPlaying {
                player.scheduleBuffer(buffer, at: nil, options: .interrupts)
                player.play()
                return
            }
        }

        // All players busy, use the first one (interrupt)
        if let player = playerNodes.first {
            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: .interrupts)
            player.play()
        }
    }

    // MARK: - Sound Synthesis

    private func createSoundBuffer(for effect: SoundEffect) -> AVAudioPCMBuffer? {
        switch effect {
        case .hit:
            return synthesizeExplosion(duration: 0.4, lowFreq: 80, highFreq: 200)
        case .miss:
            return synthesizeSplash(duration: 0.5)
        case .sunk:
            return synthesizeSinking(duration: 1.2)
        case .shipPlaced:
            return synthesizeTone(frequency: 440, duration: 0.15, attack: 0.01, decay: 0.14)
        case .buttonTap:
            return synthesizeTone(frequency: 800, duration: 0.05, attack: 0.005, decay: 0.045)
        case .turnStart:
            return synthesizeBell(duration: 0.4)
        case .turnTimeout:
            return synthesizeAlarm(duration: 0.6)
        case .victory:
            return synthesizeVictoryFanfare(duration: 1.0)
        case .defeat:
            return synthesizeDefeatSound(duration: 1.0)
        case .gameStart:
            return synthesizeShipHorn(duration: 0.8)
        }
    }

    /// Synthesizes an explosion sound (hit)
    private func synthesizeExplosion(duration: Float, lowFreq: Float, highFreq: Float) -> AVAudioPCMBuffer? {
        let sampleRate = Float(audioFormat.sampleRate)
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }

        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / sampleRate
            let progress = t / duration

            // Envelope: fast attack, slow decay
            let envelope = exp(-progress * 4.0) * (1.0 - exp(-t * 100))

            // Mix of low rumble and noise
            let lowRumble = sin(2.0 * .pi * lowFreq * t * (1.0 - progress * 0.5))
            let midTone = sin(2.0 * .pi * highFreq * t * (1.0 - progress * 0.3))
            let noise = Float.random(in: -1...1) * (1.0 - progress)

            let sample = envelope * (lowRumble * 0.4 + midTone * 0.2 + noise * 0.4) * 0.6

            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }

        return buffer
    }

    /// Synthesizes a water splash sound (miss)
    private func synthesizeSplash(duration: Float) -> AVAudioPCMBuffer? {
        let sampleRate = Float(audioFormat.sampleRate)
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }

        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / sampleRate
            let progress = t / duration

            // Initial splash burst, then bubbling decay
            let splashEnvelope = exp(-progress * 8.0)
            let bubbleEnvelope = exp(-progress * 3.0) * sin(progress * 20) * 0.3

            // Filtered noise for splash
            let noise = Float.random(in: -1...1)
            // High-pass effect through rapid envelope
            let highFreqComponent = sin(2.0 * .pi * 2000 * t) * exp(-progress * 15)

            let sample = (splashEnvelope * noise * 0.5 + highFreqComponent * 0.2 + bubbleEnvelope * noise * 0.3) * 0.5

            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }

        return buffer
    }

    /// Synthesizes a sinking ship sound
    private func synthesizeSinking(duration: Float) -> AVAudioPCMBuffer? {
        let sampleRate = Float(audioFormat.sampleRate)
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }

        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / sampleRate
            let progress = t / duration

            // Descending pitch
            let baseFreq: Float = 150 * (1.0 - progress * 0.6)

            // Multiple impacts
            let impact1 = exp(-pow((t - 0.0) * 10, 2))
            let impact2 = exp(-pow((t - 0.3) * 10, 2))
            let impact3 = exp(-pow((t - 0.6) * 10, 2))
            let impactEnvelope = impact1 + impact2 * 0.7 + impact3 * 0.5

            // Groaning metal sound (descending)
            let groan = sin(2.0 * .pi * baseFreq * t) * (1.0 - progress)

            // Bubbles
            let bubbles = Float.random(in: -1...1) * progress * exp(-progress * 2)

            let sample = (impactEnvelope * groan * 0.5 + bubbles * 0.3) * 0.6

            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }

        return buffer
    }

    /// Synthesizes a simple tone
    private func synthesizeTone(frequency: Float, duration: Float, attack: Float, decay: Float) -> AVAudioPCMBuffer? {
        let sampleRate = Float(audioFormat.sampleRate)
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }

        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / sampleRate

            // ADSR envelope (simplified)
            var envelope: Float = 0
            if t < attack {
                envelope = t / attack
            } else {
                envelope = exp(-(t - attack) / decay * 3)
            }

            let sample = sin(2.0 * .pi * frequency * t) * envelope * 0.4

            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }

        return buffer
    }

    /// Synthesizes a bell sound (turn start)
    private func synthesizeBell(duration: Float) -> AVAudioPCMBuffer? {
        let sampleRate = Float(audioFormat.sampleRate)
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }

        let frequencies: [Float] = [523.25, 659.25, 783.99]  // C5, E5, G5

        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / sampleRate
            let envelope = exp(-t * 5.0)

            var sample: Float = 0
            for freq in frequencies {
                sample += sin(2.0 * .pi * freq * t) * envelope
            }
            sample = sample / Float(frequencies.count) * 0.4

            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }

        return buffer
    }

    /// Synthesizes an alarm sound (timeout)
    private func synthesizeAlarm(duration: Float) -> AVAudioPCMBuffer? {
        let sampleRate = Float(audioFormat.sampleRate)
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }

        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / sampleRate

            // Oscillating between two frequencies
            let oscRate: Float = 8.0  // Hz
            let freqMod = (sin(2.0 * .pi * oscRate * t) + 1) / 2  // 0 to 1
            let freq = 400 + freqMod * 200  // 400-600 Hz

            let envelope = min(1.0, t * 10) * (1.0 - t / duration)
            let sample = sin(2.0 * .pi * freq * t) * envelope * 0.4

            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }

        return buffer
    }

    /// Synthesizes a victory fanfare
    private func synthesizeVictoryFanfare(duration: Float) -> AVAudioPCMBuffer? {
        let sampleRate = Float(audioFormat.sampleRate)
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }

        // Ascending notes: C, E, G, C (octave up)
        let notes: [(freq: Float, start: Float, noteDuration: Float)] = [
            (261.63, 0.0, 0.2),    // C4
            (329.63, 0.2, 0.2),    // E4
            (392.00, 0.4, 0.2),    // G4
            (523.25, 0.6, 0.4)     // C5 (held longer)
        ]

        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / sampleRate
            var sample: Float = 0

            for note in notes {
                let noteT = t - note.start
                if noteT >= 0 && noteT < note.noteDuration {
                    let envelope = min(1.0, noteT * 20) * exp(-noteT * 3)
                    sample += sin(2.0 * .pi * note.freq * noteT) * envelope
                }
            }

            sample = sample * 0.4

            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }

        return buffer
    }

    /// Synthesizes a defeat sound (descending)
    private func synthesizeDefeatSound(duration: Float) -> AVAudioPCMBuffer? {
        let sampleRate = Float(audioFormat.sampleRate)
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }

        // Descending notes: C, B, Bb, A (sad progression)
        let notes: [(freq: Float, start: Float, noteDuration: Float)] = [
            (261.63, 0.0, 0.25),   // C4
            (246.94, 0.25, 0.25),  // B3
            (233.08, 0.5, 0.25),   // Bb3
            (220.00, 0.75, 0.35)   // A3 (held)
        ]

        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / sampleRate
            var sample: Float = 0

            for note in notes {
                let noteT = t - note.start
                if noteT >= 0 && noteT < note.noteDuration + 0.1 {
                    let envelope = min(1.0, noteT * 10) * exp(-noteT * 2)
                    sample += sin(2.0 * .pi * note.freq * noteT) * envelope
                }
            }

            sample = sample * 0.35

            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }

        return buffer
    }

    /// Synthesizes a ship horn sound (game start)
    private func synthesizeShipHorn(duration: Float) -> AVAudioPCMBuffer? {
        let sampleRate = Float(audioFormat.sampleRate)
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }

        let baseFreq: Float = 180  // Low foghorn frequency

        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / sampleRate
            let progress = t / duration

            // Slow attack, sustain, slow release
            var envelope: Float
            if progress < 0.15 {
                envelope = progress / 0.15
            } else if progress < 0.7 {
                envelope = 1.0
            } else {
                envelope = (1.0 - progress) / 0.3
            }

            // Rich harmonic content for foghorn
            let fundamental = sin(2.0 * .pi * baseFreq * t)
            let harmonic2 = sin(2.0 * .pi * baseFreq * 2 * t) * 0.5
            let harmonic3 = sin(2.0 * .pi * baseFreq * 3 * t) * 0.25

            // Slight vibrato
            let vibrato = sin(2.0 * .pi * 5 * t) * 0.02
            let sample = (fundamental + harmonic2 + harmonic3) * envelope * (1 + vibrato) * 0.3

            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }

        return buffer
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
