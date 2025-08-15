import Foundation
import Combine
import Rex

public struct AppReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
        switch action {
        // Game actions
        case .startGame:
            state.isGameActive = true
            state.score = 0
            state.level = 1
            state.lives = 3
            state.gameEvents.removeAll()
            
            let gameStartEvent = AppState.GameEvent(type: .gameStart, data: ["level": "1"])
            state.gameEvents.append(gameStartEvent)
            state.lastUpdated = Date()
            return [.none]
            
        case .endGame:
            state.isGameActive = false
            if state.score > state.highScore {
                state.highScore = state.score
            }
            
            let gameOverEvent = AppState.GameEvent(
                type: .gameOver,
                data: ["final_score": String(state.score), "level": String(state.level)]
            )
            state.gameEvents.append(gameOverEvent)
            state.lastUpdated = Date()
            return [.none]
            
        case .addScore(let points):
            state.score += points
            state.lastUpdated = Date()
            
            let scoreEvent = AppState.GameEvent(
                type: .score,
                data: ["points": String(points), "total_score": String(state.score)]
            )
            state.gameEvents.append(scoreEvent)
            
            // Check for level up
            if state.score >= state.level * 100 {
                return [Effect { emitter in
                    await emitter.withValue { emitter in
                        await emitter.send(.levelUp)
                    }
                }]
            }
            
            // Check for achievements
            var achievementEffects: [Effect<AppAction>] = []
            if state.score == 1 {
                achievementEffects.append(Effect { emitter in
                    await emitter.withValue { emitter in
                        await emitter.send(.unlockAchievement("first_score"))
                    }
                })
            }
            if state.score >= 100 {
                achievementEffects.append(Effect { emitter in
                    await emitter.withValue { emitter in
                        await emitter.send(.unlockAchievement("high_scorer"))
                    }
                })
            }
            if state.score >= 1000 {
                achievementEffects.append(Effect { emitter in
                    await emitter.withValue { emitter in
                        await emitter.send(.unlockAchievement("master"))
                    }
                })
            }
            
            return achievementEffects
            
        case .levelUp:
            state.level += 1
            state.lastUpdated = Date()
            
            let levelUpEvent = AppState.GameEvent(
                type: .levelUp,
                data: ["new_level": String(state.level)]
            )
            state.gameEvents.append(levelUpEvent)
            
            // Check for survivor achievement
            if state.level >= 5 {
                return [Effect { emitter in
                    await emitter.withValue { emitter in
                        await emitter.send(.unlockAchievement("survivor"))
                    }
                }]
            }
            
            return [.none]
            
        case .loseLife:
            state.lives -= 1
            state.lastUpdated = Date()
            
            let lifeLostEvent = AppState.GameEvent(
                type: .lifeLost,
                data: ["remaining_lives": String(state.lives)]
            )
            state.gameEvents.append(lifeLostEvent)
            
            if state.lives <= 0 {
                return [Effect { emitter in
                    await emitter.withValue { emitter in
                        await emitter.send(.endGame)
                    }
                }]
            }
            
            return [.none]
            
        case .gainLife:
            state.lives += 1
            state.lastUpdated = Date()
            
            let lifeGainedEvent = AppState.GameEvent(
                type: .powerUp,
                data: ["power_up_type": "life", "new_lives": String(state.lives)]
            )
            state.gameEvents.append(lifeGainedEvent)
            return [.none]
            
        case .powerUp:
            state.lastUpdated = Date()
            
            let powerUpEvent = AppState.GameEvent(
                type: .powerUp,
                data: ["power_up_type": "bonus"]
            )
            state.gameEvents.append(powerUpEvent)
            return [.none]
            
        case .unlockAchievement(let achievementId):
            if let index = state.achievements.firstIndex(where: { $0.id == achievementId }) {
                state.achievements[index] = AppState.Achievement(
                    id: state.achievements[index].id,
                    name: state.achievements[index].name,
                    description: state.achievements[index].description,
                    icon: state.achievements[index].icon,
                    isUnlocked: true
                )
                
                let achievementEvent = AppState.GameEvent(
                    type: .achievement,
                    data: ["achievement_id": achievementId, "achievement_name": state.achievements[index].name]
                )
                state.gameEvents.append(achievementEvent)
                state.lastUpdated = Date()
            }
            return [.none]
            
        // UI actions
        case .loadGame:
            state.isLoading = true
            state.errorMessage = nil
            return [
                Effect { emitter in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await emitter.withValue { emitter in
                        await emitter.send(.gameLoaded)
                    }
                }
            ]
            
        case .gameLoaded:
            state.isLoading = false
            state.lastUpdated = Date()
            return [.none]
            
        case .saveGame:
            state.isLoading = true
            return [
                Effect { emitter in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await emitter.withValue { emitter in
                        await emitter.send(.gameSaved)
                    }
                }
            ]
            
        case .gameSaved:
            state.isLoading = false
            state.lastUpdated = Date()
            return [.none]
            
        case .showError(let message):
            state.errorMessage = message
            state.isLoading = false
            state.lastUpdated = Date()
            return [.none]
            
        case .clearError:
            state.errorMessage = nil
            state.lastUpdated = Date()
            return [.none]
            
        // Event Bus actions
        case .triggerScoreEvent:
            return [
                Effect { emitter in
                    let randomScore = Int.random(in: 10...50)
                    await emitter.withValue { emitter in
                        await emitter.send(.addScore(randomScore))
                    }
                }
            ]
            
        case .triggerLevelUpEvent:
            return [
                Effect { emitter in
                    await emitter.withValue { emitter in
                        await emitter.send(.levelUp)
                    }
                }
            ]
            
        case .triggerPowerUpEvent:
            return [
                Effect { emitter in
                    let powerUpType = ["life", "bonus", "shield"].randomElement() ?? "bonus"
                    if powerUpType == "life" {
                        await emitter.withValue { emitter in
                            await emitter.send(.gainLife)
                        }
                    } else {
                        await emitter.withValue { emitter in
                            await emitter.send(.powerUp)
                        }
                    }
                }
            ]
            
        case .triggerAchievementEvent:
            let unlockedAchievements = state.achievements.filter { !$0.isUnlocked }
            if let randomAchievement = unlockedAchievements.randomElement() {
                return [
                    Effect { emitter in
                        await emitter.withValue { emitter in
                            await emitter.send(.unlockAchievement(randomAchievement.id))
                        }
                    }
                ]
            }
            return [.none]
            
        case .triggerGameOverEvent:
            return [
                Effect { emitter in
                    await emitter.withValue { emitter in
                        await emitter.send(.endGame)
                    }
                }
            ]
        }
    }
}
