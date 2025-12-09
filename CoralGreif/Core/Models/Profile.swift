//
//  Profile.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import Foundation

/// Represents a player profile (human or AI).
struct Profile: Identifiable, Equatable, Codable, Sendable {
    /// Unique identifier for this profile.
    let id: UUID

    /// Display name for the player.
    var name: String

    /// Whether this profile represents an AI player.
    let isAI: Bool

    /// Optional avatar identifier.
    var avatarId: String?

    /// Player statistics.
    var stats: ProfileStats

    /// Date the profile was created.
    let createdAt: Date

    /// Creates a new human player profile.
    /// - Parameter name: The player's display name
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.isAI = false
        self.avatarId = nil
        self.stats = ProfileStats()
        self.createdAt = Date()
    }

    /// Creates a new AI player profile.
    /// - Parameters:
    ///   - name: The AI's display name
    ///   - difficulty: Optional difficulty identifier for avatar selection
    static func aiPlayer(name: String, avatarId: String? = nil) -> Profile {
        let profile = Profile(id: UUID(), name: name, isAI: true, avatarId: avatarId)
        return profile
    }

    /// Internal initializer for full control over all properties.
    private init(id: UUID, name: String, isAI: Bool, avatarId: String?) {
        self.id = id
        self.name = name
        self.isAI = isAI
        self.avatarId = avatarId
        self.stats = ProfileStats()
        self.createdAt = Date()
    }

    /// Creates a profile with specific values (for testing or loading saved data).
    init(
        id: UUID,
        name: String,
        isAI: Bool,
        avatarId: String?,
        stats: ProfileStats,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.isAI = isAI
        self.avatarId = avatarId
        self.stats = stats
        self.createdAt = createdAt
    }

    /// Records a game result for this profile.
    /// - Parameters:
    ///   - won: Whether the player won
    ///   - hits: Number of successful hits
    ///   - misses: Number of missed attacks
    ///   - shipsSunk: Number of enemy ships sunk
    mutating func recordGame(won: Bool, hits: Int, misses: Int, shipsSunk: Int) {
        if won {
            stats.gamesWon += 1
        } else {
            stats.gamesLost += 1
        }
        stats.totalHits += hits
        stats.totalMisses += misses
        stats.totalShipsSunk += shipsSunk
    }
}

// MARK: - ProfileStats

/// Statistics tracked for a player profile.
struct ProfileStats: Equatable, Codable, Sendable {
    /// Total games won.
    var gamesWon: Int

    /// Total games lost.
    var gamesLost: Int

    /// Total successful hits across all games.
    var totalHits: Int

    /// Total missed attacks across all games.
    var totalMisses: Int

    /// Total enemy ships sunk across all games.
    var totalShipsSunk: Int

    /// Creates empty stats.
    init() {
        self.gamesWon = 0
        self.gamesLost = 0
        self.totalHits = 0
        self.totalMisses = 0
        self.totalShipsSunk = 0
    }

    /// Creates stats with specific values.
    init(gamesWon: Int, gamesLost: Int, totalHits: Int, totalMisses: Int, totalShipsSunk: Int) {
        self.gamesWon = gamesWon
        self.gamesLost = gamesLost
        self.totalHits = totalHits
        self.totalMisses = totalMisses
        self.totalShipsSunk = totalShipsSunk
    }

    /// Total games played.
    var gamesPlayed: Int {
        return gamesWon + gamesLost
    }

    /// Win rate as a percentage (0-100).
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100
    }

    /// Hit accuracy as a percentage (0-100).
    var accuracy: Double {
        let totalShots = totalHits + totalMisses
        guard totalShots > 0 else { return 0 }
        return Double(totalHits) / Double(totalShots) * 100
    }
}
