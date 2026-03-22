import SwiftUI

// MARK: - Breathing Circle Animation

/// The main visual element: a pulsating circle that expands on inhale,
/// stays large on hold, and contracts on exhale.
struct BreathingCircleView: View {
    let phase: BreathingPhaseType
    let phaseProgress: Double   // 0 → 1
    let countdown: Int

    // Circle size range
    private let minScale: CGFloat = 0.38
    private let maxScale: CGFloat = 1.0
    private let baseSize: CGFloat = 220

    private var circleScale: CGFloat {
        switch phase {
        case .inhale:
            // Growing: interpolate from min to max based on progress
            return minScale + CGFloat(phaseProgress) * (maxScale - minScale)
        case .holdFull:
            return maxScale
        case .exhale:
            // Shrinking: interpolate from max to min
            return maxScale - CGFloat(phaseProgress) * (maxScale - minScale)
        case .holdEmpty:
            return minScale
        }
    }

    private var glowColor: Color {
        switch phase {
        case .inhale: return Color(red: 0.2, green: 0.8, blue: 0.9)
        case .exhale: return Color(red: 0.5, green: 0.3, blue: 0.9)
        case .holdFull: return Color(red: 0.3, green: 0.85, blue: 0.85)
        case .holdEmpty: return Color(red: 0.3, green: 0.3, blue: 0.6)
        }
    }

    private var innerColor: Color {
        switch phase {
        case .inhale: return Color(red: 0.1, green: 0.5, blue: 0.7).opacity(0.3)
        case .exhale: return Color(red: 0.3, green: 0.1, blue: 0.5).opacity(0.3)
        case .holdFull: return Color(red: 0.1, green: 0.5, blue: 0.6).opacity(0.4)
        case .holdEmpty: return Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.3)
        }
    }

    var body: some View {
        ZStack {
            // Outermost ambient glow
            Circle()
                .fill(glowColor.opacity(0.05))
                .frame(width: baseSize * 1.5, height: baseSize * 1.5)
                .scaleEffect(circleScale * 0.85 + 0.15)

            // Ripple rings (phase progress rings)
            ForEach(0..<3) { i in
                Circle()
                    .stroke(glowColor.opacity(0.08 - Double(i) * 0.02), lineWidth: 1)
                    .frame(
                        width: baseSize * (1.0 + CGFloat(i) * 0.15),
                        height: baseSize * (1.0 + CGFloat(i) * 0.15)
                    )
                    .scaleEffect(circleScale)
            }

            // Main filled circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(0.6), innerColor],
                        center: .center,
                        startRadius: 0,
                        endRadius: baseSize * circleScale / 2
                    )
                )
                .frame(width: baseSize, height: baseSize)
                .scaleEffect(circleScale)
                .shadow(color: glowColor.opacity(0.4), radius: 30, x: 0, y: 0)

            // Progress arc on the circle edge
            Circle()
                .trim(from: 0, to: phaseProgress)
                .stroke(
                    glowColor,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: baseSize * circleScale, height: baseSize * circleScale)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: phaseProgress)

            // Countdown number in center
            VStack(spacing: 4) {
                Text("\(countdown)")
                    .font(.system(size: 52, weight: .ultraLight).monospacedDigit())
                    .foregroundColor(.white.opacity(0.9))
                    .contentTransition(.numericText())

                Text(phase.shortInstruction)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(2)
            }
        }
        .frame(width: baseSize * 1.6, height: baseSize * 1.6)
        .animation(.easeInOut(duration: 0.6), value: phase)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BreathingCircleView(
            phase: .inhale,
            phaseProgress: 0.5,
            countdown: 3
        )
    }
}
