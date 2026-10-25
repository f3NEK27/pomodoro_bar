import SwiftUI

/// Экран таймера: тёмный живой фон, циферблат, кнопки и стеклянные карточки.
struct TimerScreen: View {
    @ObservedObject var engine: PomodoroEngine
    @ObservedObject var store: TaskStore

    private var tint: Color { engine.phase.tint }
    private var accent: Color { engine.phase.accent }

    var body: some View {
        ZStack {
            AuroraBackground(tint: tint, accent: accent, animated: engine.isRunning)

            VStack(spacing: 24) {
                PhaseTabs(current: engine.phase)

                ZStack {
                    DialRing(progress: engine.progress, tint: tint, accent: accent)
                    VStack(spacing: 4) {
                        Text(engine.remaining.mmss)
                            .font(.system(size: 72, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .shadow(color: tint.opacity(0.5), radius: 20)
                        statusLine
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .frame(width: 320, height: 320)

                HStack(spacing: 28) {
                    Button(action: engine.reset) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(CircleButtonStyle(tint: .white, size: 50))
                    .disabled(engine.state == .idle)
                    .help("Начать фазу заново")

                    Button(action: engine.isRunning ? engine.pause : engine.start) {
                        Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(CircleButtonStyle(tint: tint, size: 82, filled: true))
                    .keyboardShortcut(.space, modifiers: [])
                    .help(engine.isRunning ? "Пауза (пробел)" : "Старт (пробел)")

                    Button(action: engine.skip) {
                        Image(systemName: "forward.end.fill")
                    }
                    .buttonStyle(CircleButtonStyle(tint: .white, size: 50))
                    .help("Перейти к следующей фазе")
                }

                HStack(spacing: 14) {
                    CurrentTaskCard(store: store, tint: tint)
                    TodayCard(engine: engine, store: store, tint: tint)
                }
                .frame(maxWidth: 560)

                Button {
                    FocusMusic.openInSpotify()
                } label: {
                    Label("Музыка для фокуса", systemImage: "music.note")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Открыть плейлист в Spotify")
            }
            .padding(32)
        }
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var statusLine: some View {
        switch engine.state {
        case .running(let endDate):
            Text("закончится в \(endDate, style: .time)")
        case .paused:
            Text("на паузе")
        case .idle:
            Text(engine.phase == .work ? "готов к фокусу" : "время отдохнуть")
        }
    }
}

/// Три фазы цикла, активная подсвечена.
private struct PhaseTabs: View {
    var current: Phase

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Phase.allCases, id: \.self) { phase in
                let active = phase == current
                Label(phase.shortTitle, systemImage: phase.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(active ? Color.white : Color.white.opacity(0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(active ? AnyShapeStyle(phase.tint.gradient) : AnyShapeStyle(Color.clear))
                    )
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)
    }
}

/// Карточка текущей задачи с выбором из открытых.
private struct CurrentTaskCard: View {
    @ObservedObject var store: TaskStore
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ТЕКУЩАЯ ЗАДАЧА")
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.5))

            Menu {
                ForEach(store.openTasks) { task in
                    Button(task.title) { store.currentTaskID = task.id }
                }
                if !store.openTasks.isEmpty { Divider() }
                Button("Без задачи") { store.currentTaskID = nil }
            } label: {
                HStack {
                    Text(store.currentTask?.title ?? "Выберите задачу")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)

            if let task = store.currentTask, task.pomodoros > 0 {
                Text("уже \(task.pomodoros) 🍅 на эту задачу")
                    .font(.caption)
                    .foregroundStyle(tint)
            } else {
                Text(store.openTasks.isEmpty ? "добавьте задачи во вкладке «Задачи»" : "помодоро засчитаются ей")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .glassCard()
    }
}

/// Карточка дня: сколько помодоро сделано и где мы в цикле.
private struct TodayCard: View {
    @ObservedObject var engine: PomodoroEngine
    @ObservedObject var store: TaskStore
    var tint: Color

    var body: some View {
        let cycle = engine.cycleProgress
        let isWork = engine.phase == .work
        VStack(alignment: .leading, spacing: 8) {
            Text("СЕГОДНЯ")
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.5))

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(store.todayCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("помодоро")
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(spacing: 6) {
                ForEach(1...cycle.total, id: \.self) { index in
                    let done = isWork ? index < cycle.current : index <= cycle.current
                    let current = isWork && index == cycle.current
                    Capsule()
                        .fill(done ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(Color.white.opacity(0.12)))
                        .overlay(Capsule().stroke(tint, lineWidth: current ? 1.5 : 0))
                        .frame(height: 6)
                }
            }
        }
        .glassCard()
    }
}
