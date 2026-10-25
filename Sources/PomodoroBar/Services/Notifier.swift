import AppKit
import UserNotifications

/// Звук и системное уведомление в конце интервала.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    /// Уведомления работают только из собранного .app: у голого `swift run` нет bundle id,
    /// и UNUserNotificationCenter в нём падает. Звук играет в обоих случаях.
    private let canPost = Bundle.main.bundleIdentifier != nil

    override init() {
        super.init()
        guard canPost else { return }
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func phaseFinished(_ finished: Phase, next: Phase, sound: Bool) {
        if sound {
            NSSound(named: "Glass")?.play()
        }
        guard canPost else { return }

        let content = UNMutableNotificationContent()
        content.title = finished == .work ? "Помодоро завершён" : "Перерыв окончен"
        content.body = "Дальше: \(next.title.lowercased())"
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // Показывать баннер, даже когда открыта панель приложения.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner])
    }
}
