import SwiftUI

struct HomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedTechnique: BreathingTechnique = BreathingTechnique.allTechniques[0]
    @State private var selectedDuration: Int = 300        // seconds
    @State private var selectedSound: AmbientSound = .rain
    @State private var showingSession = false
    @State private var showingTechniqueDetail = false

    private let durations = [60, 120, 180, 300, 600, 900, 1200]

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundGradientView()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero greeting
                        VStack(spacing: 4) {
                            Text(greetingText)
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(.white.opacity(0.9))
                            Text("Ready to breathe?")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 8)

                        // Stats Row
                        StatsRowView(stats: sessionManager.stats)

                        // Technique Picker
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Choose Technique")

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(BreathingTechnique.allTechniques) { technique in
                                        TechniqueCard(
                                            technique: technique,
                                            isSelected: technique.id == selectedTechnique.id,
                                            onSelect: { selectedTechnique = technique },
                                            onInfo: {
                                                selectedTechnique = technique
                                                showingTechniqueDetail = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Duration Picker
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Session Length")

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(durations, id: \.self) { seconds in
                                        DurationPill(
                                            seconds: seconds,
                                            isSelected: selectedDuration == seconds,
                                            onSelect: { selectedDuration = seconds }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Ambient Sound
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Ambient Sound")

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(AmbientSound.allCases) { sound in
                                        SoundPill(
                                            sound: sound,
                                            isSelected: selectedSound == sound,
                                            onSelect: { selectedSound = sound }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Start Button
                        Button(action: { showingSession = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Begin Session")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color("AccentTeal"))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingSession) {
            BreathingSessionView(
                technique: selectedTechnique,
                targetDuration: Double(selectedDuration),
                ambientSound: selectedSound
            )
        }
        .sheet(isPresented: $showingTechniqueDetail) {
            TechniqueDetailView(technique: selectedTechnique)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

// MARK: - Supporting Views

struct BackgroundGradientView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.07, blue: 0.14),
                Color(red: 0.03, green: 0.12, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct SectionHeader: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.4))
            .textCase(.uppercase)
            .tracking(1.2)
            .padding(.horizontal, 20)
    }
}

struct StatsRowView: View {
    let stats: SessionStats

    var body: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(stats.totalSessions)", label: "Sessions")
            Divider().frame(height: 32).background(Color.white.opacity(0.15))
            StatItem(value: "\(stats.totalMinutes)m", label: "Total Time")
            Divider().frame(height: 32).background(Color.white.opacity(0.15))
            StatItem(value: "\(stats.currentStreak)", label: "Day Streak")
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .padding(.horizontal, 20)
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

struct TechniqueCard: View {
    let technique: BreathingTechnique
    let isSelected: Bool
    let onSelect: () -> Void
    let onInfo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: technique.systemIcon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color("AccentTeal") : .white.opacity(0.7))
                Spacer()
                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Text(technique.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(technique.subtitle)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(2)

            HStack {
                DifficultyBadge(difficulty: technique.difficulty)
                Spacer()
                Text("\(Int(technique.breathsPerMinute * 10) / 10) bpm")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(14)
        .frame(width: 160, height: 130)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color("AccentTeal").opacity(0.15) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color("AccentTeal").opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
        )
        .onTapGesture(perform: onSelect)
    }
}

struct DifficultyBadge: View {
    let difficulty: BreathingTechnique.Difficulty

    var color: Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }

    var body: some View {
        Text(difficulty.rawValue)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}

struct DurationPill: View {
    let seconds: Int
    let isSelected: Bool
    let onSelect: () -> Void

    private var label: String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        return "\(m) min"
    }

    var body: some View {
        Button(action: onSelect) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(isSelected ? Color("AccentTeal") : Color.white.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct SoundPill: View {
    let sound: AmbientSound
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: sound.systemIcon)
                    .font(.system(size: 12))
                Text(sound.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .black : .white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? Color("AccentTeal") : Color.white.opacity(0.1))
            .cornerRadius(20)
        }
    }
}
