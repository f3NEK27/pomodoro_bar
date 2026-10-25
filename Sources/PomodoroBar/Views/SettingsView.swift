import SwiftUI

/// Окно настроек. Значения сохраняются в UserDefaults сразу при изменении.
struct SettingsView: View {
    static let windowID = "settings"

    @AppStorage(SettingsKey.workMinutes) private var workMinutes = 25
    @AppStorage(SettingsKey.shortBreakMinutes) private var shortBreakMinutes = 5
    @AppStorage(SettingsKey.longBreakMinutes) private var longBreakMinutes = 15
    @AppStorage(SettingsKey.cyclesBeforeLongBreak) private var cyclesBeforeLongBreak = 4
    @AppStorage(SettingsKey.autoStartBreaks) private var autoStartBreaks = true
    @AppStorage(SettingsKey.autoStartWork) private var autoStartWork = false
    @AppStorage(SettingsKey.soundEnabled) private var soundEnabled = true

    var body: some View {
        Form {
            Section("Длительность") {
                Stepper("Работа: \(workMinutes) мин", value: $workMinutes, in: 1...90)
                Stepper("Короткий перерыв: \(shortBreakMinutes) мин", value: $shortBreakMinutes, in: 1...30)
                Stepper("Длинный перерыв: \(longBreakMinutes) мин", value: $longBreakMinutes, in: 1...60)
                Stepper("Длинный перерыв после \(cyclesBeforeLongBreak) помодоро", value: $cyclesBeforeLongBreak, in: 2...8)
            }

            Section("Поведение") {
                Toggle("Сразу начинать перерыв", isOn: $autoStartBreaks)
                Toggle("Сразу начинать работу после перерыва", isOn: $autoStartWork)
                Toggle("Звук в конце интервала", isOn: $soundEnabled)
            }

            Section {
                Button("Вернуть значения по умолчанию") {
                    workMinutes = 25
                    shortBreakMinutes = 5
                    longBreakMinutes = 15
                    cyclesBeforeLongBreak = 4
                    autoStartBreaks = true
                    autoStartWork = false
                    soundEnabled = true
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }
}
