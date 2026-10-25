import SwiftUI

/// Экран таймера: большое кольцо, кнопки, текущая задача и прогресс цикла.
struct TimerScreen: View {
    @ObservedObject var engine: PomodoroEngine
    @ObservedObject var store: TaskStore

    private var tint: Color { engine.phase.tint }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [tint.opacity(0.22), tint.opacity(0.04)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: engine.phase)

            VStack(spacing: 28) {
                Label(engine.phase.title, systemImage: engine.phase.symbol)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(tint.opacity(0.14)))

                ZStack {
                    ProgressRing(progress: engine.progress, tint: tint)
                    VStack(spacing: 6) {
                        Text(engine.remaining.mmss)
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text(store.currentTask?.title ?? "Задача не выбрана")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 200)
                    }
                }
                .frame(width: 280, height: 280)

                HStack(spacing: 24) {
                    Button(action: engine.reset) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(CircleButtonStyle(tint: tint))
                    .disabled(engine.state == .idle)
                    .help("Начать фазу заново")

                    Button(action: engine.isRunning ? engine.pause : engine.start) {
                        Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(CircleButtonStyle(tint: tint, size: 76, filled: true))
                    .keyboardShortcut(.space, modifiers: [])
                    .help(engine.isRunning ? "Пауза (пробел)" : "Старт (пробел)")

                    Button(action: engine.skip) {
                        Image(systemName: "forward.end.fill")
                    }
                    .buttonStyle(CircleButtonStyle(tint: tint))
                    .help("Перейти к следующей фазе")
                }

                CycleDots(progress: engine.cycleProgress, isWork: engine.phase == .work, tint: tint)

                Picker("Текущая задача", selection: $store.currentTaskID) {
                    Text("Не выбрана").tag(UUID?.none)
                    ForEach(store.openTasks) { task in
                        Text(task.title).tag(Optional(task.id))
                    }
                }
                .frame(maxWidth: 320)
            }
            .padding(32)
        }
    }
}

/// Точки цикла: закрашены завершённые помодоро, текущее обведено.
private struct CycleDots: View {
    var progress: (current: Int, total: Int)
    var isWork: Bool
    var tint: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ForEach(1...progress.total, id: \.self) { index in
                    let done = isWork ? index < progress.current : index <= progress.current
                    let current = isWork && index == progress.current
                    Circle()
                        .fill(done ? tint : tint.opacity(0.15))
                        .overlay(Circle().stroke(tint, lineWidth: current ? 2 : 0))
                        .frame(width: 12, height: 12)
                }
            }
            Text("Длинный перерыв после \(progress.total) помодоро")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
