import Foundation
import SwiftUI

/// Список задач и статистика за день. Задачи лежат в
/// ~/Library/Application Support/PomodoroBar/tasks.json, остальное в UserDefaults.
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var todayCount = 0
    @Published var currentTaskID: UUID? {
        didSet { defaults.set(currentTaskID?.uuidString, forKey: Key.currentTaskID) }
    }

    private enum Key {
        static let currentTaskID = "currentTaskID"
        static let statsDay = "statsDay"
        static let statsCount = "statsCount"
    }

    private let fileURL: URL
    private let defaults: UserDefaults

    static var defaultFileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PomodoroBar", isDirectory: true)
            .appendingPathComponent("tasks.json")
    }

    init(fileURL: URL = TaskStore.defaultFileURL, defaults: UserDefaults = .standard) {
        self.fileURL = fileURL
        self.defaults = defaults
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = saved
        }
        currentTaskID = defaults.string(forKey: Key.currentTaskID).flatMap(UUID.init(uuidString:))
        todayCount = defaults.string(forKey: Key.statsDay) == Self.today ? defaults.integer(forKey: Key.statsCount) : 0
    }

    var currentTask: TaskItem? {
        tasks.first { $0.id == currentTaskID }
    }

    var openTasks: [TaskItem] {
        tasks.filter { !$0.isDone }
    }

    var hasCompleted: Bool {
        tasks.contains { $0.isDone }
    }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let task = TaskItem(title: trimmed)
        tasks.append(task)
        if currentTask == nil {
            currentTaskID = task.id
        }
        save()
    }

    func setDone(_ id: UUID, _ isDone: Bool) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isDone = isDone
        if isDone && currentTaskID == id {
            currentTaskID = openTasks.first?.id
        }
        save()
    }

    func remove(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        if currentTaskID == id {
            currentTaskID = openTasks.first?.id
        }
        save()
    }

    func removeCompleted() {
        tasks.removeAll { $0.isDone }
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
        save()
    }

    /// Засчитать помодоро текущей задаче и в статистику за сегодня.
    func recordPomodoro() {
        if let index = tasks.firstIndex(where: { $0.id == currentTaskID }) {
            tasks[index].pomodoros += 1
            save()
        }
        if defaults.string(forKey: Key.statsDay) != Self.today {
            todayCount = 0
        }
        todayCount += 1
        defaults.set(Self.today, forKey: Key.statsDay)
        defaults.set(todayCount, forKey: Key.statsCount)
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(tasks).write(to: fileURL, options: .atomic)
        } catch {
            NSLog("PomodoroBar: не удалось сохранить задачи: \(error)")
        }
    }

    private static var today: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
