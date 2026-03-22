import SwiftUI

// MARK: - Main Session View

struct BreathingSessionView: View {
    let technique: BreathingTechnique
    let targetDuration: Double
    let ambientSound: AmbientSound

    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var phaseManager: BreathingPhaseManager
    @State private var showingExitAlert = false
    @Environment(\.dismiss) private var dismiss

    init(technique: BreathingTechnique, targetDuration: Double, ambientSound: AmbientSound) {
        self.technique = technique
        self.targetDuration = targetDuration
        self.ambientSound = ambientSound
        _phaseManager = StateObject(wrappedValue: BreathingPhaseManager(
            technique: technique,
            targetDuration: targetDuration,
            ambientSound: ambientSound
        ))
    }

    var body: some View {
        ZStack {
            SessionBackgroundView(phase: phaseManager.currentPhase.type)

            if phaseManager.isFinished {
                SessionCompleteView(
                    technique: technique,
                    duration: phaseManager.elapsedSeconds,
                    targetDuration: targetDuration,
                    cycles: phaseManager.completedCycles,
                    ambientSound: ambientSound,
                    onDismiss: { dismiss() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                VStack(spacing: 0) {
                    // Top bar
                    SessionTopBar(
                        techniqueName: technique.name,
                        elapsed: phaseManager.formattedElapsed,
                        remaining: phaseManager.formattedRemaining,
                        onExit: { showingExitAlert = true }
                    )

                    Spacer()

                    // Breathing circle
                    BreathingCircleView(
                        phase: phaseManager.currentPhase.type,
                        phaseProgress: phaseManager.phaseProgress,
                        countdown: phaseManager.countdownSeconds
                    )

                    Spacer()

                    // Phase label
                    VStack(spacing: 8) {
                        Text(phaseManager.currentPhaseName)
                            .font(.system(size: 32, weight: .thin))
                            .foregroundColor(.white)
                            .animation(.easeInOut(duration: 0.4), value: phaseManager.currentPhaseName)

                        Text("Cycle \(phaseManager.completedCycles + 1)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Spacer()

                    // Wim Hof special UI
                    if technique.isWimHof {
                        WimHofStatusView(phaseManager: phaseManager)
                            .padding(.bottom, 8)
                    }

                    // Session progress bar
                    SessionProgressBar(progress: phaseManager.sessionProgress)
                        .padding(.horizontal, 40)

                    // Controls
                    SessionControls(
                        isPaused: phaseManager.isPaused,
                        onTogglePause: { phaseManager.togglePause() },
                        onStop: { showingExitAlert = true }
                    )
                    .padding(.bottom, 48)
                }
            }
        }
        .onAppear {
            phaseManager.onSessionComplete = { cycles in
                saveSession(cycles: cycles, wasCompleted: true)
            }
            phaseManager.start()
        }
        .alert("End Session?", isPresented: $showingExitAlert) {
            Button("End & Save", role: .destructive) {
                let cycles = phaseManager.completedCycles
                let elapsed = phaseManager.elapsedSeconds
                phaseManager.stop()
                saveSession(cycles: cycles, wasCompleted: false)
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
    }

    private func saveSession(cycles: Int, wasCompleted: Bool) {
        let session = MeditationSession(
            techniqueId: technique.id,
            techniqueName: technique.name,
            duration: phaseManager.elapsedSeconds,
            targetDuration: targetDuration,
            completedCycles: cycles,
            wasCompleted: wasCompleted,
            ambientSound: ambientSound
        )
        sessionManager.save(session: session)
    }
}

// MARK: - Session Background

struct SessionBackgroundView: View {
    let phase: BreathingPhaseType

    private var colors: [Color] {
        switch phase {
        case .inhale:
            return [Color(red: 0.04, green: 0.10, blue: 0.22), Color(red: 0.02, green: 0.18, blue: 0.28)]
        case .exhale:
            return [Color(red: 0.06, green: 0.04, blue: 0.18), Color(red: 0.12, green: 0.04, blue: 0.22)]
        case .holdFull:
            return [Color(red: 0.02, green: 0.14, blue: 0.20), Color(red: 0.04, green: 0.18, blue: 0.24)]
        case .holdEmpty:
            return [Color(red: 0.04, green: 0.04, blue: 0.10), Color(red: 0.08, green: 0.06, blue: 0.14)]
        }
    }

    var body: some View {
        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.2), value: phase)
    }
}

// MARK: - Top Bar

struct SessionTopBar: View {
    let techniqueName: String
    let elapsed: String
    let remaining: String
    let onExit: () -> Void

    var body: some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(techniqueName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(remaining + " remaining")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Text(elapsed)
                .font(.system(size: 14, weight: .medium).monospacedDigit())
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - Session Progress Bar

struct SessionProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 3)
                Capsule()
                    .fill(Color("AccentTeal"))
                    .frame(width: geo.size.width * progress, height: 3)
                    .animation(.linear(duration: 0.05), value: progress)
            }
        }
        .frame(height: 3)
        .padding(.bottom, 24)
    }
}

// MARK: - Session Controls

struct SessionControls: View {
    let isPaused: Bool
    let onTogglePause: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 48) {
            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            Button(action: onTogglePause) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 72, height: 72)
                    .background(Color("AccentTeal"))
                    .clipShape(Circle())
            }

            // Placeholder for balance
            Color.clear
                .frame(width: 56, height: 56)
        }
    }
}

// MARK: - Wim Hof Status

struct WimHofStatusView: View {
    @ObservedObject var phaseManager: BreathingPhaseManager

    var body: some View {
        VStack(spacing: 8) {
            switch phaseManager.wimHofStage {
            case .breathing:
                Text("Breath \(phaseManager.wimHofBreathCount) of 30")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

            case .retentionExhale:
                VStack(spacing: 4) {
                    Text("Retention: \(Int(phaseManager.wimHofRetentionSeconds))s")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color("AccentTeal"))
                    Text("Exhale and hold — tap when ready to inhale")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    Button("Inhale & Hold") {
                        phaseManager.wimHofUserTriggeredRetention()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color("AccentTeal"))
                    .cornerRadius(20)
                }

            case .recoveryHold:
                Text("Recovery Hold — Inhale fully")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Session Complete

struct SessionCompleteView: View {
    let technique: BreathingTechnique
    let duration: TimeInterval
    let targetDuration: TimeInterval
    let cycles: Int
    let ambientSound: AmbientSound
    let onDismiss: () -> Void

    var completionPct: Int {
        Int(min(100, duration / targetDuration * 100))
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: CGFloat(completionPct) / 100)
                    .stroke(Color("AccentTeal"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(completionPct)%")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    Text("complete")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            VStack(spacing: 8) {
                Text("Well done")
                    .font(.system(size: 34, weight: .thin))
                    .foregroundColor(.white)

                Text(technique.name)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("AccentTeal"))
            }

            // Stats grid
            HStack(spacing: 20) {
                CompleteStat(value: formatDuration(duration), label: "Duration")
                CompleteStat(value: "\(cycles)", label: "Cycles")
                CompleteStat(value: ambientSound.rawValue, label: "Sound")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onDismiss) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color("AccentTeal"))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private func formatDuration(_ s: TimeInterval) -> String {
        let m = Int(s) / 60
        let sec = Int(s) % 60
        return m > 0 ? "\(m)m \(sec)s" : "\(sec)s"
    }
}

struct CompleteStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(12)
    }
}
