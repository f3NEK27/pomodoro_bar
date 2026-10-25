import SwiftUI

/// Экран таймера: тёмный живой фон, циферблат, кнопки и стеклянные карточки.
struct TimerScreen: View {
    @ObservedObject var engine: PomodoroEngine
    @ObservedObject var store: TaskStore

    private var tint: Color { engine.phase.tint }
    private var accent: Color { engine.phase.accent }

    var body: some View {
        GeometryReader { geo in
            // Циферблат подстраивается под высоту окна, чтобы всё помещалось без прокрутки.
            let compact = geo.size.height < 640
            let spacing: CGFloat = compact ? 16 : 24
            let dial = min(340, max(180, geo.size.height - (compact ? 300 : 360)))

            ZStack {
                AuroraBackground(tint: tint, accent: accent, animated: engine.isRunning)

                VStack(spacing: spacing) {
                    PhaseTabs(current: engine.phase)

                    ZStack {
                        DialRing(progress: engine.progress, tint: tint, accent: accent)
                        VStack(spacing: 4) {
                            Text(engine.remaining.mmss)
                                .font(.system(size: dial * 0.22, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                                .shadow(color: tint.opacity(0.5), radius: 20)
                            statusLine
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .frame(width: dial, height: dial)

                    HStack(spacing: 28) {
                        Button(action: engine.reset) {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(CircleButtonStyle(tint: .white, size: compact ? 44 : 50))
                        .disabled(engine.state == .idle)
                        .help("Начать фазу заново")

                        Button(action: engine.isRunning ? engine.pause : engine.start) {
                            Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                        }
                        .buttonStyle(CircleButtonStyle(tint: tint, size: compact ? 66 : 80, filled: true))
                        .keyboardShortcut(.space, modifiers: [])
                        .help(engine.isRunning ? "Пауза (пробел)" : "Старт (пробел)")

                        Button(action: engine.skip) {
                            Image(systemName: "forward.end.fill")
                        }
                        .buttonStyle(CircleButtonStyle(tint: .white, size: compact ? 44 : 50))
                        .help("Перейти к следующей фазе")
                    }

                    HStack(spacing: 14) {
                        CurrentTaskCard(store: store, tint: tint)
                        TodayCard(engine: engine, store: store, tint: tint)
                    }
                    .frame(maxWidth: 560)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, spacing)
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .environment(\.colorScheme, .dark)
        // Прозрачная полоса заголовка: фон таймера уходит под неё, без белой плашки сверху.
        .toolbarBackground(.hidden, for: .windowToolbar)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    FocusMusic.openInSpotify()
                } label: {
                    Label("Музыка для фокуса", systemImage: "music.note")
                }
                .help("Открыть плейлист в Spotify")
            }
        }
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
