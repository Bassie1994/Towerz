import Foundation

/// Central configuration for game balance
/// Easy to modify values without touching game logic
struct GameConfig {
    
    // MARK: - Enemy Stats
    
    struct EnemyStats {
        let health: CGFloat
        let speed: CGFloat
        let armor: CGFloat
        let reward: Int
        
        // Per-level scaling
        let healthScaling: CGFloat
        let speedScaling: CGFloat
        let armorScaling: CGFloat
        let rewardScaling: Int
    }
    
    static let enemyStats: [EnemyType: EnemyStats] = [
        .infantry: EnemyStats(
            health: 100,
            speed: 100,      // CHANGED from 80 - faster
            armor: 0,
            reward: 2,       // CHANGED from 10 - 5x smaller
            healthScaling: 0.30,
            speedScaling: 0.0,
            armorScaling: 5,
            rewardScaling: 0
        ),
        .cavalry: EnemyStats(
            health: 300,     // CHANGED from 180 - TANKY
            speed: 50,       // CHANGED from 120 - SLOW
            armor: 30,
            reward: 4,       // CHANGED from 20 - 5x smaller
            healthScaling: 0.35,
            speedScaling: 0,
            armorScaling: 10,
            rewardScaling: 1
        ),
        .flying: EnemyStats(
            health: 40,      // Weak
            speed: 60,       // CHANGED from 90 - slower
            armor: 0,
            reward: 2,       // CHANGED from 12 - 5x smaller
            healthScaling: 0.20,
            speedScaling: 0,
            armorScaling: 0,
            rewardScaling: 0
        )
    ]
    
    // MARK: - Tower Stats
    
    struct TowerStats {
        let damage: CGFloat
        let range: CGFloat
        let fireRate: CGFloat
        let cost: Int
        
        // Per-upgrade scaling
        let damageScaling: CGFloat
        let rangeScaling: CGFloat
        let fireRateScaling: CGFloat
        let upgradeCostMultiplier: CGFloat
    }
    
    static let towerStats: [TowerType: TowerStats] = [
        .wall: TowerStats(
            damage: 0,
            range: 0,
            fireRate: 0,
            cost: 10,         // Very cheap - just for blocking
            damageScaling: 0.0,
            rangeScaling: 0.0,
            fireRateScaling: 0.0,
            upgradeCostMultiplier: 0.0
        ),
        .machineGun: TowerStats(
            damage: 4,        // NERFED from 8 (50%)
            range: 150,
            fireRate: 8.0,
            cost: 50,
            damageScaling: 0.20,
            rangeScaling: 0.10,
            fireRateScaling: 0.15,
            upgradeCostMultiplier: 0.5
        ),
        .cannon: TowerStats(
            damage: 30,       // NERFED from 60 (50%)
            range: 70,        // NERFED from 180 - SHORT range
            fireRate: 0.8,
            cost: 80,
            damageScaling: 0.25,
            rangeScaling: 0.10,
            fireRateScaling: 0.10,
            upgradeCostMultiplier: 0.5
        ),
        .slow: TowerStats(
            damage: 0,
            range: 120,
            fireRate: 2.0,
            cost: 60,
            damageScaling: 0.0,
            rangeScaling: 0.15,
            fireRateScaling: 0.10,
            upgradeCostMultiplier: 0.5
        ),
        .buff: TowerStats(
            damage: 0,
            range: 30,        // NERFED from 150 - TINY buff radius
            fireRate: 1.0,
            cost: 100,
            damageScaling: 0.0,
            rangeScaling: 0.0,  // No range scaling - stays tiny
            fireRateScaling: 0.0,
            upgradeCostMultiplier: 0.6
        ),
        .mine: TowerStats(
            damage: 25,       // Mine explosion damage
            range: 120,       // Range to place mines
            fireRate: 0.5,    // 1 mine every 2 seconds
            cost: 70,
            damageScaling: 0.20,
            rangeScaling: 0.08,
            fireRateScaling: 0.12,
            upgradeCostMultiplier: 0.5
        ),
        .splash: TowerStats(
            damage: 15,       // NERFED from 30 (50%)
            range: 160,
            fireRate: 0.7,
            cost: 90,
            damageScaling: 0.22,
            rangeScaling: 0.10,
            fireRateScaling: 0.08,
            upgradeCostMultiplier: 0.55
        ),
        .laser: TowerStats(
            damage: 7,        // NERFED from 15 (50%)
            range: 1300,      // BUFFED - FULL FIELD range
            fireRate: 10.0,
            cost: 120,
            damageScaling: 0.35,
            rangeScaling: 0.0,  // Already max range
            fireRateScaling: 0.15,
            upgradeCostMultiplier: 0.5
        ),
        .antiAir: TowerStats(
            damage: 12,       // NERFED from 25 (50%)
            range: 200,
            fireRate: 3.0,
            cost: 75,
            damageScaling: 0.30,
            rangeScaling: 0.12,
            fireRateScaling: 0.20,
            upgradeCostMultiplier: 0.45
        )
    ]
    
    // MARK: - Game Balance
    
    struct GameBalance {
        static let startingLives = 20
        static let startingMoney = 200
        
        static let sellValuePercent = 0.70  // 70% of invested value
        
        static let waveCompletionBonusBase = 20
        static let waveCompletionBonusPerWave = 10
        
        static let maxTowerUpgradeLevel = 2
    }
    
    // MARK: - Slow Tower Config
    
    struct SlowTowerConfig {
        static let baseSlowPercent: CGFloat = 0.50
        static let slowPercentPerLevel: CGFloat = 0.10
        static let maxSlowPercent: CGFloat = 0.70
        
        static let baseDuration: TimeInterval = 2.0
        static let durationPerLevel: TimeInterval = 0.5
    }
    
    // MARK: - Buff Tower Config
    
    struct BuffTowerConfig {
        static let baseDamageBuffPercent: CGFloat = 0.15
        static let damageBuffPerLevel: CGFloat = 0.10  // BUFFED: 15% -> 25% -> 35%
        
        static let baseFireRateBuffPercent: CGFloat = 0.15  // Matched to damage
        static let fireRateBuffPerLevel: CGFloat = 0.10  // BUFFED: 15% -> 25% -> 35%
        
        static let buffStackingEnabled = false
    }
    
    // MARK: - Cannon Tower Config
    
    struct CannonTowerConfig {
        static let baseArmorPenetration: CGFloat = 50
        static let armorPenetrationPerLevel: CGFloat = 15
    }
    
    // MARK: - Shotgun Tower Config
    
    struct ShotgunTowerConfig {
        static let basePelletCount = 6
        static let pelletsPerLevel = 1
        static let spreadAngle: CGFloat = .pi / 4  // 45 degrees
        static let damageDropoffAtMaxRange: CGFloat = 0.50
    }
    
    // MARK: - Splash Tower Config
    
    struct SplashTowerConfig {
        static let baseSplashRadius: CGFloat = 60
        static let splashRadiusPerLevel: CGFloat = 10
        static let splashDamageFalloff: CGFloat = 0.50
    }
    
    // MARK: - Laser Tower Config
    
    struct LaserTowerConfig {
        static let beamWidth: CGFloat = 20
        static let damageTicksPerSecond: CGFloat = 10
    }
    
    // MARK: - AntiAir Tower Config
    
    struct AntiAirTowerConfig {
        static let flyingDamageMultiplier: CGFloat = 2.5  // 250% damage to flying
        static let missileSpeed: CGFloat = 500
        static let missileTrackingStrength: CGFloat = 1.0
    }
}

// MARK: - Stats Table (for documentation)

/*
 ╔══════════════════════════════════════════════════════════════════════════════════════╗
 ║                         ENEMY STATS TABLE (REBALANCED)                               ║
 ╠══════════════╦════════╦═══════╦═══════╦════════╦═════════════════════════════════════╣
 ║ Type         ║ Health ║ Speed ║ Armor ║ Reward ║ Notes                               ║
 ╠══════════════╬════════╬═══════╬═══════╬════════╬═════════════════════════════════════╣
 ║ Infantry     ║  100   ║  100  ║   0   ║    2   ║ Fast ground swarm                   ║
 ║ Cavalry      ║  300   ║   50  ║  30   ║    4   ║ SLOW TANK, armored, ground          ║
 ║ Flying       ║   40   ║   60  ║   0   ║    2   ║ Ignores path, WEAKER, immune to     ║
 ║              ║        ║       ║       ║        ║ Cannon/Splash/Laser                 ║
 ╚══════════════╩════════╩═══════╩═══════╩════════╩═════════════════════════════════════╝
 
 ╔══════════════════════════════════════════════════════════════════════════════════════╗
 ║                        TOWER STATS TABLE (50% DMG NERF)                              ║
 ╠════════════╦════════╦═══════╦═══════════╦══════╦══════════════════════════════════════╣
 ║ Type       ║ Damage ║ Range ║ Fire Rate ║ Cost ║ Special                              ║
 ╠════════════╬════════╬═══════╬═══════════╬══════╬══════════════════════════════════════╣
 ║ Wall       ║    0   ║    0  ║    N/A    ║  10  ║ Blocks only, convert later           ║
 ║ MachineGun ║    4   ║  150  ║   8.0/s   ║  50  ║ Prioritizes flying, hits all        ║
 ║ Cannon     ║   30   ║   70  ║   0.8/s   ║  80  ║ SHORT range, armor pen, NO FLYING   ║
 ║ Slow       ║    0   ║  120  ║   2.0/s   ║  60  ║ 50% slow for 2s, hits all           ║
 ║ Buff       ║    0   ║   30  ║    N/A    ║ 100  ║ TINY range, 15/25/35% buff          ║
 ║ Shotgun    ║    6   ║   60  ║   1.5/s   ║  70  ║ VERY SHORT range, 6 pellets         ║
 ║ Splash     ║   15   ║  160  ║   0.7/s   ║  90  ║ 60 radius AoE, NO FLYING            ║
 ║ Laser      ║    7   ║ 1300  ║  10.0/s   ║ 120  ║ FULL FIELD range, NO FLYING         ║
 ║ AntiAir    ║   12   ║  200  ║   3.0/s   ║  75  ║ ONLY flying, +150% dmg to flying    ║
 ╚════════════╩════════╩═══════╩═══════════╩══════╩══════════════════════════════════════╝
 
 TOWER TARGETING:
 - Can hit Flying: MachineGun, Slow, Shotgun, AntiAir
 - Cannot hit Flying: Cannon, Splash, Laser (projectiles go under them)
 - AntiAir: ONLY targets flying enemies
 - Wall: Cannot attack - for maze building only
 
 BUFF TOWER SCALING:
 - Level 1: 15% damage/ROF buff
 - Level 2: 25% damage/ROF buff
 - Level 3: 35% damage/ROF buff
 
 WALL TOWER:
 - Costs only $10
 - Can be converted to any other tower (pay the difference)
 - Great for maze building on a budget
 
 REWARD RATIO: 5x smaller rewards = need to kill many more enemies!
 WAVES: Much larger enemy counts to compensate
 */
