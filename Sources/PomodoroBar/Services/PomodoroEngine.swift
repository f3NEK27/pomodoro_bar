import Combine
import Foundation

/// Состояния и переходы таймера: работа → короткий перерыв → работа … → длинный перерыв.
/// Пока таймер идёт, хранится момент окончания, а не счётчик секунд,
/// поэтому сон Мака и задержки тика не сбивают время.
final class PomodoroEngine: ObservableObject {
    enum State: Equatable {
        case idle
        case running(endDate: Date)
        case paused(remaining: TimeInterval)
    }

    @Published private(set) var phase: Phase = .work
    @Published private(set) var state: State = .idle
    @Published private(set) var remaining: TimeInterval
    /// Завершённые рабочие интервалы с запуска приложения.
    @Published private(set) var completedPomodoros = 0

    private let settings: TimerSettings
    private let notifier: Notifier
    private var ticker: AnyCancellable?
    private var settingsObserver: AnyCancellable?

    init(settings: TimerSettings = TimerSettings(), notifier: Notifier = Notifier()) {
        self.settings = settings
        self.notifier = notifier
        self.remaining = settings.duration(of: .work)

        // Новая длительность из настроек сразу видна, пока таймер не запущен.
        settingsObserver = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, self.state == .idle else { return }
                self.remaining = self.settings.duration(of: self.phase)
            }
    }

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    /// Номер текущего помодоро в цикле до длинного перерыва, например 2 из 4.
    var cycleProgress: (current: Int, total: Int) {
        let total = settings.cyclesBeforeLongBreak
        let done = completedPomodoros % total
        if phase == .work { return (done + 1, total) }
        // На длинном перерыве цикл только что закончился: показываем «4 из 4», а не «0 из 4».
        return (done == 0 && completedPomodoros > 0 ? total : done, total)
    }

    func start() {
        switch state {
        case .running:
            return
        case .idle:
            state = .running(endDate: Date().addingTimeInterval(settings.duration(of: phase)))
        case .paused(let left):
            state = .running(endDate: Date().addingTimeInterval(left))
        }
        ticker = Timer.publish(every: 1, tolerance: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
        tick()
    }

    func pause() {
        guard case .running(let endDate) = state else { return }
        ticker = nil
        remaining = max(0, endDate.timeIntervalSinceNow)
        state = .paused(remaining: remaining)
    }

    /// Начать текущую фазу заново.
    func reset() {
        ticker = nil
        state = .idle
        remaining = settings.duration(of: phase)
    }

    /// Перейти к следующей фазе. Пропущенная работа не засчитывается.
    func skip() {
        advance(countingWork: false)
    }

    private func tick() {
        guard case .running(let endDate) = state else { return }
        let left = endDate.timeIntervalSinceNow
        guard left > 0 else {
            notifier.phaseFinished(phase, next: nextPhase(countingWork: true), sound: settings.soundEnabled)
            advance(countingWork: true)
            return
        }
        remaining = left
    }

    private func nextPhase(countingWork: Bool) -> Phase {
        guard phase == .work else { return .work }
        let completed = completedPomodoros + (countingWork ? 1 : 0)
        let isLong = countingWork && completed % settings.cyclesBeforeLongBreak == 0
        return isLong ? .longBreak : .shortBreak
    }

    private func advance(countingWork: Bool) {
        let next = nextPhase(countingWork: countingWork)
        if phase == .work && countingWork {
            completedPomodoros += 1
        }
        phase = next
        reset()
        if countingWork && settings.autoStarts(next) {
            start()
        }
    }
}
