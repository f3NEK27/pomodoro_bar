import AppKit
import SwiftUI

@main
struct PomodoroBarApp: App {
    @StateObject private var engine: PomodoroEngine
    @StateObject private var store: TaskStore

    init() {
        TimerSettings.registerDefaults()
        let store = TaskStore()
        let engine = PomodoroEngine()
        engine.onWorkCompleted = { [weak store] in store?.recordPomodoro() }
        engine.onFocusStarted = {
            if TimerSettings().openMusicOnFocus {
                FocusMusic.openInSpotify()
            }
        }
        _store = StateObject(wrappedValue: store)
        _engine = StateObject(wrappedValue: engine)
    }

    var body: some Scene {
        // Первая сцена открывается при запуске. После закрытия окна приложение
        // остаётся в строке меню, окно можно вернуть из панели.
        Window("PomodoroBar", id: MainWindow.windowID) {
            MainWindow(engine: engine, store: store)
        }
        .defaultSize(width: 940, height: 720)

        MenuBarExtra {
            PopoverView(engine: engine, store: store)
        } label: {
            MenuBarLabel(engine: engine)
        }
        .menuBarExtraStyle(.window)
    }
}
