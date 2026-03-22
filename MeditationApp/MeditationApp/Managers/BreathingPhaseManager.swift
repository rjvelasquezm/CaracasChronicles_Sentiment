import Foundation
import Combine

// MARK: - Breathing Phase Manager

/// Drives the breathing timer: cycles through phases, fires audio cues,
/// and publishes state updates for the UI.
@MainActor
final class BreathingPhaseManager: ObservableObject {

    // MARK: Published state

    @Published private(set) var currentPhaseIndex: Int = 0
    @Published private(set) var currentPhase: BreathingPhase
    @Published private(set) var phaseProgress: Double = 0     // 0→1 within phase
    @Published private(set) var sessionProgress: Double = 0   // 0→1 overall
    @Published private(set) var elapsedSeconds: Double = 0
    @Published private(set) var completedCycles: Int = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isFinished: Bool = false

    // Wim Hof specific
    @Published private(set) var wimHofBreathCount: Int = 0
    @Published private(set) var wimHofRetentionSeconds: Double = 0
    @Published private(set) var wimHofStage: WimHofStage = .breathing

    enum WimHofStage {
        case breathing, retentionExhale, recoveryHold
    }

    // MARK: Private

    private var technique: BreathingTechnique
    private var targetDuration: Double
    private var ambientSound: AmbientSound
    private var timer: Timer?
    private var phaseStartTime: Date = Date()
    private var sessionStartTime: Date = Date()
    private let tickInterval: Double = 0.05   // 50ms ticks for smooth animation
    private var accumulatedPhaseTime: Double = 0
    private var accumulatedPauseTime: Double = 0
    private var pauseStartTime: Date?
    private let audioManager = AudioManager.shared

    // Wim Hof
    private var wimHofBreathsPerRound = 30
    private var wimHofRetentionStart: Date?
    private var wimHofRecoveryDuration: Double = 15

    // Callbacks
    var onSessionComplete: ((Int) -> Void)?   // completedCycles

    // MARK: Init

    init(technique: BreathingTechnique, targetDuration: Double, ambientSound: AmbientSound) {
        self.technique = technique
        self.targetDuration = targetDuration
        self.ambientSound = ambientSound
        self.currentPhase = technique.phases[0]
    }

    // MARK: - Control

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isPaused = false
        isFinished = false
        sessionStartTime = Date()
        phaseStartTime = Date()
        currentPhaseIndex = 0
        currentPhase = technique.phases[0]
        completedCycles = 0
        elapsedSeconds = 0
        phaseProgress = 0
        sessionProgress = 0
        accumulatedPhaseTime = 0
        accumulatedPauseTime = 0

        audioManager.beginSession(sound: ambientSound)
        audioManager.playTransitionTone(for: currentPhase.type)
        audioManager.speakPhase(currentPhase.type, duration: currentPhase.duration)

        scheduleTimer()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        pauseStartTime = Date()
        timer?.invalidate()
        audioManager.stopSpeaking()
    }

    func resume() {
        guard isRunning, isPaused else { return }
        if let pauseStart = pauseStartTime {
            accumulatedPauseTime += Date().timeIntervalSince(pauseStart)
        }
        isPaused = false
        pauseStartTime = nil
        scheduleTimer()
        audioManager.speakPhase(currentPhase.type, duration: currentPhase.duration)
    }

    func stop() {
        finishSession(early: true)
    }

    func togglePause() {
        if isPaused { resume() } else { pause() }
    }

    // MARK: - Timer

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    private func tick() {
        let now = Date()
        elapsedSeconds = now.timeIntervalSince(sessionStartTime) - accumulatedPauseTime
        sessionProgress = min(1.0, elapsedSeconds / targetDuration)

        // Check session complete
        if elapsedSeconds >= targetDuration {
            finishSession(early: false)
            return
        }

        if technique.isWimHof {
            tickWimHof(now: now)
        } else {
            tickNormal(now: now)
        }
    }

    // MARK: - Normal Breathing Tick

    private func tickNormal(now: Date) {
        let phaseDuration = currentPhase.duration
        let phaseElapsed = now.timeIntervalSince(phaseStartTime)
        accumulatedPhaseTime = phaseElapsed
        phaseProgress = min(1.0, phaseElapsed / phaseDuration)

        if phaseElapsed >= phaseDuration {
            advancePhase()
        }
    }

    private func advancePhase() {
        let nextIndex = currentPhaseIndex + 1

        if nextIndex >= technique.phases.count {
            // Completed one full cycle
            completedCycles += 1
            currentPhaseIndex = 0

            // Check cycle limit
            if let limit = technique.cycleCount, completedCycles >= limit {
                finishSession(early: false)
                return
            }
        } else {
            currentPhaseIndex = nextIndex
        }

        currentPhase = technique.phases[currentPhaseIndex]
        phaseStartTime = Date()
        phaseProgress = 0
        accumulatedPhaseTime = 0

        audioManager.playTransitionTone(for: currentPhase.type)
        audioManager.speakPhase(currentPhase.type, duration: currentPhase.duration)
    }

    // MARK: - Wim Hof Tick

    private func tickWimHof(now: Date) {
        switch wimHofStage {
        case .breathing:
            let phaseDuration = currentPhase.duration
            let phaseElapsed = now.timeIntervalSince(phaseStartTime)
            phaseProgress = min(1.0, phaseElapsed / phaseDuration)

            if phaseElapsed >= phaseDuration {
                // Alternate inhale/exhale
                currentPhaseIndex = currentPhaseIndex == 0 ? 1 : 0
                currentPhase = technique.phases[currentPhaseIndex]
                phaseStartTime = Date()
                phaseProgress = 0

                if currentPhaseIndex == 0 {
                    wimHofBreathCount += 1
                    audioManager.speakPhase(.inhale, duration: 1.5)
                    if wimHofBreathCount >= wimHofBreathsPerRound {
                        // Transition to retention
                        wimHofStage = .retentionExhale
                        wimHofRetentionStart = Date()
                        audioManager.speak("Exhale all air and hold")
                    }
                } else {
                    audioManager.speakPhase(.exhale, duration: 1.5)
                }
            }

        case .retentionExhale:
            guard let retStart = wimHofRetentionStart else { return }
            wimHofRetentionSeconds = now.timeIntervalSince(retStart)
            phaseProgress = min(1.0, wimHofRetentionSeconds / 120)  // cap at 2 min display
            // User breathes in after retention — we auto-advance at 90s or user taps
            if wimHofRetentionSeconds >= 90 {
                transitionToWimHofRecovery()
            }

        case .recoveryHold:
            guard let retStart = wimHofRetentionStart else { return }
            let elapsed = now.timeIntervalSince(retStart)
            phaseProgress = min(1.0, elapsed / wimHofRecoveryDuration)
            if elapsed >= wimHofRecoveryDuration {
                // Next round
                wimHofBreathCount = 0
                wimHofStage = .breathing
                completedCycles += 1
                currentPhaseIndex = 0
                currentPhase = technique.phases[0]
                phaseStartTime = Date()
                audioManager.speak("Begin the next round")
            }
        }
    }

    func wimHofUserTriggeredRetention() {
        // Called when user taps "I'm ready" during retention
        guard wimHofStage == .retentionExhale else { return }
        transitionToWimHofRecovery()
    }

    private func transitionToWimHofRecovery() {
        wimHofStage = .recoveryHold
        wimHofRetentionStart = Date()
        audioManager.speak("Inhale fully and hold for 15 seconds")
    }

    // MARK: - Finish

    private func finishSession(early: Bool) {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isFinished = true
        sessionProgress = early ? sessionProgress : 1.0

        if early {
            audioManager.stopAmbient()
            audioManager.stopSpeaking()
        } else {
            audioManager.endSession()
        }

        onSessionComplete?(completedCycles)
    }

    // MARK: - Display Helpers

    var remainingSeconds: Double {
        max(0, targetDuration - elapsedSeconds)
    }

    var currentPhaseName: String {
        currentPhase.type.instruction
    }

    var countdownSeconds: Int {
        let phaseElapsed = Date().timeIntervalSince(phaseStartTime)
        return max(0, Int(ceil(currentPhase.duration - phaseElapsed)))
    }

    var circleTargetScale: Double {
        currentPhase.type.circleScale
    }

    var formattedElapsed: String {
        formatTime(elapsedSeconds)
    }

    var formattedRemaining: String {
        formatTime(remainingSeconds)
    }

    private func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
