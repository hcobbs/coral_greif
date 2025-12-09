# Coral Greif Implementation Plan

## Overview

Turn-based naval strategy game (Battleship variant) for iOS. Single-player vs AI with WWII Pacific theater theme.

## Architecture

```
CoralGreif/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Core/
│   ├── Models/
│   │   ├── Profile.swift          # Player/AI identity
│   │   ├── Ship.swift             # Ship types, positions, damage state
│   │   ├── Board.swift            # 10x10 grid, ship placements
│   │   ├── Cell.swift             # Grid cell state (empty, ship, hit, miss)
│   │   ├── Move.swift             # Attack coordinates, result
│   │   └── GameState.swift        # Full game snapshot
│   ├── Engine/
│   │   ├── GameEngine.swift       # Core game logic, rule enforcement
│   │   ├── TurnManager.swift      # Turn sequencing, timeout handling
│   │   └── WinCondition.swift     # Victory detection
│   └── AI/
│       ├── AIPlayer.swift         # AI decision interface
│       └── HuntTargetAI.swift     # Hunt/Target algorithm
├── UI/
│   ├── Scenes/
│   │   ├── MainMenuScene.swift    # Title, play button
│   │   ├── SetupScene.swift       # Ship placement
│   │   ├── BattleScene.swift      # Main gameplay
│   │   └── ResultScene.swift      # Win/lose screen
│   ├── Components/
│   │   ├── GridView.swift         # Reusable 10x10 grid
│   │   ├── ShipSprite.swift       # Ship visual representation
│   │   ├── CellSprite.swift       # Grid cell with state
│   │   └── TimerDisplay.swift     # 20-second countdown
│   └── Theme/
│       ├── PacificTheme.swift     # Colors, fonts, styling
│       └── PunGenerator.swift     # Context-aware quips
├── Audio/
│   └── SoundManager.swift         # Sound effects (interrupt-driven)
└── Resources/
    ├── Assets.xcassets/
    ├── Sounds/
    └── Fonts/
```

## Models

### Profile
```
- id: UUID
- name: String
- isAI: Bool
- avatar: String (optional)
- stats: ProfileStats (wins, losses, hits, misses)
```

### Ship (WWII Pacific Fleet)
```
Types:
- Carrier (5 cells)      # USS Enterprise style
- Battleship (4 cells)   # USS Missouri style
- Cruiser (3 cells)      # USS Indianapolis style
- Submarine (3 cells)    # USS Wahoo style
- Destroyer (2 cells)    # USS Johnston style

Properties:
- type: ShipType
- origin: Coordinate
- orientation: Orientation (horizontal, vertical)
- hits: Set<Coordinate>
- isSunk: Bool (computed)
```

### Board
```
- grid: [[Cell]] (10x10)
- ships: [Ship]
- placeShip(Ship, at: Coordinate, orientation: Orientation) -> Result
- receiveAttack(at: Coordinate) -> AttackResult
- allShipsSunk: Bool
```

### Cell
```
enum CellState:
- empty
- ship(Ship)
- hit
- miss
```

### Move
```
- player: Profile
- coordinate: Coordinate
- timestamp: Date
- result: AttackResult (hit, miss, sunk(ShipType))
```

## Game Flow

### Phase 1: Setup
1. Load/create player profile
2. AI profile auto-generated
3. Random first-move assignment (coin flip)
4. Player places ships (drag/drop or auto-place)
5. AI places ships (random valid placement)

### Phase 2: Battle
1. Active player's turn begins
2. 20-second timer starts (Timer with delegate callback, not polling)
3. Player taps enemy grid to attack OR timeout triggers random attack
4. Attack resolves: hit/miss/sunk
5. Pun displayed based on result
6. Check win condition
7. Switch turns

### Phase 3: Result
1. Display winner
2. Show battle statistics
3. Update profiles
4. Return to menu

## Turn Timer Implementation

Interrupt-driven using Timer with target-action pattern:
```swift
private var turnTimer: Timer?

func startTurn() {
    turnTimer = Timer.scheduledTimer(
        timeInterval: 20.0,
        target: self,
        selector: #selector(turnTimeout),
        userInfo: nil,
        repeats: false
    )
}

@objc private func turnTimeout() {
    // Force random valid move
}

func endTurn() {
    turnTimer?.invalidate()
    turnTimer = nil
}
```

## AI Strategy (Hunt/Target)

**Hunt Mode**: Random attacks on unchecked cells
**Target Mode**: After hit, systematically check adjacent cells

```
States:
- hunting: No active targets
- targeting(lastHit: Coordinate, direction: Direction?)

On hit:
- If hunting -> switch to targeting
- If targeting -> continue in direction

On miss:
- If targeting -> try next direction or return to hunting

On sunk:
- Return to hunting
```

## Pun System

Categories with context triggers:
```
onHit: ["That's gonna leave a mark!", "Bullseye! Or should I say, hull's eye?", ...]
onMiss: ["Splash! The fish thank you.", "Water you doing?", ...]
onSunk: ["Down to Davy Jones!", "Glub glub glub...", ...]
onThreeMisses: ["Need glasses?", "The ocean is big, ships are small...", ...]
onGettingHit: ["Ow! That was my favorite hull!", ...]
```

## UI Layout (Battle Scene)

```
+----------------------------------+
|  [Enemy Name]          [Timer]   |
|  +------------------------+      |
|  |    ENEMY GRID (10x10) |      |
|  |    (tap to attack)    |      |
|  +------------------------+      |
|                                  |
|  [Pun/Status Message Area]       |
|                                  |
|  +------------------------+      |
|  |    YOUR GRID (10x10)  |      |
|  |    (shows your ships) |      |
|  +------------------------+      |
|  [Your Name]        [Ship Status]|
+----------------------------------+
```

## Test Coverage Requirements

### Unit Tests (CoralGreifTests/)
1. **Model Tests**
   - Profile creation, stat updates
   - Ship placement validation
   - Board attack resolution
   - Cell state transitions
   - Move recording

2. **Engine Tests**
   - Turn sequencing
   - Win condition detection
   - Timeout handling
   - Random first-move fairness

3. **AI Tests**
   - Hunt mode coverage
   - Target mode directional logic
   - Edge cases (corners, borders)
   - No invalid moves

### UI Tests (CoralGreifUITests/)
1. Ship placement drag/drop
2. Attack tap registration
3. Timer display accuracy
4. Scene transitions

## Implementation Phases

### Phase 1: Core Models
- [ ] Profile model with stats
- [ ] Ship model with WWII types
- [ ] Board model with placement/attack logic
- [ ] Cell and Move models
- [ ] GameState for full snapshots
- [ ] Unit tests for all models (100% coverage)

### Phase 2: Game Engine
- [ ] GameEngine with rule enforcement
- [ ] TurnManager with timer (interrupt-driven)
- [ ] WinCondition checker
- [ ] Unit tests for engine (100% coverage)

### Phase 3: AI
- [ ] AIPlayer protocol
- [ ] HuntTargetAI implementation
- [ ] Unit tests for AI (100% coverage)

### Phase 4: UI Foundation
- [ ] SpriteKit scene setup
- [ ] GridView component
- [ ] CellSprite with states
- [ ] ShipSprite rendering

### Phase 5: Game Scenes
- [ ] MainMenuScene
- [ ] SetupScene (ship placement)
- [ ] BattleScene (gameplay)
- [ ] ResultScene

### Phase 6: Polish
- [ ] PacificTheme styling
- [ ] PunGenerator
- [ ] Sound effects
- [ ] Animations

### Phase 7: Integration Testing
- [ ] Full game flow tests
- [ ] Edge case scenarios
- [ ] Performance profiling

## Security Considerations

1. **Input Validation**: All coordinates bounds-checked before processing
2. **State Integrity**: GameState immutable snapshots prevent tampering
3. **AI Fairness**: AI cannot access player's ship positions
4. **Random Generation**: SecureRandom for ship placement and first-move
