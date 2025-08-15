import Foundation
import Rex

public enum AppAction: ActionType {
    // Game actions
    case startGame
    case endGame
    case addScore(Int)
    case levelUp
    case loseLife
    case gainLife
    case powerUp
    case unlockAchievement(String)
    
    // UI actions
    case loadGame
    case gameLoaded
    case saveGame
    case gameSaved
    case showError(String?)
    case clearError
    
    // Event Bus actions
    case triggerScoreEvent
    case triggerLevelUpEvent
    case triggerPowerUpEvent
    case triggerAchievementEvent
    case triggerGameOverEvent
}
