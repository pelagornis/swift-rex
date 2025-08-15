import Foundation
import Rex

public struct AppState: StateType {
    public var score: Int = 0
    public var highScore: Int = 0
    public var level: Int = 1
    public var lives: Int = 3
    public var isGameActive: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    public var lastUpdated: Date = Date()
    public var gameEvents: [GameEvent] = []
    public var achievements: [Achievement] = []
    
    public struct GameEvent: Codable, Equatable, Identifiable {
        public let id: String
        public let type: EventType
        public let timestamp: Date
        public let data: [String: String]
        
        public init(id: String = UUID().uuidString, type: EventType, data: [String: String] = [:]) {
            self.id = id
            self.type = type
            self.timestamp = Date()
            self.data = data
        }
        
        public enum EventType: String, Codable, CaseIterable {
            case score = "score"
            case levelUp = "level_up"
            case lifeLost = "life_lost"
            case powerUp = "power_up"
            case achievement = "achievement"
            case gameOver = "game_over"
            case gameStart = "game_start"
        }
    }
    
    public struct Achievement: Codable, Equatable, Identifiable {
        public let id: String
        public let name: String
        public let description: String
        public let icon: String
        public let isUnlocked: Bool
        public let unlockedAt: Date?
        
        public init(id: String, name: String, description: String, icon: String, isUnlocked: Bool = false) {
            self.id = id
            self.name = name
            self.description = description
            self.icon = icon
            self.isUnlocked = isUnlocked
            self.unlockedAt = isUnlocked ? Date() : nil
        }
    }
    
    public init() {
        // Initialize achievements
        achievements = [
            Achievement(id: "first_score", name: "First Score", description: "Score your first point", icon: "🎯"),
            Achievement(id: "high_scorer", name: "High Scorer", description: "Reach 100 points", icon: "🏆"),
            Achievement(id: "survivor", name: "Survivor", description: "Complete 5 levels", icon: "🛡️"),
            Achievement(id: "lucky", name: "Lucky", description: "Get 3 power-ups", icon: "🍀"),
            Achievement(id: "master", name: "Master", description: "Reach 1000 points", icon: "👑")
        ]
    }
}
