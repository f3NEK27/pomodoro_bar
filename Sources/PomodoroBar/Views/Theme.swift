import SwiftUI

extension Phase {
    var tint: Color {
        switch self {
        case .work: return Color(red: 0.98, green: 0.34, blue: 0.29)
        case .shortBreak: return Color(red: 0.13, green: 0.78, blue: 0.60)
        case .longBreak: return Color(red: 0.36, green: 0.50, blue: 1.00)
        }
    }

    /// Второй цвет фазы для градиентов и фона.
    var accent: Color {
        switch self {
        case .work: return Color(red: 1.00, green: 0.66, blue: 0.24)
        case .shortBreak: return Color(red: 0.22, green: 0.82, blue: 0.95)
        case .longBreak: return Color(red: 0.66, green: 0.42, blue: 1.00)
        }
    }

    var symbol: String {
        switch self {
        case .work: return "flame.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "leaf.fill"
        }
    }

    var shortTitle: String {
        switch self {
        case .work: return "Фокус"
        case .shortBreak: return "Перерыв"
        case .longBreak: return "Отдых"
        }
    }
}

/// Круглая кнопка: заливка цветом фазы для главного действия, лёгкий тон для остальных.
struct CircleButtonStyle: ButtonStyle {
    var tint: Color
    var size: CGFloat = 52
    var filled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.36, weight: .semibold))
            .foregroundStyle(filled ? Color.white : tint)
            .frame(width: size, height: size)
            .background(
                Circle().fill(filled ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(tint.opacity(0.16)))
            )
            .overlay(Circle().stroke(Color.white.opacity(filled ? 0.25 : 0.08), lineWidth: 1))
            .shadow(color: filled ? tint.opacity(0.55) : .clear, radius: 16, y: 6)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
            .contentShape(Circle())
    }
}

/// Простое кольцо прогресса для панели в строке меню.
struct ProgressRing: View {
    var progress: Double
    var tint: Color
    var lineWidth: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

/// Большое кольцо экрана таймера: 60 делений как на циферблате, градиент и светящаяся точка.
struct DialRing: View {
    var progress: Double
    var tint: Color
    var accent: Color

    private let inset: CGFloat = 36
    private let lineWidth: CGFloat = 18

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            ZStack {
                ForEach(0..<60, id: \.self) { index in
                    let passed = Double(index) / 60 < progress
                    let major = index % 5 == 0
                    Capsule()
                        .fill(Color.white.opacity(passed ? 0.85 : (major ? 0.28 : 0.14)))
                        .frame(width: major ? 3 : 1.5, height: major ? 12 : 6)
                        .offset(y: -radius + 8)
                        .rotationEffect(.degrees(Double(index) * 6))
                }

                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: lineWidth)
                    .padding(inset)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [accent, tint],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * max(progress, 0.01))
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(inset)
                    .shadow(color: tint.opacity(0.75), radius: 18)

                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .shadow(color: accent, radius: 8)
                    .offset(y: -(radius - inset))
                    .rotationEffect(.degrees(360 * progress))
                    .opacity(progress > 0.002 ? 1 : 0)
            }
            .frame(width: size, height: size)
            .animation(.linear(duration: 1), value: progress)
        }
    }
}

/// Тёмный фон с медленно плывущими цветными пятнами. Двигается, только пока идёт таймер.
struct AuroraBackground: View {
    var tint: Color
    var accent: Color
    var animated: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !animated)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.08)
                blob(tint, size: 460, x: cos(t / 7) * 150, y: sin(t / 9) * 90 - 120)
                blob(accent.opacity(0.75), size: 380, x: sin(t / 11) * 190, y: cos(t / 8) * 110 + 140)
                blob(tint.opacity(0.5), size: 300, x: cos(t / 13 + 2) * 220, y: sin(t / 10 + 1) * 160)
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.8), value: tint)
    }

    private func blob(_ color: Color, size: CGFloat, x: Double, y: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 110)
            .opacity(0.55)
            .offset(x: x, y: y)
    }
}

/// Полупрозрачная карточка «стекло».
struct GlassCard: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        modifier(GlassCard(padding: padding))
    }
}

/// Круглый чекбокс, который заливается цветом с пружинкой.
struct RoundCheckbox: View {
    var isOn: Bool
    var tint: Color
    var size: CGFloat = 20
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(isOn ? tint : Color.secondary.opacity(0.6), lineWidth: 1.5)
                Circle()
                    .fill(tint.gradient)
                    .scaleEffect(isOn ? 1 : 0.01)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(isOn ? 1 : 0)
            }
            .frame(width: size, height: size)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isOn)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
