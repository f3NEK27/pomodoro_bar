import SwiftUI

extension Phase {
    var tint: Color {
        switch self {
        case .work: return Color(red: 0.94, green: 0.33, blue: 0.27)
        case .shortBreak: return Color(red: 0.16, green: 0.70, blue: 0.56)
        case .longBreak: return Color(red: 0.30, green: 0.47, blue: 0.95)
        }
    }

    var symbol: String {
        switch self {
        case .work: return "flame.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "leaf.fill"
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
                Circle().fill(filled ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(tint.opacity(0.14)))
            )
            .shadow(color: filled ? tint.opacity(0.35) : .clear, radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Circle())
    }
}

/// Кольцо прогресса фазы.
struct ProgressRing: View {
    var progress: Double
    var tint: Color
    var lineWidth: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [tint.opacity(0.55), tint], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}
