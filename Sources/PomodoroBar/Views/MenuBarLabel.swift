import SwiftUI

/// То, что видно в строке меню: «🍅 18:42».
struct MenuBarLabel: View {
    @ObservedObject var timer: CountdownTimer

    var body: some View {
        Text("\(timer.isPaused ? "⏸" : "🍅") \(timer.remaining.mmss)")
            .monospacedDigit()
    }
}
