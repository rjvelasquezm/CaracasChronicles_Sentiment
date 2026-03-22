import Foundation
import AVFoundation

// MARK: - Audio Manager

/// Handles all audio: ambient sounds, voice cues (TTS), and transition tones.
@MainActor
final class AudioManager: NSObject, ObservableObject {

    static let shared = AudioManager()

    @Published var currentAmbientSound: AmbientSound = .none
    @Published var ambientVolume: Float = 0.6
    @Published var cueVolume: Float = 1.0
    @Published var isVoiceEnabled: Bool = true
    @Published var isToneEnabled: Bool = true

    private var ambientPlayer: AVAudioPlayer?
    private var tonePlayer: AVAudioPlayer?
    private let speechSynthesizer = AVSpeechSynthesizer()

    // Preferred voice: calm, slow, natural
    private var preferredVoice: AVSpeechSynthesisVoice? {
        let preferred = ["com.apple.ttsbundle.siri_female_en-US_compact",
                         "com.apple.ttsbundle.Samantha-compact",
                         "com.apple.voice.compact.en-US.Samantha"]
        for id in preferred {
            if let voice = AVSpeechSynthesisVoice(identifier: id) { return voice }
        }
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    private override init() {
        super.init()
        configureAudioSession()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioManager: Failed to configure session — \(error)")
        }
    }

    // MARK: - Ambient Sounds

    func playAmbient(_ sound: AmbientSound) {
        stopAmbient()
        currentAmbientSound = sound

        guard let fileName = sound.fileName else { return }

        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") ??
                     Bundle.main.url(forResource: fileName, withExtension: "wav") {
            do {
                ambientPlayer = try AVAudioPlayer(contentsOf: url)
                ambientPlayer?.numberOfLoops = -1  // infinite loop
                ambientPlayer?.volume = ambientVolume
                ambientPlayer?.prepareToPlay()
                ambientPlayer?.play()
            } catch {
                print("AudioManager: Could not play \(fileName) — \(error)")
            }
        } else {
            // Fallback: synthesize ambient-like audio via system
            print("AudioManager: Ambient file \(fileName) not found in bundle — using silence")
        }
    }

    func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
    }

    func setAmbientVolume(_ volume: Float) {
        ambientVolume = volume
        ambientPlayer?.volume = volume
    }

    // MARK: - Voice Cues

    /// Speak the breathing phase instruction aloud.
    func speakPhase(_ phase: BreathingPhaseType, duration: Double) {
        guard isVoiceEnabled else { return }
        speechSynthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: phase.instruction)
        utterance.voice = preferredVoice
        utterance.rate = 0.38        // slow and soothing
        utterance.pitchMultiplier = 0.92
        utterance.volume = cueVolume
        utterance.preUtteranceDelay = 0.1
        speechSynthesizer.speak(utterance)
    }

    /// Speak a custom message.
    func speak(_ message: String) {
        guard isVoiceEnabled else { return }
        speechSynthesizer.stopSpeaking(at: .word)

        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = preferredVoice
        utterance.rate = 0.38
        utterance.pitchMultiplier = 0.92
        utterance.volume = cueVolume
        speechSynthesizer.speak(utterance)
    }

    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Transition Tones

    /// Play a soft bell tone at phase transitions.
    func playTransitionTone(for phase: BreathingPhaseType) {
        guard isToneEnabled else { return }

        // Try to play a bundled sound file first
        let toneName: String
        switch phase {
        case .inhale: toneName = "tone_inhale"
        case .exhale: toneName = "tone_exhale"
        case .holdFull, .holdEmpty: toneName = "tone_hold"
        }

        if let url = Bundle.main.url(forResource: toneName, withExtension: "wav") ??
                     Bundle.main.url(forResource: toneName, withExtension: "mp3") {
            do {
                tonePlayer = try AVAudioPlayer(contentsOf: url)
                tonePlayer?.volume = cueVolume * 0.7
                tonePlayer?.play()
            } catch {
                playSystemTone(for: phase)
            }
        } else {
            playSystemTone(for: phase)
        }
    }

    /// Fallback: use AudioServicesPlaySystemSound for a subtle click/tick
    private func playSystemTone(for phase: BreathingPhaseType) {
        // System sound IDs: 1057 (tock), 1104 (key click), 1306 (lock)
        let soundID: SystemSoundID
        switch phase {
        case .inhale: soundID = 1057
        case .exhale: soundID = 1052
        case .holdFull, .holdEmpty: soundID = 1000
        }
        AudioServicesPlaySystemSound(soundID)
    }

    // MARK: - Session Lifecycle

    func beginSession(sound: AmbientSound) {
        playAmbient(sound)
        speak("Beginning your meditation. Find a comfortable position.")
    }

    func endSession() {
        stopAmbient()
        stopSpeaking()
        speak("Session complete. Well done.")
    }

    func announceCompletion(cycles: Int) {
        let cycleText = cycles == 1 ? "1 cycle" : "\(cycles) cycles"
        speak("Great work. You completed \(cycleText).")
    }
}
