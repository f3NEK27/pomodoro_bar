import Combine
import Foundation

/// Обратный отсчёт одного интервала. Пока таймер идёт, хранится момент окончания,
/// а не счётчик секунд, поэтому сон Мака и задержки тика не сбивают время.
final class CountdownTimer: ObservableObject {
    enum State: Equatable {
        case idle
        case running(endDate: Date)
        case paused(remaining: TimeInterval)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var remaining: TimeInterval

    let duration: TimeInterval
    private var ticker: AnyCancellable?

    init(duration: TimeInterval = 25 * 60) {
        self.duration = duration
        self.remaining = duration
    }

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    func start() {
        switch state {
        case .running:
            return
        case .idle:
            state = .running(endDate: Date().addingTimeInterval(duration))
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

    func reset() {
        ticker = nil
        state = .idle
        remaining = duration
    }

    private func tick() {
        guard case .running(let endDate) = state else { return }
        let left = endDate.timeIntervalSinceNow
        guard left > 0 else {
            // Шаг 2: здесь будет переход к перерыву и уведомление.
            reset()
            return
        }
        remaining = left
    }
}

extension TimeInterval {
    /// «мм:сс», округление вверх: 24:59.3 показывается как 25:00.
    var mmss: String {
        let seconds = Int(rounded(.up))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
