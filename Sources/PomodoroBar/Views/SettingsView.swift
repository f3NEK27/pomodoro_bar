import ServiceManagement
import SwiftUI

/// Экран настроек. Значения сохраняются в UserDefaults сразу при изменении.
struct SettingsView: View {
    @AppStorage(SettingsKey.workMinutes) private var workMinutes = 25
    @AppStorage(SettingsKey.shortBreakMinutes) private var shortBreakMinutes = 5
    @AppStorage(SettingsKey.longBreakMinutes) private var longBreakMinutes = 15
    @AppStorage(SettingsKey.cyclesBeforeLongBreak) private var cyclesBeforeLongBreak = 4
    @AppStorage(SettingsKey.autoStartBreaks) private var autoStartBreaks = true
    @AppStorage(SettingsKey.autoStartWork) private var autoStartWork = false
    @AppStorage(SettingsKey.soundEnabled) private var soundEnabled = true
    @AppStorage(SettingsKey.openMusicOnFocus) private var openMusicOnFocus = false
    // Состояние хранит сама macOS, поэтому читаем его оттуда, а не из UserDefaults.
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Настройки")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                section("Длительность") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                        ValueCard(title: Phase.work.shortTitle, symbol: Phase.work.symbol, tint: Phase.work.tint,
                                  unit: "мин", value: $workMinutes, range: 1...90)
                        ValueCard(title: Phase.shortBreak.shortTitle, symbol: Phase.shortBreak.symbol, tint: Phase.shortBreak.tint,
                                  unit: "мин", value: $shortBreakMinutes, range: 1...30)
                        ValueCard(title: Phase.longBreak.shortTitle, symbol: Phase.longBreak.symbol, tint: Phase.longBreak.tint,
                                  unit: "мин", value: $longBreakMinutes, range: 1...60)
                        ValueCard(title: "Цикл", symbol: "repeat", tint: Phase.longBreak.accent,
                                  unit: "помодоро", value: $cyclesBeforeLongBreak, range: 2...8)
                    }
                    Text("Длинный отдых наступает после указанного числа помодоро.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                section("Поведение") {
                    VStack(spacing: 0) {
                        toggleRow("Сразу начинать перерыв", symbol: "cup.and.saucer", isOn: $autoStartBreaks)
                        Divider()
                        toggleRow("Сразу начинать фокус после перерыва", symbol: "flame", isOn: $autoStartWork)
                        Divider()
                        toggleRow("Звук в конце интервала", symbol: "speaker.wave.2", isOn: $soundEnabled)
                        Divider()
                        toggleRow("Включать плейлист Spotify при старте фокуса", symbol: "music.note", isOn: $openMusicOnFocus)
                        Divider()
                        toggleRow("Запускать при входе в систему", symbol: "power", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { enabled in
                                setLaunchAtLogin(enabled)
                            }
                    }
                    .padding(.horizontal, 16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Text("Запуск при входе работает, когда приложение установлено в «Программы».")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("Вернуть значения по умолчанию", action: resetDefaults)
                    .buttonStyle(.borderless)
            }
            .padding(28)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func toggleRow(_ title: String, symbol: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: symbol)
        }
        .toggleStyle(.switch)
        .tint(Phase.work.tint)
        .padding(.vertical, 12)
    }

    private func resetDefaults() {
        workMinutes = 25
        shortBreakMinutes = 5
        longBreakMinutes = 15
        cyclesBeforeLongBreak = 4
        autoStartBreaks = true
        autoStartWork = false
        soundEnabled = true
        openMusicOnFocus = false
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("PomodoroBar: не удалось изменить запуск при входе: \(error)")
        }
        let actual = SMAppService.mainApp.status == .enabled
        if actual != launchAtLogin {
            launchAtLogin = actual
        }
    }
}

/// Карточка с крупным числом и кнопками − / +.
private struct ValueCard: View {
    let title: String
    let symbol: String
    let tint: Color
    let unit: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(unit)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                stepButton("minus", enabled: value > range.lowerBound) { value -= 1 }
                stepButton("plus", enabled: value < range.upperBound) { value += 1 }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [tint.opacity(0.18), tint.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.3), lineWidth: 1)
        )
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.18)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(tint)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
}
