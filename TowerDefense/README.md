# iOS Tower Defense - Dynamic Pathfinding

Een complete Tower Defense game voor iOS met **dynamische obstacle-based pathfinding**. Vijanden navigeren in real-time om geplaatste torens heen - geen vaste paden!

## 🎮 Features

- **Dynamische Pathfinding**: Vijanden berekenen hun route in real-time met een Flow Field algoritme
- **8 Unieke Torens**: Elk met eigen strategie en upgrade-pad
- **3 Vijandtypes**: Infantry, Cavalry (gepantserd), en Flying (negeert obstakels)
- **Pad-validatie**: Torens kunnen niet geplaatst worden als ze alle paden blokkeren
- **11 Levels**: Tutorial + 10 levels met 20-50 waves elk
- **Economy systeem**: Verdien geld door vijanden te doden, koop en upgrade torens
- **Procedural Audio**: Synthesized sound effects voor alle acties
- **Flying Mechanics**: Vliegende vijanden zijn NIET padgebonden maar wel zwakker

## 🛠 Technologie Keuze: SpriteKit

**Waarom SpriteKit en niet Unity?**

1. **Native Performance**: Direct gecompileerd voor iOS, geen runtime overhead
2. **Kleinere App Size**: Geen externe engine bundled (Unity ~50MB+ overhead)
3. **Directe iOS Integratie**: Naadloze toegang tot iOS APIs
4. **Swift First**: Modern, type-safe Swift code
5. **Geen Licentiekosten**: Apple's eigen framework

## 📁 Project Structuur

```
TowerDefense/
├── TowerDefense.xcodeproj/
├── TowerDefense/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── GameViewController.swift
│   │
│   ├── Core/
│   │   ├── GameScene.swift        # Hoofdscene
│   │   ├── GameManager.swift      # Game state
│   │   ├── Constants.swift        # Enums & constanten
│   │   └── Extensions.swift       # Helpers
│   │
│   ├── Pathfinding/
│   │   ├── PathfindingGrid.swift  # Grid walkability
│   │   ├── AStarPathfinder.swift  # A* validatie
│   │   └── FlowField.swift        # Navigatie systeem
│   │
│   ├── Entities/
│   │   ├── Enemies/
│   │   │   ├── Enemy.swift        # Base class
│   │   │   ├── InfantryEnemy.swift
│   │   │   ├── CavalryEnemy.swift
│   │   │   └── FlyingEnemy.swift  # Niet padgebonden!
│   │   │
│   │   └── Towers/
│   │       ├── Tower.swift        # Base class
│   │       ├── MachineGunTower.swift
│   │       ├── CannonTower.swift
│   │       ├── SlowTower.swift
│   │       ├── BuffTower.swift
│   │       ├── ShotgunTower.swift
│   │       ├── SplashTower.swift
│   │       ├── LaserTower.swift   # NIEUW: Piercing beam
│   │       ├── AntiAirTower.swift # NIEUW: Anti-vliegtuig
│   │       └── Projectile.swift
│   │
│   ├── Systems/
│   │   ├── WaveManager.swift
│   │   ├── EconomyManager.swift
│   │   ├── PlacementValidator.swift
│   │   ├── TargetingSystem.swift
│   │   ├── AudioManager.swift     # Procedural audio
│   │   └── LevelManager.swift     # 11 levels
│   │
│   ├── UI/
│   │   ├── HUDNode.swift
│   │   ├── BuildMenuNode.swift
│   │   ├── TowerInfoNode.swift
│   │   └── PlacementPreviewNode.swift
│   │
│   ├── Config/
│   │   ├── GameConfig.swift
│   │   └── WaveConfig.json
│   │
│   └── Resources/
│       ├── Assets.xcassets/
│       ├── AppIconGenerator.swift
│       ├── Main.storyboard
│       └── LaunchScreen.storyboard
```

## ✈️ Flying Units - Speciale Mechanics

Flying enemies hebben unieke eigenschappen:

| Eigenschap | Beschrijving |
|------------|--------------|
| **Geen pathfinding** | Vliegen direct naar exit, negeren torens |
| **Zwakker** | Minder HP (40 base vs 100 infantry) |
| **Geen armor** | 0 armor, geen scaling |
| **Beperkte counters** | Alleen MG, Slow, Shotgun, AntiAir kunnen ze raken |
| **Immune voor** | Cannon, Splash, Laser (projectielen gaan eronder) |

## 📊 Enemy Stats

| Type | Health | Speed | Armor | Reward | Pathfinding |
|------|--------|-------|-------|--------|-------------|
| Infantry | 100 | 80 | 0 | 10 | Flow Field |
| Cavalry | 180 | 120 | 30 | 20 | Flow Field |
| Flying | 40 | 90 | 0 | 12 | **Direct** |

## 🗼 Tower Stats (8 Torens)

| Tower | Damage | Range | ROF | Cost | Target | Special |
|-------|--------|-------|-----|------|--------|---------|
| MachineGun | 8 | 150 | 8.0/s | 50 | All | Prioriteert flying |
| Cannon | 60 | 180 | 0.8/s | 80 | Ground | 50 armor pen, **NO flying** |
| Slow | 0 | 120 | 2.0/s | 60 | All | 50% slow, 2s |
| Buff | 0 | 150 | - | 100 | Towers | +15% dmg, +10% ROF |
| Shotgun | 12×6 | 100 | 1.5/s | 70 | All | Cone spread |
| Splash | 30 | 160 | 0.7/s | 90 | Ground | 60 radius, **NO flying** |
| **Laser** | 15 DPS | 250 | 10/s | 120 | Ground | Piercing beam, **NO flying** |
| **AntiAir** | 25 | 200 | 3.0/s | 75 | **Flying only** | +150% vs flying |

## ⬆️ Upgrade Balancing

**Upgrades zijn waardevoller dan nieuwe torens kopen!**

| Upgrade | Cost | Damage | Range | Fire Rate |
|---------|------|--------|-------|-----------|
| Level 1→2 | 40% base | +35% | +15% | +25% |
| Level 2→3 | 50% base | +70% | +30% | +50% |

**Voorbeeld MachineGun ($50 base):**
- Upgrade 1→2: $20 voor +35% stats
- Upgrade 2→3: $25 voor +70% stats totaal
- **Totaal: $95 voor 170% damage**
- Vergelijk: 2 nieuwe torens = $100 voor 200% base damage maar geen synergy

## 🎯 Target Selection

| Tower | Priority |
|-------|----------|
| MachineGun | Flying > Closest |
| Cannon | Most Armored (ground only) |
| Slow | All in range (AoE) |
| Buff | N/A (buffs towers) |
| Shotgun | Closest |
| Splash | Most enemies in radius (ground) |
| Laser | Closest ground enemy (beam pierces) |
| AntiAir | **Only flying** - homing missiles |

## 🎮 Levels

| Level | Name | Waves | Emphasis |
|-------|------|-------|----------|
| 0 | Tutorial | 5 | Learning basics |
| 1 | First Defense | 20 | Infantry intro |
| 2 | Air Raid | 25 | Heavy flying |
| 3 | Armored Assault | 25 | Heavy cavalry |
| 4 | The Swarm | 30 | Massive infantry |
| 5 | Combined Arms | 35 | Balanced mixed |
| 6 | Sky Terror | 35 | Air superiority |
| 7 | Iron Legion | 40 | Elite armor |
| 8 | Blitzkrieg | 40 | Fast assault |
| 9 | Endless Tide | 45 | Massive numbers |
| 10 | Final Stand | 50 | Ultimate challenge |

## 🔊 Audio System

Proceduraal gegenereerde geluiden via AVAudioEngine:

- **Tower sounds**: Plaats, upgrade, verkoop, elk wapen type
- **Enemy sounds**: Dood, exit bereikt, spawn
- **Game sounds**: Wave start/complete, victory, game over
- **UI sounds**: Button clicks, invalid placement

## 🏃 Build & Run

### Vereisten
- Xcode 15.0+
- iOS 15.0+ deployment target
- macOS voor development

### Stappen

1. Open `TowerDefense.xcodeproj` in Xcode
2. Select een iPhone simulator of device
3. Build & Run (⌘R)

```bash
# Command line build:
cd TowerDefense
xcodebuild -scheme TowerDefense -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## 🎮 Controls

- **Tap** Build Menu → Selecteer toren
- **Tap** speelveld → Plaats toren (groen=geldig, rood=ongeldig)
- **Tap** geplaatste toren → Info/Upgrade/Sell
- **Start Wave** → Begin volgende wave
- **2x** → Fast forward

## 🖼 App Icon

De app icon wordt proceduraal gegenereerd door `AppIconGenerator.swift`:
- Tower silhouette met range indicator
- Enemy dots approaching
- Muzzle flash effect
- Dark gradient background met grid

## ⚙️ Balance Philosophy

1. **Upgrades > New Towers**: Maximale stats voor minimale investering
2. **Counter System**: Elke vijand heeft sterke en zwakke counters
3. **Flying Tradeoff**: Geen pathfinding maar zeer fragiel
4. **Specialization**: Laser voor DPS, AntiAir voor vliegers, Buff voor support

## 📝 What's Implemented

✅ Dynamic obstacle-based pathfinding (Flow Field)
✅ 8 unique tower types with upgrades
✅ 3 enemy types with distinct behaviors
✅ Flying units ignore pathing, are weaker
✅ 11 levels (tutorial + 10 main levels)
✅ 20-50 waves per level
✅ Procedural audio system
✅ App icon generator
✅ Upgrade value > new tower value
✅ Tower targeting restrictions (no flying for cannon/splash/laser)

## 🚧 Future Improvements

- Save/Load game progress between sessions
- More tower types
- Boss enemies
- Achievement system
- Leaderboards
- Additional levels

---

**Ontwikkeld met SpriteKit & Swift voor iOS**
