# iOS Tower Defense - Dynamic Pathfinding

Een complete Tower Defense game voor iOS met **dynamische obstacle-based pathfinding**. Vijanden navigeren in real-time om geplaatste torens heen - geen vaste paden!

## 🎮 Features

- **Dynamische Pathfinding**: Vijanden berekenen hun route in real-time met een Flow Field algoritme
- **6 Unieke Torens**: Elk met eigen strategie en upgrade-pad
- **3 Vijandtypes**: Infantry, Cavalry (gepantserd), en Flying (negeert obstakels)
- **Pad-validatie**: Torens kunnen niet geplaatst worden als ze alle paden blokkeren
- **10 Waves**: Met oplopende moeilijkheid en gemixte vijandtypes
- **Economy systeem**: Verdien geld door vijanden te doden, koop en upgrade torens

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
│   ├── AppDelegate.swift          # App lifecycle
│   ├── SceneDelegate.swift        # Scene lifecycle
│   ├── GameViewController.swift   # SpriteKit view controller
│   │
│   ├── Core/
│   │   ├── GameScene.swift        # Hoofdscene, integreert alle systemen
│   │   ├── GameManager.swift      # Centrale game state manager
│   │   ├── Constants.swift        # Game constanten en enums
│   │   └── Extensions.swift       # Helper extensions
│   │
│   ├── Pathfinding/
│   │   ├── PathfindingGrid.swift  # Grid met walkability data
│   │   ├── AStarPathfinder.swift  # A* voor validatie
│   │   └── FlowField.swift        # Flow Field voor navigatie
│   │
│   ├── Entities/
│   │   ├── Enemies/
│   │   │   ├── Enemy.swift        # Base class
│   │   │   ├── InfantryEnemy.swift
│   │   │   ├── CavalryEnemy.swift
│   │   │   └── FlyingEnemy.swift
│   │   │
│   │   └── Towers/
│   │       ├── Tower.swift        # Base class
│   │       ├── MachineGunTower.swift
│   │       ├── CannonTower.swift
│   │       ├── SlowTower.swift
│   │       ├── BuffTower.swift
│   │       ├── ShotgunTower.swift
│   │       ├── SplashTower.swift
│   │       └── Projectile.swift
│   │
│   ├── Systems/
│   │   ├── WaveManager.swift      # Wave spawning
│   │   ├── EconomyManager.swift   # Geld management
│   │   ├── PlacementValidator.swift
│   │   └── TargetingSystem.swift
│   │
│   ├── UI/
│   │   ├── HUDNode.swift          # Lives, money, wave info
│   │   ├── BuildMenuNode.swift    # Tower selectie
│   │   ├── TowerInfoNode.swift    # Selected tower info
│   │   └── PlacementPreviewNode.swift
│   │
│   ├── Config/
│   │   ├── GameConfig.swift       # Balancing constanten
│   │   └── WaveConfig.json        # Wave definities
│   │
│   └── Resources/
│       ├── Assets.xcassets/
│       ├── Main.storyboard
│       └── LaunchScreen.storyboard
```

## 🔧 Dynamic Pathfinding Implementatie

### Flow Field Algorithm

Het spel gebruikt een **Flow Field** in plaats van individuele A* paden per vijand:

1. **Distance Field**: BFS vanuit alle exit posities berekent afstand naar exit voor elke cel
2. **Direction Field**: Elke cel krijgt een richting die naar de exit wijst
3. **Real-time Updates**: Bij tower placement wordt het flow field opnieuw berekend
4. **Interpolatie**: Vijanden samplen de flow field met bilinear interpolation voor vloeiende beweging

### Placement Validatie

```swift
func validate(gridPosition: GridPosition) -> PlacementValidationResult {
    // 1. Bounds check
    // 2. Niet in spawn/exit zone
    // 3. Cel niet bezet
    // 4. KRITIEK: Testblock om te checken of pad nog bestaat
    if !grid.testBlockCell(gridPosition) {
        return .invalid(reason: "Would block all paths!")
    }
    return .valid()
}
```

De `testBlockCell` methode:
- Blokkeert de cel tijdelijk
- Voert BFS uit vanuit exits om te checken of spawns bereikbaar zijn
- Herstelt de cel
- Retourneert of plaatsing geldig is

## 📊 Enemy Stats

| Type | Health | Speed | Armor | Reward | Notes |
|------|--------|-------|-------|--------|-------|
| Infantry | 100 | 80 | 0 | 10 | Standaard grondunit |
| Cavalry | 180 | 120 | 30 | 20 | Snel, gepantserd |
| Flying | 60 | 100 | 0 | 15 | Negeert obstakels |

**Scaling per level**: Health +25-35%, Armor +5-10, Speed +0-8

## 🗼 Tower Stats

| Tower | Damage | Range | Fire Rate | Cost | Special |
|-------|--------|-------|-----------|------|---------|
| Machine Gun | 8 | 150 | 8.0/s | 50 | Prioriteert flying |
| Cannon | 60 | 180 | 0.8/s | 80 | 50 armor penetration |
| Slow | 0 | 120 | 2.0/s | 60 | 50% slow, 2s |
| Buff | 0 | 150 | - | 100 | +15% dmg, +10% ROF |
| Shotgun | 12/pellet | 100 | 1.5/s | 70 | 6 pellets, cone |
| Splash | 30 | 160 | 0.7/s | 90 | 60 radius AoE |

**Upgrades**: Max 2 upgrades per toren
- Damage: +20% per level
- Range: +10% per level
- Fire Rate: +15% per level

## 🎯 Target Selection

| Tower | Priority |
|-------|----------|
| Machine Gun | Flying > Closest |
| Cannon | Most Armored > Most HP |
| Slow | All in range (AoE) |
| Buff | N/A (buffs towers) |
| Shotgun | Closest |
| Splash | Most enemies in splash radius |

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
# Of via command line:
cd TowerDefense
xcodebuild -scheme TowerDefense -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## 🎮 Controls

- **Tap** op Build Menu → Selecteer toren type
- **Tap** op speelveld → Plaats toren (groen = geldig, rood = ongeldig)
- **Tap** op geplaatste toren → Open info panel
- **Upgrade/Sell** via toren info panel
- **Start Wave** knop om wave te starten
- **2x** knop voor fast forward

## ⚙️ Configuratie

Wave configuratie kan aangepast worden in `WaveConfig.json`:

```json
{
    "waveNumber": 1,
    "groups": [
        {
            "type": "infantry",
            "count": 8,
            "level": 1,
            "spawnInterval": 1.2,
            "groupDelay": 0.0
        }
    ]
}
```

## 🚧 Wat NIET is geïmplementeerd

- **Sound/Music**: Geen audio assets toegevoegd
- **App Icon**: Placeholder configuratie (geen artwork)
- **Tutorial**: Geen in-game uitleg (wel intuïtieve UI)
- **Persistence**: Game state wordt niet opgeslagen
- **Achievements**: Geen tracking van prestaties
- **Meerdere levels**: Alleen 1 level (10 waves)
- **iCloud sync**: Geen cloud opslag

## 🔍 Performance Optimalisaties

1. **Flow Field Caching**: Niet elke frame herberekend, alleen bij grid wijzigingen
2. **Spatial Partitioning**: Enemies in range queries zijn geoptimaliseerd
3. **Object Pooling**: Niet volledig geïmplementeerd maar makkelijk toe te voegen
4. **Batch Rendering**: SpriteKit handled dit automatisch

## 📝 License

MIT License - vrij te gebruiken en aan te passen.

---

**Ontwikkeld met SpriteKit & Swift voor iOS**
