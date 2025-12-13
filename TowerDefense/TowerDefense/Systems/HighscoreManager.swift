import Foundation

/// Represents a single highscore entry
struct HighscoreEntry: Codable, Comparable {
    let score: Int
    let wave: Int
    let date: Date
    let enemiesKilled: Int
    
    static func < (lhs: HighscoreEntry, rhs: HighscoreEntry) -> Bool {
        return lhs.score < rhs.score
    }
}

/// Manages highscores with persistence
final class HighscoreManager {
    
    static let shared = HighscoreManager()
    
    private let highscoresKey = "TowerDefenseHighscores"
    private let maxHighscores = 10
    
    private(set) var highscores: [HighscoreEntry] = []
    
    private init() {
        loadHighscores()
    }
    
    // MARK: - Score Calculation
    
    /// Calculate score based on game performance
    static func calculateScore(wave: Int, enemiesKilled: Int, moneyEarned: Int, livesRemaining: Int, isVictory: Bool) -> Int {
        var score = 0
        
        // Base score from waves (exponential scaling)
        score += wave * wave * 100
        
        // Bonus for enemies killed
        score += enemiesKilled * 10
        
        // Bonus for remaining lives
        score += livesRemaining * 500
        
        // Victory multiplier
        if isVictory {
            score = Int(Double(score) * 1.5)
        }
        
        return score
    }
    
    // MARK: - Highscore Management
    
    /// Add a new score and return its rank (1-based), or nil if not in top 10
    @discardableResult
    func addScore(score: Int, wave: Int, enemiesKilled: Int) -> Int? {
        let entry = HighscoreEntry(
            score: score,
            wave: wave,
            date: Date(),
            enemiesKilled: enemiesKilled
        )
        
        highscores.append(entry)
        highscores.sort(by: >)  // Sort descending
        
        // Keep only top scores
        if highscores.count > maxHighscores {
            highscores = Array(highscores.prefix(maxHighscores))
        }
        
        saveHighscores()
        
        // Return rank if in top 10
        if let index = highscores.firstIndex(where: { $0.score == score && $0.date == entry.date }) {
            return index + 1
        }
        return nil
    }
    
    /// Check if a score would make the top 10
    func wouldBeHighscore(_ score: Int) -> Bool {
        if highscores.count < maxHighscores {
            return true
        }
        return score > (highscores.last?.score ?? 0)
    }
    
    /// Get rank for a score (1-based), or nil if not in top 10
    func getRank(for score: Int) -> Int? {
        for (index, entry) in highscores.enumerated() {
            if score >= entry.score {
                return index + 1
            }
        }
        if highscores.count < maxHighscores {
            return highscores.count + 1
        }
        return nil
    }
    
    // MARK: - Persistence
    
    private func loadHighscores() {
        guard let data = UserDefaults.standard.data(forKey: highscoresKey) else {
            highscores = []
            return
        }
        
        do {
            highscores = try JSONDecoder().decode([HighscoreEntry].self, from: data)
            highscores.sort(by: >)
        } catch {
            print("Failed to load highscores: \(error)")
            highscores = []
        }
    }
    
    private func saveHighscores() {
        do {
            let data = try JSONEncoder().encode(highscores)
            UserDefaults.standard.set(data, forKey: highscoresKey)
        } catch {
            print("Failed to save highscores: \(error)")
        }
    }
    
    /// Clear all highscores (for testing)
    func clearHighscores() {
        highscores = []
        UserDefaults.standard.removeObject(forKey: highscoresKey)
    }
}
