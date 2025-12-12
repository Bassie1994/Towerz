# iOS Tower Defense - Dynamic Pathfinding

Een complete Tower Defense game voor iOS met **dynamische obstacle-based pathfinding**. Vijanden navigeren in real-time om geplaatste torens heen - geen vaste paden!

## 🎮 Features

- **Dynamische Pathfinding**: Vijanden berekenen hun route in real-time met een Flow Field algoritme
- **9 Unieke Torens**: Inclusief Wall tower voor goedkoop maze building
- **3 Vijandtypes**: Infantry (snel), Cavalry (trage tanks), en Flying (negeert obstakels)
- **Pad-validatie**: Torens kunnen niet geplaatst worden als ze alle paden blokkeren
- **11 Levels**: Tutorial + 10 levels met 20-50 waves elk
- **Economy systeem**: Verdien geld door vijanden te doden, koop en upgrade torens
- **Procedural Audio**: Synthesized sound effects voor alle acties
- **Flying Mechanics**: Vliegende vijanden zijn NIET padgebonden maar wel zwakker
- **Massive Waves**: Honderden vijanden per wave voor epische gevechten

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

## 📊 Enemy Stats (REBALANCED)

| Type | Health | Speed | Armor | Reward | Pathfinding | Notes |
|------|--------|-------|-------|--------|-------------|-------|
| Infantry | 100 | **100** | 0 | **2** | Flow Field | Snel, zwerm |
| Cavalry | **300** | **50** | 30 | **4** | Flow Field | **TRAGE TANK** |
| Flying | 40 | **60** | 0 | **2** | **Direct** | Traag, fragiel |

**Reward Ratio**: 5x lager dan voorheen = veel meer vijanden nodig om dezelfde torens te bouwen!

## 🗼 Tower Stats (9 Torens - ALL NERFED 50%)

| Tower | Damage | Range | ROF | Cost | Target | Special |
|-------|--------|-------|-----|------|--------|---------|
| **Wall** | 0 | 0 | - | **10** | - | Blokkeert alleen, converteerbaar |
| MachineGun | **4** | 150 | 8.0/s | 50 | All | Prioriteert flying |
| Cannon | **30** | **70** | 0.8/s | 80 | Ground | Korte range, **NO flying** |
| Slow | 0 | 120 | 2.0/s | 60 | All | 50% slow, 2s |
| Buff | 0 | **30** | - | 100 | Towers | **15/25/35%** per level |
| Shotgun | **6**×6 | **60** | 1.5/s | 70 | All | ZEER korte range |
| Splash | **15** | 160 | 0.7/s | 90 | Ground | 60 radius, **NO flying** |
| **Laser** | **7** DPS | **1300** | 10/s | 120 | Ground | **FULL FIELD**, **NO flying** |
| **AntiAir** | **12** | 200 | 3.0/s | 75 | **Flying only** | +150% vs flying |

### 🧱 Wall Tower - Nieuw!

De Wall tower is speciaal:
- Kost slechts **$10** - goedkoopste optie voor maze building
- Doet **geen schade** - puur voor het blokkeren van paden
- Kan later worden **geconverteerd** naar elke andere toren (betaal het verschil)
- Perfect voor vroege game maze setup met beperkt budget

## ⬆️ Upgrade Balancing

**Upgrades zijn waardevoller dan nieuwe torens kopen!**

| Upgrade | Cost | Damage | Range | Fire Rate |
|---------|------|--------|-------|-----------|
| Level 1→2 | 40% base | +35% | +15% | +25% |
| Level 2→3 | 50% base | +70% | +30% | +50% |

### Buff Tower Upgrade Scaling

De Buff tower wordt **significant sterker** per upgrade:
| Level | Damage Buff | ROF Buff |
|-------|-------------|----------|
| 1 | 15% | 15% |
| 2 | **25%** | **25%** |
| 3 | **35%** | **35%** |

**Voorbeeld MachineGun ($50 base):**
- Upgrade 1→2: $20 voor +35% stats
- Upgrade 2→3: $25 voor +70% stats totaal
- **Totaal: $95 voor 170% damage**
- Vergelijk: 2 nieuwe torens = $100 voor 200% base damage maar geen synergy

## 🎯 Target Selection

| Tower | Priority |
|-------|----------|
| Wall | N/A (blocks only) |
| MachineGun | Flying > Closest |
| Cannon | Most Armored (ground only) - **Short range!** |
| Slow | All in range (AoE) |
| Buff | N/A (buffs adjacent towers - **tiny range**) |
| Shotgun | Closest - **Very short range!** |
| Splash | Most enemies in radius (ground) |
| Laser | Closest ground enemy (beam pierces) - **Full field!** |
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
4. **Specialization**: Laser voor full-field DPS, AntiAir voor vliegers, Buff voor support
5. **Swarm Economy**: Lage rewards = veel vijanden = epische gevechten
6. **Cavalry = Tanks**: Traag maar moeilijk te stoppen
7. **Range Matters**: Cannon/Shotgun zeer korte range, Laser ongelimiteerd

## 📝 What's Implemented

✅ Dynamic obstacle-based pathfinding (Flow Field)
✅ **9 unique tower types** with upgrades (including Wall)
✅ 3 enemy types with distinct behaviors
✅ Flying units ignore pathing, are weaker
✅ 11 levels (tutorial + 10 main levels)
✅ 20-50 waves per level with **massive enemy counts**
✅ Procedural audio system
✅ App icon generator
✅ Upgrade value > new tower value
✅ Tower targeting restrictions (no flying for cannon/splash/laser)
✅ Wall tower conversion system
✅ Rebalanced damage (50% nerf) and rewards (5x smaller)

## 🚧 Future Improvements

- Save/Load game progress between sessions
- More tower types
- Boss enemies
- Achievement system
- Leaderboards
- Additional levels

---

**Ontwikkeld met SpriteKit & Swift voor iOS**
