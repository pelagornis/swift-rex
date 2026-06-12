import Foundation
import Rex

public struct AppState: Statable, GraphStateContainer {
    public var graph: StateGraph = StateGraph()
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
    public var activityLog: [ActivityLogEntry] = []

    public struct ActivityLogEntry: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let timestamp: Date
        public let message: String

        public init(id: UUID = UUID(), timestamp: Date = Date(), message: String) {
            self.id = id
            self.timestamp = timestamp
            self.message = message
        }

        public var formatted: String {
            "[\(timestamp.formatted(date: .omitted, time: .standard))] \(message)"
        }
    }

    public struct GameEvent: Codable, Equatable, Identifiable, Sendable {
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

        public enum EventType: String, Codable, CaseIterable, Sendable {
            case score
            case levelUp
            case lifeLost
            case powerUp
            case achievement
            case gameOver
            case gameStart
        }
    }

    public struct Achievement: Codable, Equatable, Identifiable, Sendable {
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
        achievements = [
            Achievement(id: "first_score", name: "First Score", description: "Score your first point", icon: "🎯"),
            Achievement(id: "high_scorer", name: "High Scorer", description: "Reach 100 points", icon: "🏆"),
            Achievement(id: "survivor", name: "Survivor", description: "Complete 5 levels", icon: "🛡️"),
            Achievement(id: "lucky", name: "Lucky", description: "Get 3 power-ups", icon: "🍀"),
            Achievement(id: "master", name: "Master", description: "Reach 1000 points", icon: "👑")
        ]
    }
}
