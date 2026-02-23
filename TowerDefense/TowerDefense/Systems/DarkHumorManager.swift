import Foundation

/// Provides dark humor jokes for game over and victory screens
final class DarkHumorManager {
    
    static let shared = DarkHumorManager()
    
    private init() {}
    
    // MARK: - Game Over Jokes
    
    private let gameOverJokes: [String] = [
        "Your defense was as stable as basement Wi-Fi.",
        "The enemies came hungry, and you were the buffet.",
        "Even tutorial mobs are talking trash now.",
        "Your towers were mostly decorative.",
        "Pro tip: towers work better when they shoot.",
        "The enemy called that a speedrun.",
        "Your base just became a goblin timeshare.",
        "That strategy had confidence, not results.",
        "The enemies rated this run: easy mode.",
        "Maybe take a short break and come back stronger.",
        "Your plan was basically \"hope.\"",
        "A random monkey might have micromanaged better.",
        "They moved faster than your reactions.",
        "That was painful to witness.",
        "This was more tower defeat than tower defense.",
        "F in chat for your base.",
        "The enemies sent a thank-you card.",
        "You failed, but at least it was dramatic.",
        "404: Defense not found.",
        "Skill issue, but fixable.",
        "You played like the controller disconnected.",
        "The enemies almost felt bad. Almost.",
        "Retry, adapt, and clap back.",
        "That collapse was quick.",
        "Bold choice. Wrong one, but bold.",
        "The enemy team typed \"GG EZ.\"",
        "Your defense looked expensive and ineffective.",
        "Oof. Just... oof.",
        "*sad tower noises*",
        "Your base went out for milk and never came back."
    ]
    
    // MARK: - Victory Jokes
    
    private let victoryJokes: [String] = [
        "You won. The enemies are calling their therapist.",
        "GG. The enemy squad is emotionally compromised.",
        "Victory Royale! ...wrong game, still counts.",
        "They are posting this loss online.",
        "Your towers earned paid time off.",
        "Congratulations, that was ruthless efficiency.",
        "Enemy morale has left the server.",
        "The goblin union filed a complaint.",
        "Somewhere, an enemy commander is weeping.",
        "You were merciless. Respect.",
        "\"We will return!\" (Narrator: they did not.)",
        "Mission complete: absolute dominance.",
        "Your towers deserve a medal.",
        "Enemy review: ★☆☆☆☆ \"too hard\".",
        "Victory secured. Flex for five minutes.",
        "The enemies are considering a career change.",
        "Your tactical genius was unexpectedly real.",
        "Turns out violence solved this one.",
        "Enemy chat: \"Is this even balanced?!\"",
        "You are now the villain in their lore.",
        "Speedrun any%: erase hostiles.",
        "Your towers are humming victory music.",
        "Achievement unlocked: No Mercy.",
        "You won. Worth it? Yes.",
        "The enemies switched to another game.",
        "Clean defense. Clinical finish.",
        "That maze was illegal in 37 countries.",
        "You turned panic into choreography.",
        "Your base stood. Their hopes did not.",
        "Enemy feedback: \"Please nerf towers.\""
    ]
    
    // MARK: - Public Methods
    
    /// Get a random game over joke
    func getGameOverJoke() -> String {
        return gameOverJokes.randomElement() ?? "Game Over!"
    }
    
    /// Get a random victory joke
    func getVictoryJoke() -> String {
        return victoryJokes.randomElement() ?? "Victory!"
    }
}
