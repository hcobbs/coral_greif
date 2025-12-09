//
//  TurnManager.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import Foundation

// MARK: - Turn Manager Delegate

/// Delegate protocol for receiving turn timer events.
protocol TurnManagerDelegate: AnyObject {
    /// Called every second with the remaining time.
    func turnManager(_ manager: TurnManager, didUpdateRemainingTime seconds: Int)

    /// Called when the turn timer expires.
    func turnManagerDidTimeout(_ manager: TurnManager)
}

// MARK: - Turn Manager

/// Manages turn timing using interrupt-driven Timer callbacks.
/// No polling. Timer fires callbacks at specified intervals.
final class TurnManager {

    // MARK: - Properties

    /// Delegate for receiving timer events.
    weak var delegate: TurnManagerDelegate?

    /// Total duration of the turn in seconds.
    let duration: TimeInterval

    /// Remaining time in seconds.
    private(set) var remainingSeconds: Int

    /// The underlying timer.
    private var timer: Timer?

    /// Whether the timer is currently running.
    private(set) var isRunning: Bool = false

    // MARK: - Initialization

    /// Creates a new turn manager with the specified duration.
    /// - Parameter duration: Turn duration in seconds
    init(duration: TimeInterval) {
        self.duration = duration
        self.remainingSeconds = Int(duration)
    }

    deinit {
        stop()
    }

    // MARK: - Timer Control

    /// Starts the turn timer.
    func start() {
        guard !isRunning else { return }

        remainingSeconds = Int(duration)
        isRunning = true

        // Fire immediately with initial value
        delegate?.turnManager(self, didUpdateRemainingTime: remainingSeconds)

        // Schedule timer to fire every second
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(timerFired),
            userInfo: nil,
            repeats: true
        )

        // Ensure timer fires even during UI tracking (scrolling, etc.)
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// Stops the turn timer.
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    /// Pauses the turn timer.
    func pause() {
        timer?.invalidate()
        timer = nil
        // Keep isRunning true so we know we were running
    }

    /// Resumes a paused timer.
    func resume() {
        guard isRunning, timer == nil else { return }

        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(timerFired),
            userInfo: nil,
            repeats: true
        )

        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    // MARK: - Timer Callback

    /// Called every second by the timer.
    @objc private func timerFired() {
        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            stop()
            delegate?.turnManagerDidTimeout(self)
        } else {
            delegate?.turnManager(self, didUpdateRemainingTime: remainingSeconds)
        }
    }
}

// MARK: - Turn Manager Configuration

/// Configuration options for turn timing.
struct TurnConfiguration: Equatable, Sendable {
    /// Standard turn duration (20 seconds).
    static let standard = TurnConfiguration(duration: 20)

    /// Relaxed turn duration (30 seconds).
    static let relaxed = TurnConfiguration(duration: 30)

    /// No time limit.
    static let untimed = TurnConfiguration(duration: .infinity)

    /// Turn duration in seconds.
    let duration: TimeInterval

    /// Whether this configuration has a time limit.
    var hasTimeLimit: Bool {
        return duration.isFinite
    }
}
