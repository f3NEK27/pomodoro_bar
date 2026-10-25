import AppKit
import SwiftUI

@main
struct PomodoroBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var timer = CountdownTimer()

    var body: some Scene {
        MenuBarExtra {
            PopoverView(timer: timer)
        } label: {
            MenuBarLabel(timer: timer)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Без иконки в Dock: приложение живёт только в строке меню.
        NSApp.setActivationPolicy(.accessory)
    }
}
