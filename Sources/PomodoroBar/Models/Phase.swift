import Foundation

enum Phase: String, CaseIterable {
    case work
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .work: return "Работа"
        case .shortBreak: return "Короткий перерыв"
        case .longBreak: return "Длинный перерыв"
        }
    }

    var icon: String {
        self == .work ? "🍅" : "☕"
    }
}

extension TimeInterval {
    /// «мм:сс», округление вверх: 24:59.3 показывается как 25:00.
    var mmss: String {
        let seconds = Int(rounded(.up))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
