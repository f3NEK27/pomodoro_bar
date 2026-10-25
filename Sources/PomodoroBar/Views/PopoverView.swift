import AppKit
import SwiftUI

/// Панель, которая открывается по клику на время в строке меню.
struct PopoverView: View {
    @ObservedObject var engine: PomodoroEngine
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            Text(engine.phase.title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(engine.remaining.mmss)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()

            HStack {
                if engine.isRunning {
                    Button("Пауза", action: engine.pause)
                } else {
                    Button(engine.isPaused ? "Продолжить" : "Старт", action: engine.start)
                        .keyboardShortcut(.defaultAction)
                }
                Button("Сброс", action: engine.reset)
                    .disabled(engine.state == .idle)
                Button("Пропустить", action: engine.skip)
            }

            Text("Помодоро \(engine.cycleProgress.current) из \(engine.cycleProgress.total) · сегодня \(engine.completedPomodoros)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            HStack {
                Button("Настройки…") {
                    openWindow(id: SettingsView.windowID)
                    NSApp.activate(ignoringOtherApps: true)
                }
                Spacer()
                Button("Выйти") { NSApp.terminate(nil) }
            }
            .buttonStyle(.link)
        }
        .padding(16)
        .frame(width: 280)
    }
}
