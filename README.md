# Coral Greif

A naval warfare strategy game for iOS. Sink enemy ships before they sink yours. No luck involved, just tactics and the occasional educated guess.

## What Is This?

Coral Greif is a Battleship-style game set in the WWII Pacific theater. You command a fleet of historically-named vessels against AI opponents (and eventually other humans, if they can handle the pressure).

The name is a pun. Coral grief. Like the reefs, but sadder. For your opponents.

## Features

- **Single Player vs AI**: Multiple difficulty levels from "barely trying" to "suspiciously good"
- **Turn-based Combat**: 20-second turn timer keeps things moving
- **Historical Flavor**: Ships named after actual WWII Pacific vessels
- **Player Profiles**: Track your stats, wins, and spectacular failures
- **No Ads, No Microtransactions**: You paid for the game. That should be enough.

## Technical Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Building

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Build
xcodebuild -scheme CoralGreif -destination 'platform=iOS Simulator,name=iPhone 17'

# Run tests
xcodebuild test -scheme CoralGreif -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Project Structure

```
CoralGreif/
├── Core/
│   └── Models/           # Data models (Coordinate, Ship, Board, etc.)
├── Engine/               # Game logic and AI (Phase 2)
├── Persistence/          # Save/load functionality (Phase 3)
├── UI/                   # UIKit views and controllers (Phase 4)
└── Visualization/        # SpriteKit rendering (Phase 5)

CoralGreifTests/
└── Models/               # Unit tests for all models
```

## Architecture

The game follows a clean separation of concerns:

1. **Models**: Immutable data structures. No business logic leakage.
2. **Engine**: Game rules, turn management, AI decision-making.
3. **Persistence**: Local storage via UserDefaults and Codable. No cloud dependency.
4. **UI**: Standard UIKit. Works reliably.
5. **Visualization**: SpriteKit for the game board. Animations that don't make you seasick.

All interfaces are interrupt-driven. No polling. If you see a timer spinning in a loop somewhere, that's a bug.

## Development Philosophy

- **Test coverage is not optional.** Every model has tests. Every edge case has tests. If it compiles but isn't tested, it doesn't exist yet.
- **Security first.** Input validation at boundaries. No trusting external data.
- **Simple over clever.** Readable code beats clever code. Every time.

## Contributing

This is a personal project. If you've somehow found it and want to contribute, open an issue first. Cold PRs will be evaluated with appropriate skepticism.

## Disclaimer

**This is a technology demonstration only.** This software is provided as-is for educational and demonstration purposes. It is not recommended for production use. The author takes no responsibility for any issues arising from the use of this code.

## License

Copyright (C) 2024 T. Hunter Cobbs

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. See [LICENSE](LICENSE) for details.

## Documentation

- [Game Manual](Documentation/GameManual.md): How to play
- [Privacy Policy](Documentation/PrivacyPolicy.md): What data we collect (spoiler: almost none)
- [Development Plan](PLAN.md): Technical roadmap

---

*"The only easy day was yesterday."* - Navy SEALs, but also applicable to debugging iOS simulators
