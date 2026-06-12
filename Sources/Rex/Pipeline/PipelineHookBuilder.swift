import Foundation

@resultBuilder
public struct PipelineHookBuilder<State: Statable, Action: Actionable> {
  public static func buildBlock<H: PipelineHook>(_ components: H...) -> [AnyPipelineHook<State, Action>]
    where H.State == State, H.Action == Action
  {
    components.map { AnyPipelineHook($0) }
  }

  public static func buildBlock() -> [AnyPipelineHook<State, Action>] {
    []
  }
}
