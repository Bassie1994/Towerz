import Foundation

/// Delegate for economy events
protocol EconomyManagerDelegate: AnyObject {
    func moneyDidChange(newAmount: Int)
    func purchaseFailed(reason: String)
}

/// Manages player money and transactions
final class EconomyManager {
    
    // MARK: - Properties
    
    weak var delegate: EconomyManagerDelegate?
    
    private(set) var money: Int {
        didSet {
            delegate?.moneyDidChange(newAmount: money)
        }
    }
    
    // Stats tracking
    private(set) var totalEarned: Int = 0
    private(set) var totalSpent: Int = 0
    
    // MARK: - Initialization
    
    init(startingMoney: Int = GameConstants.startingMoney) {
        self.money = startingMoney
        self.totalEarned = startingMoney
    }
    
    // MARK: - Transactions
    
    func canAfford(_ amount: Int) -> Bool {
        return money >= amount
    }
    
    func spend(_ amount: Int) -> Bool {
        guard canAfford(amount) else {
            delegate?.purchaseFailed(reason: "Not enough money!")
            return false
        }
        
        money -= amount
        totalSpent += amount
        return true
    }
    
    func earn(_ amount: Int) {
        money += amount
        totalEarned += amount
    }
    
    // MARK: - Tower Transactions
    
    func purchaseTower(type: TowerType) -> Bool {
        let cost = type.baseCost
        
        guard canAfford(cost) else {
            delegate?.purchaseFailed(reason: "Need \(cost) coins for \(type.displayName)")
            return false
        }
        
        return spend(cost)
    }
    
    func upgradeTower(_ tower: Tower) -> Bool {
        guard let cost = tower.getUpgradeCost() else {
            delegate?.purchaseFailed(reason: "Tower is max level")
            return false
        }
        
        guard canAfford(cost) else {
            delegate?.purchaseFailed(reason: "Need \(cost) coins to upgrade")
            return false
        }
        
        return spend(cost)
    }
    
    func sellTower(_ tower: Tower) {
        earn(tower.sellValue)
    }
    
    // MARK: - Enemy Rewards
    
    @discardableResult
    func rewardForKill(enemy: Enemy) -> Int {
        let reward = enemy.killReward
        earn(reward)
        return reward
    }
    
    // MARK: - Wave Bonuses
    
    func waveCompletionBonus(waveNumber: Int) {
        let bonus = 20 + waveNumber * 10
        earn(bonus)
    }
    
    // MARK: - Info
    
    func getStats() -> [String: Int] {
        return [
            "Current": money,
            "Total Earned": totalEarned,
            "Total Spent": totalSpent
        ]
    }
}
