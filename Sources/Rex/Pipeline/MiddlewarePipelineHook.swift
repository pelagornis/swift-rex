import Foundation

/// Adapts legacy ``Middleware`` into a ``PipelineHook`` that runs at `willReceive`.
public struct MiddlewarePipelineHook<State: Statable, Action: Actionable>: PipelineHook {
  private let middleware: AnyMiddleware<State, Action>

  public init(_ middleware: AnyMiddleware<State, Action>) {
    self.middleware = middleware
  }

  public init<M: Middleware>(_ middleware: M) where M.State == State, M.Action == Action {
    self.middleware = AnyMiddleware(middleware)
  }

  public func handle(
    phase: PipelinePhase<Action, State>,
    context: PipelineContext<Action, State>
  ) async -> HookResult<Action> {
    guard case .willReceive = phase else {
      return .continue
    }

    let effects = await middleware.process(
      state: context.stateBefore,
      action: context.action,
      emit: { action in
        context.dispatch?(action)
      }
    )

    guard !effects.isEmpty else {
      return .continue
    }
    return .appendEffects(effects)
  }
}
