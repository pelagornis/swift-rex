import Foundation

/// The outcome of a pipeline hook invocation.
public enum HookResult<Action: Actionable>: Sendable {
  case `continue`
  case transform(Action)
  case abort
  case appendEffects([Effect<Action>])
}
