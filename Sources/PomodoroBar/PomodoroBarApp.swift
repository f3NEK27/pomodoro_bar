import AppKit
import SwiftUI

@main
struct PomodoroBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var engine: PomodoroEngine

    init() {
        TimerSettings.registerDefaults()
        _engine = StateObject(wrappedValue: PomodoroEngine())
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(engine: engine)
        } label: {
            MenuBarLabel(engine: engine)
        }
        .menuBarExtraStyle(.window)

        Window("Настройки", id: SettingsView.windowID) {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Без иконки в Dock: приложение живёт только в строке меню.
        NSApp.setActivationPolicy(.accessory)
    }
}
