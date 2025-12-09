//
//  TurnManagerTests.swift
//  Coral Greif Tests
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import XCTest
@testable import CoralGreif

// MARK: - Mock Delegate

final class MockTurnManagerDelegate: TurnManagerDelegate {
    var timeUpdates: [Int] = []
    var didTimeout = false
    var timeoutExpectation: XCTestExpectation?
    var updateExpectation: XCTestExpectation?

    func turnManager(_ manager: TurnManager, didUpdateRemainingTime seconds: Int) {
        timeUpdates.append(seconds)
        updateExpectation?.fulfill()
    }

    func turnManagerDidTimeout(_ manager: TurnManager) {
        didTimeout = true
        timeoutExpectation?.fulfill()
    }
}

// MARK: - Turn Manager Tests

final class TurnManagerTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitialization() {
        let manager = TurnManager(duration: 20)

        XCTAssertEqual(manager.duration, 20)
        XCTAssertEqual(manager.remainingSeconds, 20)
        XCTAssertFalse(manager.isRunning)
    }

    func testInitializationWithCustomDuration() {
        let manager = TurnManager(duration: 30)

        XCTAssertEqual(manager.duration, 30)
        XCTAssertEqual(manager.remainingSeconds, 30)
    }

    // MARK: - Start/Stop Tests

    func testStartSetsIsRunning() {
        let manager = TurnManager(duration: 20)

        manager.start()

        XCTAssertTrue(manager.isRunning)

        manager.stop()
    }

    func testStopClearsIsRunning() {
        let manager = TurnManager(duration: 20)

        manager.start()
        manager.stop()

        XCTAssertFalse(manager.isRunning)
    }

    func testStartFiresImmediateUpdate() {
        let manager = TurnManager(duration: 20)
        let delegate = MockTurnManagerDelegate()
        manager.delegate = delegate

        manager.start()

        XCTAssertEqual(delegate.timeUpdates, [20])

        manager.stop()
    }

    func testDoubleStartDoesNothing() {
        let manager = TurnManager(duration: 20)
        let delegate = MockTurnManagerDelegate()
        manager.delegate = delegate

        manager.start()
        manager.start()

        XCTAssertEqual(delegate.timeUpdates.count, 1)

        manager.stop()
    }

    // MARK: - Timer Tests

    func testTimerUpdatesEverySecond() {
        let expectation = expectation(description: "Timer updates")
        expectation.expectedFulfillmentCount = 3

        let manager = TurnManager(duration: 5)
        let delegate = MockTurnManagerDelegate()
        delegate.updateExpectation = expectation
        manager.delegate = delegate

        manager.start()

        waitForExpectations(timeout: 4) { _ in
            manager.stop()
            // Should have initial (5) + at least 2 updates (4, 3)
            XCTAssertTrue(delegate.timeUpdates.count >= 3)
        }
    }

    func testTimerTimeoutAfterDuration() {
        let expectation = expectation(description: "Timeout")

        let manager = TurnManager(duration: 2)
        let delegate = MockTurnManagerDelegate()
        delegate.timeoutExpectation = expectation
        manager.delegate = delegate

        manager.start()

        waitForExpectations(timeout: 4) { _ in
            XCTAssertTrue(delegate.didTimeout)
            XCTAssertFalse(manager.isRunning)
        }
    }

    // MARK: - Pause/Resume Tests

    func testPauseStopsTimer() {
        let manager = TurnManager(duration: 20)
        let delegate = MockTurnManagerDelegate()
        manager.delegate = delegate

        manager.start()
        manager.pause()

        let initialCount = delegate.timeUpdates.count

        // Wait a bit
        let expectation = expectation(description: "Wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2) { _ in
            // Count should not have increased
            XCTAssertEqual(delegate.timeUpdates.count, initialCount)
            manager.stop()
        }
    }

    func testResumeAfterPause() {
        let expectation = expectation(description: "Resume")

        let manager = TurnManager(duration: 10)
        let delegate = MockTurnManagerDelegate()
        manager.delegate = delegate

        manager.start()
        manager.pause()

        let initialCount = delegate.timeUpdates.count

        // Resume after a brief pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            manager.resume()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                XCTAssertTrue(delegate.timeUpdates.count > initialCount)
                manager.stop()
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3)
    }

    // MARK: - Configuration Tests

    func testStandardConfiguration() {
        let config = TurnConfiguration.standard

        XCTAssertEqual(config.duration, 20)
        XCTAssertTrue(config.hasTimeLimit)
    }

    func testRelaxedConfiguration() {
        let config = TurnConfiguration.relaxed

        XCTAssertEqual(config.duration, 30)
        XCTAssertTrue(config.hasTimeLimit)
    }

    func testUntimedConfiguration() {
        let config = TurnConfiguration.untimed

        XCTAssertFalse(config.hasTimeLimit)
    }

    func testConfigurationEquality() {
        XCTAssertEqual(TurnConfiguration.standard, TurnConfiguration(duration: 20))
        XCTAssertNotEqual(TurnConfiguration.standard, TurnConfiguration.relaxed)
    }
}
