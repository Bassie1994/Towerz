import Foundation

/// Sound effect types (placeholder - audio disabled)
enum SoundEffect: String {
    case towerPlace, towerUpgrade, towerSell
    case machineGunFire, cannonFire, laserFire, shotgunFire, splashFire, antiAirFire
    case slowActivate, buffActivate
    case enemyDeath, enemyReachExit, enemySpawn
    case waveStart, waveComplete, levelComplete, gameOver, victory
    case buttonClick, invalidPlacement, coinEarn, lifeLost
}

/// Audio Manager - DISABLED
/// Audio system removed due to AVAudioEngine format compatibility issues
final class AudioManager {
    static let shared = AudioManager()
    
    private init() {}
    
    func playSound(_ effect: SoundEffect) {
        // Audio disabled
    }
    
    func toggleSound() {}
    func toggleMusic() {}
    func startBackgroundMusic() {}
    func stopBackgroundMusic() {}
}
