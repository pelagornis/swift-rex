import Foundation

/// A single recorded step in the action history.
public struct TimeTravelEntry<State: Statable, Action: Actionable>: Sendable {
  public let action: Action
  public let stateBefore: State
  public let stateAfter: State
  public let timestamp: Date

  public init(action: Action, stateBefore: State, stateAfter: State, timestamp: Date = Date()) {
    self.action = action
    self.stateBefore = stateBefore
    self.stateAfter = stateAfter
    self.timestamp = timestamp
  }
}

private actor TimeTravelStorage<State: Statable, Action: Actionable> {
  var entries: [TimeTravelEntry<State, Action>] = []
  var cursor: Int = -1

  func record(action: Action, before: State, after: State) {
    if cursor < entries.count - 1 {
      entries = Array(entries.prefix(cursor + 1))
    }
    entries.append(TimeTravelEntry(action: action, stateBefore: before, stateAfter: after))
    cursor = entries.count - 1
  }

  func history() -> [TimeTravelEntry<State, Action>] {
    entries
  }

  func jumpTo(index: Int) -> State? {
    guard entries.indices.contains(index) else { return nil }
    cursor = index
    return entries[index].stateAfter
  }

  func undo() -> State? {
    guard cursor > 0 else { return nil }
    cursor -= 1
    return entries[cursor].stateAfter
  }

  func redo() -> State? {
    guard cursor < entries.count - 1 else { return nil }
    cursor += 1
    return entries[cursor].stateAfter
  }

  func currentIndex() -> Int {
    cursor
  }
}

/// Automatically records state snapshots on `didReduce` for time-travel debugging.
public final class TimeTravelPipelineHook<State: Statable, Action: Actionable>: PipelineHook, Sendable {
  private let storage = TimeTravelStorage<State, Action>()

  public init() {}

  public func handle(
    phase: PipelinePhase<Action, State>,
    context: PipelineContext<Action, State>
  ) async -> HookResult<Action> {
    guard case .didReduce(let action, let before, let after) = phase else {
      return .continue
    }

    await storage.record(action: action, before: before, after: after)
    return .continue
  }

  public func history() async -> [TimeTravelEntry<State, Action>] {
    await storage.history()
  }

  public func jumpTo(index: Int) async -> State? {
    await storage.jumpTo(index: index)
  }

  public func undo() async -> State? {
    await storage.undo()
  }

  public func redo() async -> State? {
    await storage.redo()
  }

  public func currentIndex() async -> Int {
    await storage.currentIndex()
  }
}
