import AppKit
import SwiftUI

/// Панель, которая открывается по клику на время в строке меню.
struct PopoverView: View {
    @ObservedObject var timer: CountdownTimer

    var body: some View {
        VStack(spacing: 12) {
            Text(timer.remaining.mmss)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()

            HStack {
                if timer.isRunning {
                    Button("Пауза", action: timer.pause)
                } else {
                    Button(timer.isPaused ? "Продолжить" : "Старт", action: timer.start)
                        .keyboardShortcut(.defaultAction)
                }
                Button("Сброс", action: timer.reset)
                    .disabled(timer.state == .idle)
            }

            Divider()

            Button("Выйти") { NSApp.terminate(nil) }
                .buttonStyle(.link)
        }
        .padding(16)
        .frame(width: 240)
    }
}
