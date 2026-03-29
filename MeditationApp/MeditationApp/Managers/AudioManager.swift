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

    // Sine-wave tone engine — avoids unreliable system sound IDs
    private let toneEngine = AVAudioEngine()
    private let toneNode   = AVAudioPlayerNode()
    private var toneEngineReady = false

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
        setupToneEngine()
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

        let instruction = phase.instruction
        // Stop any current speech, then allow one runloop cycle before enqueueing
        // the next utterance — avoids the synthesizer silently discarding it.
        speechSynthesizer.stopSpeaking(at: .immediate)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let utterance = AVSpeechUtterance(string: instruction)
            utterance.voice = self.preferredVoice
            utterance.rate = 0.38
            utterance.pitchMultiplier = 0.92
            utterance.volume = self.cueVolume
            self.speechSynthesizer.speak(utterance)
        }
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

    // MARK: - Tone Engine Setup

    private func setupToneEngine() {
        toneEngine.attach(toneNode)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        toneEngine.connect(toneNode, to: toneEngine.mainMixerNode, format: format)
        do {
            try toneEngine.start()
            toneEngineReady = true
        } catch {
            print("AudioManager: Tone engine failed to start — \(error)")
        }
    }

    // MARK: - Transition Tones

    /// Play a soft tone at each phase transition.
    /// Uses bundled audio files if present, otherwise synthesizes a sine-wave tone
    /// at a phase-appropriate pitch (reliable across all devices/volumes).
    func playTransitionTone(for phase: BreathingPhaseType) {
        guard isToneEnabled else { return }

        let toneName: String
        switch phase {
        case .inhale:     toneName = "tone_inhale"
        case .exhale:     toneName = "tone_exhale"
        case .holdFull, .holdEmpty: toneName = "tone_hold"
        }

        if let url = Bundle.main.url(forResource: toneName, withExtension: "wav") ??
                     Bundle.main.url(forResource: toneName, withExtension: "mp3"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            tonePlayer = player
            tonePlayer?.volume = cueVolume * 0.7
            tonePlayer?.play()
        } else {
            playSynthesizedTone(for: phase)
        }
    }

    /// Generate and play a brief sine-wave bell tone at a phase-specific pitch.
    /// This is the reliable fallback — no system sound IDs, no missing files.
    private func playSynthesizedTone(for phase: BreathingPhaseType) {
        guard toneEngineReady else { return }

        // Frequencies chosen for a calming, musical quality
        let frequency: Float
        switch phase {
        case .inhale:     frequency = 528   // ascending — "opening"
        case .exhale:     frequency = 396   // descending — "releasing"
        case .holdFull:   frequency = 440   // steady — "neutral"
        case .holdEmpty:  frequency = 369   // low — "empty"
        }

        let sampleRate: Double = 44100
        let duration: Double   = 0.55        // tone length in seconds
        let fadeFrames         = Int(sampleRate * 0.07)  // 70 ms fade in/out
        let frameCount         = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let data      = buffer.floatChannelData![0]
        let amplitude = cueVolume * 0.30     // moderate volume, not startling
        let twoPiF    = 2.0 * Float.pi * frequency

        for i in 0..<Int(frameCount) {
            var sample = sin(twoPiF * Float(i) / Float(sampleRate)) * amplitude
            // Fade in
            if i < fadeFrames {
                sample *= Float(i) / Float(fadeFrames)
            }
            // Fade out
            let fadeOutStart = Int(frameCount) - fadeFrames
            if i > fadeOutStart {
                sample *= Float(Int(frameCount) - i) / Float(fadeFrames)
            }
            data[i] = sample
        }

        toneNode.stop()
        toneNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
        toneNode.play()
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
