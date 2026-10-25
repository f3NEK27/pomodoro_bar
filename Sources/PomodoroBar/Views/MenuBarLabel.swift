import SwiftUI

/// То, что видно в строке меню: «🍅 18:42» на работе, «☕ 04:10» на перерыве.
struct MenuBarLabel: View {
    @ObservedObject var engine: PomodoroEngine

    var body: some View {
        Text("\(engine.isPaused ? "⏸" : engine.phase.icon) \(engine.remaining.mmss)")
            .monospacedDigit()
    }
}
