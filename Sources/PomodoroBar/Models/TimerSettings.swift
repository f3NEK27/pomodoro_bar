import Foundation

/// Ключи UserDefaults. Окно настроек пишет их через @AppStorage, движок читает отсюда.
enum SettingsKey {
    static let workMinutes = "workMinutes"
    static let shortBreakMinutes = "shortBreakMinutes"
    static let longBreakMinutes = "longBreakMinutes"
    static let cyclesBeforeLongBreak = "cyclesBeforeLongBreak"
    static let autoStartBreaks = "autoStartBreaks"
    static let autoStartWork = "autoStartWork"
    static let soundEnabled = "soundEnabled"
    static let openMusicOnFocus = "openMusicOnFocus"
}

struct TimerSettings {
    static let defaultValues: [String: Any] = [
        SettingsKey.workMinutes: 25,
        SettingsKey.shortBreakMinutes: 5,
        SettingsKey.longBreakMinutes: 15,
        SettingsKey.cyclesBeforeLongBreak: 4,
        SettingsKey.autoStartBreaks: true,
        SettingsKey.autoStartWork: false,
        SettingsKey.soundEnabled: true,
        SettingsKey.openMusicOnFocus: false,
    ]

    var defaults: UserDefaults = .standard

    static func registerDefaults(in defaults: UserDefaults = .standard) {
        defaults.register(defaults: defaultValues)
    }

    var cyclesBeforeLongBreak: Int { max(1, defaults.integer(forKey: SettingsKey.cyclesBeforeLongBreak)) }
    var soundEnabled: Bool { defaults.bool(forKey: SettingsKey.soundEnabled) }
    var openMusicOnFocus: Bool { defaults.bool(forKey: SettingsKey.openMusicOnFocus) }

    func duration(of phase: Phase) -> TimeInterval {
        let key: String
        switch phase {
        case .work: key = SettingsKey.workMinutes
        case .shortBreak: key = SettingsKey.shortBreakMinutes
        case .longBreak: key = SettingsKey.longBreakMinutes
        }
        return TimeInterval(max(1, defaults.integer(forKey: key)) * 60)
    }

    func autoStarts(_ phase: Phase) -> Bool {
        defaults.bool(forKey: phase == .work ? SettingsKey.autoStartWork : SettingsKey.autoStartBreaks)
    }
}
