import XCTest
@testable import CoralGreif

final class ProfileTests: XCTestCase {

    // MARK: - Human Profile Tests

    func testHumanProfileCreation() {
        let profile = Profile(name: "Admiral")

        XCTAssertEqual(profile.name, "Admiral")
        XCTAssertFalse(profile.isAI)
        XCTAssertNil(profile.avatarId)
        XCTAssertNotNil(profile.id)
    }

    func testHumanProfileHasEmptyStats() {
        let profile = Profile(name: "Admiral")

        XCTAssertEqual(profile.stats.gamesWon, 0)
        XCTAssertEqual(profile.stats.gamesLost, 0)
        XCTAssertEqual(profile.stats.totalHits, 0)
        XCTAssertEqual(profile.stats.totalMisses, 0)
        XCTAssertEqual(profile.stats.totalShipsSunk, 0)
    }

    func testHumanProfileHasCreationDate() {
        let before = Date()
        let profile = Profile(name: "Admiral")
        let after = Date()

        XCTAssertGreaterThanOrEqual(profile.createdAt, before)
        XCTAssertLessThanOrEqual(profile.createdAt, after)
    }

    // MARK: - AI Profile Tests

    func testAIProfileCreation() {
        let profile = Profile.aiPlayer(name: "CPU Opponent")

        XCTAssertEqual(profile.name, "CPU Opponent")
        XCTAssertTrue(profile.isAI)
    }

    func testAIProfileWithAvatar() {
        let profile = Profile.aiPlayer(name: "Hard AI", avatarId: "admiral_yamamoto")

        XCTAssertEqual(profile.avatarId, "admiral_yamamoto")
    }

    // MARK: - Full Initializer Tests

    func testFullInitializer() {
        let testId = UUID()
        let testDate = Date(timeIntervalSince1970: 0)
        let testStats = ProfileStats(gamesWon: 10, gamesLost: 5, totalHits: 100, totalMisses: 50, totalShipsSunk: 25)

        let profile = Profile(
            id: testId,
            name: "Test Player",
            isAI: false,
            avatarId: "test_avatar",
            stats: testStats,
            createdAt: testDate
        )

        XCTAssertEqual(profile.id, testId)
        XCTAssertEqual(profile.name, "Test Player")
        XCTAssertFalse(profile.isAI)
        XCTAssertEqual(profile.avatarId, "test_avatar")
        XCTAssertEqual(profile.stats, testStats)
        XCTAssertEqual(profile.createdAt, testDate)
    }

    // MARK: - Record Game Tests

    func testRecordGameWin() {
        var profile = Profile(name: "Admiral")

        profile.recordGame(won: true, hits: 20, misses: 10, shipsSunk: 5)

        XCTAssertEqual(profile.stats.gamesWon, 1)
        XCTAssertEqual(profile.stats.gamesLost, 0)
        XCTAssertEqual(profile.stats.totalHits, 20)
        XCTAssertEqual(profile.stats.totalMisses, 10)
        XCTAssertEqual(profile.stats.totalShipsSunk, 5)
    }

    func testRecordGameLoss() {
        var profile = Profile(name: "Admiral")

        profile.recordGame(won: false, hits: 15, misses: 20, shipsSunk: 3)

        XCTAssertEqual(profile.stats.gamesWon, 0)
        XCTAssertEqual(profile.stats.gamesLost, 1)
        XCTAssertEqual(profile.stats.totalHits, 15)
        XCTAssertEqual(profile.stats.totalMisses, 20)
        XCTAssertEqual(profile.stats.totalShipsSunk, 3)
    }

    func testRecordMultipleGames() {
        var profile = Profile(name: "Admiral")

        profile.recordGame(won: true, hits: 20, misses: 10, shipsSunk: 5)
        profile.recordGame(won: false, hits: 15, misses: 25, shipsSunk: 3)
        profile.recordGame(won: true, hits: 18, misses: 12, shipsSunk: 5)

        XCTAssertEqual(profile.stats.gamesWon, 2)
        XCTAssertEqual(profile.stats.gamesLost, 1)
        XCTAssertEqual(profile.stats.totalHits, 53)
        XCTAssertEqual(profile.stats.totalMisses, 47)
        XCTAssertEqual(profile.stats.totalShipsSunk, 13)
    }

    // MARK: - Equatable Tests

    func testProfileEqualityById() {
        let testId = UUID()
        let testDate = Date(timeIntervalSince1970: 1000)
        let profile1 = Profile(
            id: testId,
            name: "Player",
            isAI: false,
            avatarId: nil,
            stats: ProfileStats(),
            createdAt: testDate
        )
        let profile2 = Profile(
            id: testId,
            name: "Player",
            isAI: false,
            avatarId: nil,
            stats: ProfileStats(),
            createdAt: testDate
        )

        XCTAssertEqual(profile1, profile2)
    }

    func testProfileInequalityByDifferentId() {
        let profile1 = Profile(name: "Player")
        let profile2 = Profile(name: "Player")

        XCTAssertNotEqual(profile1, profile2)
    }

    // MARK: - Codable Tests

    func testCodableRoundTrip() throws {
        var original = Profile(name: "Admiral")
        original.recordGame(won: true, hits: 20, misses: 10, shipsSunk: 5)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Profile.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.isAI, decoded.isAI)
        XCTAssertEqual(original.stats, decoded.stats)
    }

    // MARK: - Mutable Name Tests

    func testNameCanBeChanged() {
        var profile = Profile(name: "OldName")
        profile.name = "NewName"

        XCTAssertEqual(profile.name, "NewName")
    }

    func testAvatarCanBeChanged() {
        var profile = Profile(name: "Player")
        profile.avatarId = "new_avatar"

        XCTAssertEqual(profile.avatarId, "new_avatar")
    }
}

// MARK: - ProfileStats Tests

final class ProfileStatsTests: XCTestCase {

    func testEmptyStatsInitialization() {
        let stats = ProfileStats()

        XCTAssertEqual(stats.gamesWon, 0)
        XCTAssertEqual(stats.gamesLost, 0)
        XCTAssertEqual(stats.totalHits, 0)
        XCTAssertEqual(stats.totalMisses, 0)
        XCTAssertEqual(stats.totalShipsSunk, 0)
    }

    func testFullStatsInitialization() {
        let stats = ProfileStats(gamesWon: 10, gamesLost: 5, totalHits: 100, totalMisses: 50, totalShipsSunk: 25)

        XCTAssertEqual(stats.gamesWon, 10)
        XCTAssertEqual(stats.gamesLost, 5)
        XCTAssertEqual(stats.totalHits, 100)
        XCTAssertEqual(stats.totalMisses, 50)
        XCTAssertEqual(stats.totalShipsSunk, 25)
    }

    func testGamesPlayed() {
        let stats = ProfileStats(gamesWon: 10, gamesLost: 5, totalHits: 0, totalMisses: 0, totalShipsSunk: 0)
        XCTAssertEqual(stats.gamesPlayed, 15)
    }

    func testGamesPlayedEmpty() {
        let stats = ProfileStats()
        XCTAssertEqual(stats.gamesPlayed, 0)
    }

    func testWinRate() {
        let stats = ProfileStats(gamesWon: 7, gamesLost: 3, totalHits: 0, totalMisses: 0, totalShipsSunk: 0)
        XCTAssertEqual(stats.winRate, 70.0, accuracy: 0.01)
    }

    func testWinRateNoGames() {
        let stats = ProfileStats()
        XCTAssertEqual(stats.winRate, 0.0)
    }

    func testWinRateAllWins() {
        let stats = ProfileStats(gamesWon: 10, gamesLost: 0, totalHits: 0, totalMisses: 0, totalShipsSunk: 0)
        XCTAssertEqual(stats.winRate, 100.0)
    }

    func testWinRateNoWins() {
        let stats = ProfileStats(gamesWon: 0, gamesLost: 10, totalHits: 0, totalMisses: 0, totalShipsSunk: 0)
        XCTAssertEqual(stats.winRate, 0.0)
    }

    func testAccuracy() {
        let stats = ProfileStats(gamesWon: 0, gamesLost: 0, totalHits: 60, totalMisses: 40, totalShipsSunk: 0)
        XCTAssertEqual(stats.accuracy, 60.0, accuracy: 0.01)
    }

    func testAccuracyNoShots() {
        let stats = ProfileStats()
        XCTAssertEqual(stats.accuracy, 0.0)
    }

    func testAccuracyPerfect() {
        let stats = ProfileStats(gamesWon: 0, gamesLost: 0, totalHits: 100, totalMisses: 0, totalShipsSunk: 0)
        XCTAssertEqual(stats.accuracy, 100.0)
    }

    func testAccuracyZero() {
        let stats = ProfileStats(gamesWon: 0, gamesLost: 0, totalHits: 0, totalMisses: 100, totalShipsSunk: 0)
        XCTAssertEqual(stats.accuracy, 0.0)
    }

    func testStatsEquality() {
        let stats1 = ProfileStats(gamesWon: 5, gamesLost: 3, totalHits: 50, totalMisses: 30, totalShipsSunk: 10)
        let stats2 = ProfileStats(gamesWon: 5, gamesLost: 3, totalHits: 50, totalMisses: 30, totalShipsSunk: 10)
        XCTAssertEqual(stats1, stats2)
    }

    func testStatsInequality() {
        let stats1 = ProfileStats(gamesWon: 5, gamesLost: 3, totalHits: 50, totalMisses: 30, totalShipsSunk: 10)
        let stats2 = ProfileStats(gamesWon: 6, gamesLost: 3, totalHits: 50, totalMisses: 30, totalShipsSunk: 10)
        XCTAssertNotEqual(stats1, stats2)
    }

    func testStatsCodable() throws {
        let original = ProfileStats(gamesWon: 5, gamesLost: 3, totalHits: 50, totalMisses: 30, totalShipsSunk: 10)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProfileStats.self, from: data)

        XCTAssertEqual(original, decoded)
    }
}
