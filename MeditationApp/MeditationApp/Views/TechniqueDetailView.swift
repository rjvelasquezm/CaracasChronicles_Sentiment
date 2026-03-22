import SwiftUI

struct TechniqueDetailView: View {
    let technique: BreathingTechnique
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.07, blue: 0.14), Color(red: 0.03, green: 0.12, blue: 0.18)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: technique.systemIcon)
                                .font(.system(size: 32))
                                .foregroundColor(Color("AccentTeal"))
                                .frame(width: 60, height: 60)
                                .background(Color("AccentTeal").opacity(0.1))
                                .cornerRadius(14)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(technique.name)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(technique.subtitle)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                                DifficultyBadge(difficulty: technique.difficulty)
                                    .padding(.top, 2)
                            }
                        }

                        // Description
                        Text(technique.description)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.75))
                            .lineSpacing(5)

                        Divider().background(Color.white.opacity(0.1))

                        // Phase breakdown
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pattern")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .textCase(.uppercase)
                                .tracking(1.2)

                            HStack(spacing: 0) {
                                ForEach(technique.phases) { phase in
                                    PhaseBlock(phase: phase, total: technique.totalCycleDuration)
                                }
                            }
                            .frame(height: 48)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                            HStack {
                                ForEach(technique.phases) { phase in
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(phaseColor(phase.type))
                                            .frame(width: 8, height: 8)
                                        Text("\(phase.type.rawValue) \(Int(phase.duration))s")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            }

                            Text(String(format: "%.1f sec/cycle · %.1f breaths/min",
                                        technique.totalCycleDuration,
                                        technique.breathsPerMinute))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.35))
                        }

                        Divider().background(Color.white.opacity(0.1))

                        // Benefits
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Benefits")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .textCase(.uppercase)
                                .tracking(1.2)

                            ForEach(technique.benefits, id: \.self) { benefit in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color("AccentTeal"))
                                        .padding(.top, 1)
                                    Text(benefit)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.75))
                                }
                            }
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("AccentTeal"))
                }
            }
        }
    }

    private func phaseColor(_ type: BreathingPhaseType) -> Color {
        switch type {
        case .inhale: return Color(red: 0.2, green: 0.8, blue: 0.9)
        case .exhale: return Color(red: 0.5, green: 0.3, blue: 0.9)
        case .holdFull: return Color(red: 0.3, green: 0.7, blue: 0.5)
        case .holdEmpty: return Color(red: 0.4, green: 0.4, blue: 0.6)
        }
    }
}

struct PhaseBlock: View {
    let phase: BreathingPhase
    let total: Double

    private var width: CGFloat {
        CGFloat(phase.duration / total)
    }

    private var color: Color {
        switch phase.type {
        case .inhale: return Color(red: 0.2, green: 0.8, blue: 0.9).opacity(0.7)
        case .exhale: return Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.7)
        case .holdFull: return Color(red: 0.3, green: 0.7, blue: 0.5).opacity(0.7)
        case .holdEmpty: return Color(red: 0.4, green: 0.4, blue: 0.6).opacity(0.7)
        }
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .overlay(
                Text(phase.type.shortInstruction)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            )
            .frame(maxWidth: .infinity)
            .layoutPriority(phase.duration)
    }
}
