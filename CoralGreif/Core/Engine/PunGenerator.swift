//
//  PunGenerator.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import Foundation

// MARK: - Pun Category

/// Categories of puns based on game events.
enum PunCategory {
    case onHit
    case onMiss
    case onSunk(ShipType)
    case onConsecutiveMisses(count: Int)
    case onGettingHit
    case onGettingSunk(ShipType)
    case onVictory
    case onDefeat
    case onGameStart
    case onTurnStart
    case onTimeout
}

// MARK: - Pun Generator

/// Generates contextual puns and quips for game events.
/// All puns are WWII Pacific theater themed.
final class PunGenerator {

    // MARK: - Singleton

    static let shared = PunGenerator()

    private init() {}

    // MARK: - Pun Selection

    /// Returns a random pun for the given category.
    func pun(for category: PunCategory) -> String {
        let puns = getPuns(for: category)
        return puns.randomElement() ?? "..."
    }

    /// Returns all puns for the given category.
    func allPuns(for category: PunCategory) -> [String] {
        return getPuns(for: category)
    }

    // MARK: - Pun Database

    private func getPuns(for category: PunCategory) -> [String] {
        switch category {
        case .onHit:
            return onHitPuns

        case .onMiss:
            return onMissPuns

        case .onSunk(let shipType):
            return getSunkPuns(for: shipType)

        case .onConsecutiveMisses(let count):
            return getConsecutiveMissPuns(count: count)

        case .onGettingHit:
            return onGettingHitPuns

        case .onGettingSunk(let shipType):
            return getGettingSunkPuns(for: shipType)

        case .onVictory:
            return onVictoryPuns

        case .onDefeat:
            return onDefeatPuns

        case .onGameStart:
            return onGameStartPuns

        case .onTurnStart:
            return onTurnStartPuns

        case .onTimeout:
            return onTimeoutPuns
        }
    }

    // MARK: - Pun Collections

    private let onHitPuns = [
        "Direct hit! That's gonna leave a mark.",
        "Bullseye! Or should I say, hull's eye?",
        "Boom! Someone's having a bad day.",
        "Target acquired and neutralized!",
        "That's what we call 'accurate'.",
        "The enemy didn't sea that coming.",
        "Fire in the hole! Well, their hole now.",
        "Scratch one target!",
        "Good effect on target!",
        "That hit was ship-shape!",
        "Nothing but steel. And fire. Mostly fire.",
        "Someone just felt the full force of democracy.",
        "That's going to buff right out. Eventually.",
        "Hit confirmed. Request additional ordnance."
    ]

    private let onMissPuns = [
        "Splash! The fish thank you for the donation.",
        "Water you doing? That was ocean!",
        "Missed by a nautical mile.",
        "The sea remains unimpressed.",
        "Nice shot... at absolutely nothing.",
        "That shot went swimming with the fishes.",
        "Aim small, miss large. Apparently.",
        "You've successfully hydrated the Pacific.",
        "The only casualty was some plankton.",
        "Sonar says that was embarrassing.",
        "Making waves, just not the right ones.",
        "That shell's on a new adventure now.",
        "Ocean: 1, You: 0",
        "Congratulations, you've angered a whale."
    ]

    private let onGettingHitPuns = [
        "Ow! That was my favorite hull!",
        "We've been kissed by ordnance!",
        "Damage control, report!",
        "They're getting warmer...",
        "Note to self: zigzag more.",
        "That's coming out of someone's pay.",
        "Direct hit received. This displeases us.",
        "Well, that's going in the damage report.",
        "Our turn to make waves... involuntarily.",
        "Return fire recommended. Strongly.",
        "Someone's radar is working overtime.",
        "They found us. How rude."
    ]

    private let onVictoryPuns = [
        "Victory! The Pacific is ours!",
        "All enemy vessels eliminated. Time for shore leave.",
        "Mission accomplished! Break out the good coffee.",
        "The enemy fleet sleeps with the fishes.",
        "Flawless victory! Well, mostly flawless.",
        "That's how it's done in the Navy.",
        "The sea is clear. Admiral would be proud.",
        "Enemy defeated. History books, here we come.",
        "A decisive naval victory for the ages!",
        "Clear skies, calm seas, no enemies. Perfect."
    ]

    private let onDefeatPuns = [
        "We're taking on water... and regret.",
        "All hands abandon ship. And dignity.",
        "The enemy got lucky. Several times, apparently.",
        "Defeat, but with honor. Mostly.",
        "Even the Titanic had a better day.",
        "Request immediate extraction... and therapy.",
        "We gave them a good fight. They gave us worse.",
        "The ocean claims another fleet.",
        "Someone's going down with the ship. It's us.",
        "Defeat: the other kind of naval experience."
    ]

    private let onGameStartPuns = [
        "Battle stations! This is not a drill!",
        "All hands to combat positions!",
        "May the best admiral win.",
        "The Pacific awaits. Try not to become part of it.",
        "Deploy the fleet. It's hunting season.",
        "Ready all batteries. Show them what we've got.",
        "The enemy won't sink themselves. Usually.",
        "Time to make some waves.",
        "General quarters, general quarters!",
        "Fair winds and following shells."
    ]

    private let onTurnStartPuns = [
        "Your move, Admiral.",
        "The enemy awaits your decision.",
        "Choose your target wisely.",
        "Fire at will. Will is over there somewhere.",
        "The sea is your canvas. Paint it with ordnance.",
        "Select target. Make it count.",
        "Time to put holes in things.",
        "The enemy fleet mocks your hesitation.",
        "Your move. No pressure. Much pressure, actually."
    ]

    private let onTimeoutPuns = [
        "Time's up! Random fire initiated!",
        "Indecision is also a decision. A bad one.",
        "The gunners got impatient. Shots fired.",
        "Auto-fire engaged. Hope it hits something.",
        "Time ran out. The guns didn't wait.",
        "Hesitation is the enemy. So is the enemy.",
        "Random coordinates selected. Fingers crossed!",
        "The crew took matters into their own hands."
    ]

    // MARK: - Ship-Specific Puns

    private func getSunkPuns(for shipType: ShipType) -> [String] {
        var puns = [
            "Down to Davy Jones!",
            "Glub glub glub...",
            "That's one less problem.",
            "Scratch one \(shipType.displayName.lowercased())!",
            "The \(shipType.displayName.lowercased()) has left the surface.",
            "\(shipType.displayName) eliminated. Next target?"
        ]

        switch shipType {
        case .carrier:
            puns.append(contentsOf: [
                "The carrier has been... decommissioned.",
                "No more planes for them!",
                "Their air support just became seafloor decor.",
                "Enterprise? More like Enter-prize... for us."
            ])
        case .battleship:
            puns.append(contentsOf: [
                "The battleship has met its match!",
                "Big guns, big target, big sinking.",
                "The Missouri just became the Misery.",
                "Battleship down! That's a lot of steel."
            ])
        case .cruiser:
            puns.append(contentsOf: [
                "The cruiser has cruised its last.",
                "Cruising for a bruising? Got it.",
                "Indianapolis has left the building. And the surface."
            ])
        case .submarine:
            puns.append(contentsOf: [
                "The sub has surfaced. Permanently.",
                "Submarine? More like sub-marine-no-more.",
                "They can't dive away from this one.",
                "Depth charge successful!"
            ])
        case .destroyer:
            puns.append(contentsOf: [
                "The destroyer has been... destroyed.",
                "Irony: a destroyer, destroyed.",
                "Small ship, big explosion.",
                "Johnston down! They fought well."
            ])
        }

        return puns
    }

    private func getGettingSunkPuns(for shipType: ShipType) -> [String] {
        var puns = [
            "Our \(shipType.displayName.lowercased()) is going down!",
            "We've lost the \(shipType.displayName.lowercased())!",
            "Abandon \(shipType.displayName.lowercased())!"
        ]

        switch shipType {
        case .carrier:
            puns.append("There goes our air support!")
        case .battleship:
            puns.append("Our big guns are silent now.")
        case .cruiser:
            puns.append("The cruiser has sailed its last voyage.")
        case .submarine:
            puns.append("Our sub is permanently submerged now.")
        case .destroyer:
            puns.append("Lost our smallest but bravest!")
        }

        return puns
    }

    private func getConsecutiveMissPuns(count: Int) -> [String] {
        if count >= 5 {
            return [
                "Are you even trying?",
                "The ocean is very wet now. Thanks to you.",
                "Five misses? That's almost impressive.",
                "Perhaps naval warfare isn't your calling.",
                "The fish are filing a complaint.",
                "You've created a new underwater art installation."
            ]
        } else if count >= 3 {
            return [
                "Need glasses?",
                "The ocean is big, ships are small...",
                "Three misses? Let's change that.",
                "Maybe try a different sector?",
                "Persistence is admirable. Results would be better.",
                "The enemy ships are laughing. Probably."
            ]
        } else {
            return onMissPuns
        }
    }
}

// MARK: - Convenience Extension

extension PunGenerator {

    /// Returns a pun for an attack result.
    func pun(for result: AttackResult, isPlayerAttack: Bool) -> String {
        switch result {
        case .miss:
            return pun(for: isPlayerAttack ? .onMiss : .onGettingHit)
        case .hit:
            return pun(for: isPlayerAttack ? .onHit : .onGettingHit)
        case .sunk(let shipType):
            return pun(for: isPlayerAttack ? .onSunk(shipType) : .onGettingSunk(shipType))
        }
    }
}
