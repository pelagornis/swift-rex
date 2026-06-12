import Foundation
import Rex

public enum AppAction: Actionable {
    case graph(GraphAction)
    case delegate(DelegateAction)

    case startGame
    case endGame
    case addScore(Int)
    case levelUp
    case loseLife
    case gainLife
    case powerUp
    case unlockAchievement(String)

    case loadGame
    case gameLoaded
    case saveGame
    case gameSaved
    case showError(String?)
    case clearError
    case logActivity(String)

    case triggerScoreEvent
    case triggerLevelUpEvent
    case triggerPowerUpEvent
    case triggerAchievementEvent
    case triggerGameOverEvent
}

public enum DelegateAction: Actionable, Equatable {
    case messageToFirst(String)
    case addScoreFromSecond(Int)
    case navigatedBack
}
