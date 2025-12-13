import Foundation

/// Provides dark humor jokes for game over and victory screens
final class DarkHumorManager {
    
    static let shared = DarkHumorManager()
    
    private init() {}
    
    // MARK: - Game Over Jokes (Dutch dark humor)
    
    private let gameOverJokes: [String] = [
        "Je verdediging was net zo sterk als WiFi in de kelder",
        "De vijanden hadden honger... jij was de snack",
        "Zelfs de tutorial vijanden lachen je uit",
        "Je towers stonden er gewoon... voor de sfeer",
        "Pro tip: towers moeten daadwerkelijk schieten",
        "De vijanden dachten dat dit een speedrun was",
        "Je base is nu een Airbnb voor goblins",
        "Even slecht als je WiFi-wachtwoord kiezen",
        "De vijanden noemden dit 'te makkelijk'",
        "Volgende keer gewoon Candy Crush spelen?",
        "Je strategie: 'hopelijk gaat het vanzelf'",
        "Zelfs een random monkey had beter gedaan",
        "De vijanden waren sneller dan je reflexen",
        "Dit was pijnlijk om naar te kijken...",
        "Je tower defense was meer tower defeatse",
        "F in de chat voor je base",
        "De vijanden stuurden een bedankkaartje",
        "Je hebt gefaald... spectaculair wel",
        "404: Defense not found",
        "Git gud, maar dan echt",
        "Je speelde alsof je controller stuk was",
        "De vijanden hadden medelijden... bijna",
        "Retry? Of gewoon opgeven?",
        "Je base ging sneller dan een Tikkie split",
        "Dat was... een keuze",
        "De vijanden zeiden 'GG EZ'",
        "Je verdediging was puur decoratief",
        "Oef. Gewoon oef.",
        "*Treurige tower geluiden*",
        "Je base: 'Ik ga even sigaretten halen'"
    ]
    
    // MARK: - Victory Jokes (Dutch dark humor)
    
    private let victoryJokes: [String] = [
        "Je hebt gewonnen! De vijanden bellen hun therapeut",
        "GG! De vijanden zijn nu getraumatiseerd",
        "Victory royale! ...wacht, verkeerde game",
        "De vijanden gaan dit op Reddit posten",
        "Je towers hebben nu PTSS van al dat moorden",
        "Gefeliciteerd! Je bent officieel een massamoordenaar",
        "De vijandenfamilies sturen rouwkaarten",
        "Je hebt meer vijanden gedood dan je matches op Tinder",
        "De goblin vakbond gaat staken",
        "Ergens huilt een vijanden-moeder",
        "Je was meedogenloos... we zijn trots",
        "De vijanden: 'We komen terug!' (narrator: ze kwamen niet terug)",
        "Genocide simulator voltooid!",
        "Je towers verdienen een welverdiende vakantie",
        "De vijanden reviewden dit: ★☆☆☆☆ 'te moeilijk'",
        "Je hebt meer kills dan social skills",
        "Victory! Je mag nu 5 minuten trots zijn",
        "De vijanden overwegen een carrière switch",
        "Je strategisch genie is... onverwacht",
        "Wie had gedacht dat geweld de oplossing was?",
        "De vijanden: 'Dit is toch niet balanced?!'",
        "Je bent nu de villain in hun backstory",
        "Speedrun any%: vijanden uitroeien",
        "De towers zingen 'We Are The Champions'",
        "Achievement unlocked: Geen genade",
        "Je hebt gewonnen! Was het dat waard? (ja)",
        "De vijanden zoeken een andere game",
        "Nice! Nu heb je alleen nog real life te winnen",
        "Je defense was *chef's kiss* dodelijk",
        "De vijanden: 'Nerf towers pls'"
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
