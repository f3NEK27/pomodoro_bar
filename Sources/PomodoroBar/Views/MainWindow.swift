import AppKit
import SwiftUI

/// Главное окно: таймер, задачи и настройки в одном месте.
struct MainWindow: View {
    static let windowID = "main"

    enum Screen: String, CaseIterable, Identifiable {
        case timer, tasks, settings
        var id: Self { self }

        var title: String {
            switch self {
            case .timer: return "Таймер"
            case .tasks: return "Задачи"
            case .settings: return "Настройки"
            }
        }

        var symbol: String {
            switch self {
            case .timer: return "timer"
            case .tasks: return "checklist"
            case .settings: return "gearshape"
            }
        }
    }

    @ObservedObject var engine: PomodoroEngine
    @ObservedObject var store: TaskStore
    @State private var screen: Screen? = .timer

    var body: some View {
        NavigationSplitView {
            List(Screen.allCases, selection: $screen) { item in
                Label(item.title, systemImage: item.symbol)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190)
            .safeAreaInset(edge: .bottom) {
                SidebarStatus(engine: engine, store: store)
            }
        } detail: {
            switch screen ?? .timer {
            case .timer: TimerScreen(engine: engine, store: store)
            case .tasks: TasksScreen(store: store)
            case .settings: SettingsView()
            }
        }
        .frame(minWidth: 760, minHeight: 520)
        // Пока окно открыто, у приложения есть иконка в Dock; закрыли — живём только в строке меню.
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

/// Маленькая сводка внизу боковой панели: фаза, время и счётчик за сегодня.
private struct SidebarStatus: View {
    @ObservedObject var engine: PomodoroEngine
    @ObservedObject var store: TaskStore

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: engine.phase.symbol)
                .foregroundStyle(engine.phase.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(engine.remaining.mmss)
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                Text("Сегодня: \(store.todayCount) 🍅")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
    }
}
