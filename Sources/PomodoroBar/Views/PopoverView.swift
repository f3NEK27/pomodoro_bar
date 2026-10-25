import AppKit
import SwiftUI

/// Панель, которая открывается по клику на время в строке меню.
struct PopoverView: View {
    @ObservedObject var engine: PomodoroEngine
    @ObservedObject var store: TaskStore
    @Environment(\.openWindow) private var openWindow

    private var tint: Color { engine.phase.tint }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    ProgressRing(progress: engine.progress, tint: tint, lineWidth: 6)
                    Image(systemName: engine.phase.symbol)
                        .foregroundStyle(tint)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.phase.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(engine.remaining.mmss)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                Spacer()
            }

            HStack(spacing: 14) {
                Button(action: engine.reset) { Image(systemName: "arrow.counterclockwise") }
                    .buttonStyle(CircleButtonStyle(tint: tint, size: 36))
                    .disabled(engine.state == .idle)
                Button(action: engine.isRunning ? engine.pause : engine.start) {
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(CircleButtonStyle(tint: tint, size: 44, filled: true))
                .keyboardShortcut(.defaultAction)
                Button(action: engine.skip) { Image(systemName: "forward.end.fill") }
                    .buttonStyle(CircleButtonStyle(tint: tint, size: 36))
            }

            if !store.openTasks.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(store.openTasks.prefix(5)) { task in
                        HStack(spacing: 8) {
                            RoundCheckbox(isOn: task.isDone, tint: tint, size: 16) {
                                store.setDone(task.id, !task.isDone)
                            }
                            Text(task.title)
                                .fontWeight(store.currentTaskID == task.id ? .semibold : .regular)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                FocusMusic.openInSpotify()
            } label: {
                Label("Музыка для фокуса", systemImage: "music.note")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)

            Divider()

            HStack {
                Button("Открыть окно") {
                    openWindow(id: MainWindow.windowID)
                    NSApp.activate(ignoringOtherApps: true)
                }
                Spacer()
                Text("Сегодня: \(store.todayCount) 🍅")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Выйти") { NSApp.terminate(nil) }
            }
            .buttonStyle(.link)
            .font(.callout)
        }
        .padding(16)
        .frame(width: 300)
    }
}
