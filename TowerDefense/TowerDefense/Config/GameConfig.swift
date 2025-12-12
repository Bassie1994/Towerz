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
            speed: 80,
            armor: 0,
            reward: 10,
            healthScaling: 0.30,
            speedScaling: 0.0,
            armorScaling: 5,
            rewardScaling: 2
        ),
        .cavalry: EnemyStats(
            health: 180,
            speed: 120,
            armor: 30,
            reward: 20,
            healthScaling: 0.35,
            speedScaling: 5,
            armorScaling: 10,
            rewardScaling: 4
        ),
        .flying: EnemyStats(
            health: 40,      // Reduced! Flying are weaker
            speed: 90,
            armor: 0,
            reward: 12,
            healthScaling: 0.20,  // Slower scaling
            speedScaling: 5,
            armorScaling: 0,
            rewardScaling: 2
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
        .machineGun: TowerStats(
            damage: 8,
            range: 150,
            fireRate: 8.0,
            cost: 50,
            damageScaling: 0.20,
            rangeScaling: 0.10,
            fireRateScaling: 0.15,
            upgradeCostMultiplier: 0.5
        ),
        .cannon: TowerStats(
            damage: 60,
            range: 180,
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
            range: 150,
            fireRate: 1.0,
            cost: 100,
            damageScaling: 0.0,
            rangeScaling: 0.15,
            fireRateScaling: 0.0,
            upgradeCostMultiplier: 0.6
        ),
        .shotgun: TowerStats(
            damage: 12,
            range: 100,
            fireRate: 1.5,
            cost: 70,
            damageScaling: 0.20,
            rangeScaling: 0.08,
            fireRateScaling: 0.12,
            upgradeCostMultiplier: 0.5
        ),
        .splash: TowerStats(
            damage: 30,
            range: 160,
            fireRate: 0.7,
            cost: 90,
            damageScaling: 0.22,
            rangeScaling: 0.10,
            fireRateScaling: 0.08,
            upgradeCostMultiplier: 0.55
        ),
        .laser: TowerStats(
            damage: 15,       // DPS per tick
            range: 250,       // Long range
            fireRate: 10.0,   // 10 damage ticks per second
            cost: 120,
            damageScaling: 0.35,
            rangeScaling: 0.10,
            fireRateScaling: 0.15,
            upgradeCostMultiplier: 0.5
        ),
        .antiAir: TowerStats(
            damage: 25,       // Base damage (x2.5 vs flying)
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
        static let damageBuffPerLevel: CGFloat = 0.05
        
        static let baseFireRateBuffPercent: CGFloat = 0.10
        static let fireRateBuffPerLevel: CGFloat = 0.05
        
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
 ║                              ENEMY STATS TABLE                                        ║
 ╠══════════════╦════════╦═══════╦═══════╦════════╦═════════════════════════════════════╣
 ║ Type         ║ Health ║ Speed ║ Armor ║ Reward ║ Notes                               ║
 ╠══════════════╬════════╬═══════╬═══════╬════════╬═════════════════════════════════════╣
 ║ Infantry     ║  100   ║  80   ║   0   ║   10   ║ Standard ground unit                ║
 ║ Cavalry      ║  180   ║  120  ║  30   ║   20   ║ Fast, armored, ground               ║
 ║ Flying       ║   40   ║  90   ║   0   ║   12   ║ Ignores path, WEAKER, immune to     ║
 ║              ║        ║       ║       ║        ║ Cannon/Splash/Laser                 ║
 ╚══════════════╩════════╩═══════╩═══════╩════════╩═════════════════════════════════════╝
 
 ╔══════════════════════════════════════════════════════════════════════════════════════╗
 ║                              TOWER STATS TABLE                                        ║
 ╠════════════╦════════╦═══════╦═══════════╦══════╦══════════════════════════════════════╣
 ║ Type       ║ Damage ║ Range ║ Fire Rate ║ Cost ║ Special                              ║
 ╠════════════╬════════╬═══════╬═══════════╬══════╬══════════════════════════════════════╣
 ║ MachineGun ║    8   ║  150  ║   8.0/s   ║  50  ║ Prioritizes flying, hits all        ║
 ║ Cannon     ║   60   ║  180  ║   0.8/s   ║  80  ║ 50 armor pen, NO FLYING             ║
 ║ Slow       ║    0   ║  120  ║   2.0/s   ║  60  ║ 50% slow for 2s, hits all           ║
 ║ Buff       ║    0   ║  150  ║    N/A    ║ 100  ║ +15% dmg, +10% ROF to towers        ║
 ║ Shotgun    ║   12   ║  100  ║   1.5/s   ║  70  ║ 6 pellets cone, hits all            ║
 ║ Splash     ║   30   ║  160  ║   0.7/s   ║  90  ║ 60 radius AoE, NO FLYING            ║
 ║ Laser      ║   15   ║  250  ║  10.0/s   ║ 120  ║ Piercing beam, NO FLYING            ║
 ║ AntiAir    ║   25   ║  200  ║   3.0/s   ║  75  ║ ONLY flying, +150% dmg to flying    ║
 ╚════════════╩════════╩═══════╩═══════════╩══════╩══════════════════════════════════════╝
 
 TOWER TARGETING:
 - Can hit Flying: MachineGun, Slow, Shotgun, AntiAir
 - Cannot hit Flying: Cannon, Splash, Laser (projectiles go under them)
 - AntiAir: ONLY targets flying enemies
 
 UPGRADE SCALING (per level):
 - Damage: +35%
 - Range: +15%
 - Fire Rate: +25%
 - Max upgrade level: 2 (so max is level 3)
 
 UPGRADE COST:
 - Level 1->2: 40% of base cost
 - Level 2->3: 50% of base cost
 - Total for max: 90% extra investment for 170%+ stats = BETTER than buying 2nd tower!
 */
