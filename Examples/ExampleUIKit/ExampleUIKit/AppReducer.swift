import Foundation
import Rex

public struct AppReducer: Reducer {
    private let navigation = GraphNavigationReducer<AppState>()

    public init() {}

    public func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
        switch action {
        case .graph(let graphAction):
            _ = navigation.reduce(state: &state, action: graphAction)
            if case .push(let id, _, _) = graphAction {
                appendLog(&state, "🧭 Pushed: \(id.rawValue)")
            } else if case .pop = graphAction {
                appendLog(&state, "🧭 Popped navigation node")
            }
            return []

        case .delegate(let delegateAction):
            return reduceDelegate(state: &state, action: delegateAction)

        case .startGame:
            state.isGameActive = true
            state.score = 0
            state.level = 1
            state.lives = 3
            state.gameEvents.removeAll()
            state.gameEvents.append(AppState.GameEvent(type: .gameStart, data: ["level": "1"]))
            state.lastUpdated = Date()
            appendLog(&state, "🎮 Game started")
            return []

        case .endGame:
            state.isGameActive = false
            if state.score > state.highScore {
                state.highScore = state.score
            }
            state.gameEvents.append(AppState.GameEvent(
                type: .gameOver,
                data: ["final_score": String(state.score), "level": String(state.level)]
            ))
            state.lastUpdated = Date()
            appendLog(&state, "🏁 Game ended — score \(state.score)")
            return []

        case .addScore(let points):
            state.score += points
            state.lastUpdated = Date()
            state.gameEvents.append(AppState.GameEvent(
                type: .score,
                data: ["points": String(points), "total_score": String(state.score)]
            ))
            appendLog(&state, "➕ Score +\(points) (total \(state.score))")

            if state.score >= state.level * 100 {
                return [Effect { $0.send(.levelUp) }]
            }

            var effects: [Effect<AppAction>] = []
            if state.score == 1 {
                effects.append(Effect { $0.send(.unlockAchievement("first_score")) })
            }
            if state.score >= 100 {
                effects.append(Effect { $0.send(.unlockAchievement("high_scorer")) })
            }
            if state.score >= 1000 {
                effects.append(Effect { $0.send(.unlockAchievement("master")) })
            }
            return effects

        case .levelUp:
            state.level += 1
            state.lastUpdated = Date()
            state.gameEvents.append(AppState.GameEvent(type: .levelUp, data: ["new_level": String(state.level)]))
            appendLog(&state, "⬆️ Level up → \(state.level)")
            if state.level >= 5 {
                return [Effect { $0.send(.unlockAchievement("survivor")) }]
            }
            return []

        case .loseLife:
            state.lives -= 1
            state.lastUpdated = Date()
            state.gameEvents.append(AppState.GameEvent(type: .lifeLost, data: ["remaining_lives": String(state.lives)]))
            appendLog(&state, "💔 Life lost — \(state.lives) remaining")
            if state.lives <= 0 {
                return [Effect { $0.send(.endGame) }]
            }
            return []

        case .gainLife:
            state.lives += 1
            state.lastUpdated = Date()
            state.gameEvents.append(AppState.GameEvent(type: .powerUp, data: ["power_up_type": "life"]))
            appendLog(&state, "❤️ Extra life — \(state.lives) total")
            return []

        case .powerUp:
            state.lastUpdated = Date()
            state.gameEvents.append(AppState.GameEvent(type: .powerUp, data: ["power_up_type": "bonus"]))
            appendLog(&state, "⚡ Power up!")
            return []

        case .unlockAchievement(let achievementId):
            if let index = state.achievements.firstIndex(where: { $0.id == achievementId }) {
                let achievement = state.achievements[index]
                state.achievements[index] = AppState.Achievement(
                    id: achievement.id,
                    name: achievement.name,
                    description: achievement.description,
                    icon: achievement.icon,
                    isUnlocked: true
                )
                state.gameEvents.append(AppState.GameEvent(
                    type: .achievement,
                    data: ["achievement_id": achievementId, "achievement_name": achievement.name]
                ))
                state.lastUpdated = Date()
                appendLog(&state, "🏆 Achievement: \(achievement.name)")
            }
            return []

        case .loadGame:
            state.isLoading = true
            state.errorMessage = nil
            return [
                Effect { emitter in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    emitter.send(.gameLoaded)
                }
            ]

        case .gameLoaded:
            state.isLoading = false
            state.lastUpdated = Date()
            return []

        case .saveGame:
            state.isLoading = true
            return [
                Effect { emitter in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    emitter.send(.gameSaved)
                }
            ]

        case .gameSaved:
            state.isLoading = false
            state.lastUpdated = Date()
            return []

        case .showError(let message):
            state.errorMessage = message
            state.isLoading = false
            state.lastUpdated = Date()
            return []

        case .clearError:
            state.errorMessage = nil
            state.lastUpdated = Date()
            return []

        case .logActivity(let message):
            appendLog(&state, message)
            return []

        case .triggerScoreEvent:
            return [Effect { $0.send(.addScore(Int.random(in: 10...50))) }]

        case .triggerLevelUpEvent:
            return [Effect { $0.send(.levelUp) }]

        case .triggerPowerUpEvent:
            return [
                Effect { emitter in
                    if ["life", "bonus", "shield"].randomElement() == "life" {
                        emitter.send(.gainLife)
                    } else {
                        emitter.send(.powerUp)
                    }
                }
            ]

        case .triggerAchievementEvent:
            let locked = state.achievements.filter { !$0.isUnlocked }
            if let randomAchievement = locked.randomElement() {
                return [Effect { $0.send(.unlockAchievement(randomAchievement.id)) }]
            }
            return []

        case .triggerGameOverEvent:
            return [Effect { $0.send(.endGame) }]
        }
    }

    private func reduceDelegate(state: inout AppState, action: DelegateAction) -> [Effect<AppAction>] {
        switch action {
        case .messageToFirst(let message):
            appendLog(&state, "💬 Message from Second Page: \(message)")
            return []

        case .addScoreFromSecond(let points):
            appendLog(&state, "📤 Score from second page: +\(points)")
            return [Effect { $0.send(.addScore(points)) }]

        case .navigatedBack:
            appendLog(&state, "🏠 Second page returned to first page")
            return []
        }
    }

    private func appendLog(_ state: inout AppState, _ message: String) {
        let entry = AppState.ActivityLogEntry(message: message)
        state.activityLog.insert(entry, at: 0)
        if state.activityLog.count > 30 {
            state.activityLog.removeLast()
        }
    }
}
