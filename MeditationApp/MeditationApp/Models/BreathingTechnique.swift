import Foundation

// MARK: - Breathing Phase

enum BreathingPhaseType: String, Codable {
    case inhale = "Inhale"
    case exhale = "Exhale"
    case holdFull = "Hold"
    case holdEmpty = "Hold Empty"

    var instruction: String {
        switch self {
        case .inhale: return "Breathe In"
        case .exhale: return "Breathe Out"
        case .holdFull: return "Hold"
        case .holdEmpty: return "Hold Empty"
        }
    }

    var shortInstruction: String {
        switch self {
        case .inhale: return "In"
        case .exhale: return "Out"
        case .holdFull: return "Hold"
        case .holdEmpty: return "Hold"
        }
    }

    var color: String {
        switch self {
        case .inhale: return "InhaleColor"
        case .exhale: return "ExhaleColor"
        case .holdFull, .holdEmpty: return "HoldColor"
        }
    }

    var circleScale: Double {
        switch self {
        case .inhale: return 1.0       // expanding to full
        case .holdFull: return 1.0     // stay full
        case .exhale: return 0.4       // shrinking
        case .holdEmpty: return 0.4    // stay empty
        }
    }
}

struct BreathingPhase: Identifiable, Codable {
    let id: UUID
    let type: BreathingPhaseType
    let duration: Double  // seconds

    init(type: BreathingPhaseType, duration: Double) {
        self.id = UUID()
        self.type = type
        self.duration = duration
    }
}

// MARK: - Ambient Sound

enum AmbientSound: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case rain = "Rain"
    case oceanWaves = "Ocean Waves"
    case forest = "Forest"
    case whiteNoise = "White Noise"
    case tibetanBowl = "Tibetan Bowl"
    case softPiano = "Soft Piano"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .none: return "speaker.slash"
        case .rain: return "cloud.rain"
        case .oceanWaves: return "water.waves"
        case .forest: return "leaf"
        case .whiteNoise: return "waveform"
        case .tibetanBowl: return "music.note"
        case .softPiano: return "pianokeys"
        }
    }

    var fileName: String? {
        switch self {
        case .none: return nil
        case .rain: return "rain_ambient"
        case .oceanWaves: return "ocean_ambient"
        case .forest: return "forest_ambient"
        case .whiteNoise: return "whitenoise_ambient"
        case .tibetanBowl: return "tibetan_bowl_ambient"
        case .softPiano: return "piano_ambient"
        }
    }
}

// MARK: - Breathing Technique

struct BreathingTechnique: Identifiable, Codable {
    let id: UUID
    let name: String
    let subtitle: String
    let description: String
    let benefits: [String]
    let difficulty: Difficulty
    let phases: [BreathingPhase]
    let recommendedDuration: Int  // seconds
    let cycleCount: Int?          // nil = unlimited within duration
    let isWimHof: Bool            // Special handling for Wim Hof
    let systemIcon: String

    enum Difficulty: String, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"

        var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "orange"
            case .advanced: return "red"
            }
        }
    }

    var totalCycleDuration: Double {
        phases.reduce(0) { $0 + $1.duration }
    }

    var breathsPerMinute: Double {
        60.0 / totalCycleDuration
    }

    init(id: UUID = UUID(), name: String, subtitle: String, description: String,
         benefits: [String], difficulty: Difficulty, phases: [BreathingPhase],
         recommendedDuration: Int, cycleCount: Int? = nil, isWimHof: Bool = false,
         systemIcon: String) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.description = description
        self.benefits = benefits
        self.difficulty = difficulty
        self.phases = phases
        self.recommendedDuration = recommendedDuration
        self.cycleCount = cycleCount
        self.isWimHof = isWimHof
        self.systemIcon = systemIcon
    }
}

// MARK: - Built-in Techniques Library

extension BreathingTechnique {
    static let allTechniques: [BreathingTechnique] = [
        boxBreathing,
        breathing478,
        coherentBreathing,
        wimHof,
        triangleBreathing,
        twoToOneBreathing,
        diaphragmaticBreathing,
        resonantBreathing,
        physiologicalSigh
    ]

    /// Box Breathing — Navy SEAL / Dr. Mark Divine
    static let boxBreathing = BreathingTechnique(
        name: "Box Breathing",
        subtitle: "4-4-4-4 · Stress & Focus",
        description: "Used by Navy SEALs and elite athletes. Equal phases create perfect symmetry that calms the nervous system and sharpens focus. Also known as square breathing.",
        benefits: ["Reduces stress and anxiety", "Improves focus and concentration", "Regulates the autonomic nervous system", "Lowers cortisol", "Improves emotional regulation"],
        difficulty: .beginner,
        phases: [
            BreathingPhase(type: .inhale, duration: 4),
            BreathingPhase(type: .holdFull, duration: 4),
            BreathingPhase(type: .exhale, duration: 4),
            BreathingPhase(type: .holdEmpty, duration: 4)
        ],
        recommendedDuration: 300,
        systemIcon: "square"
    )

    /// 4-7-8 Breathing — Dr. Andrew Weil
    static let breathing478 = BreathingTechnique(
        name: "4-7-8 Breathing",
        subtitle: "4-7-8 · Relaxation & Sleep",
        description: "Developed by Dr. Andrew Weil based on pranayama. The extended hold builds carbon dioxide, and the long exhale activates the parasympathetic nervous system profoundly.",
        benefits: ["Promotes deep relaxation", "Helps with insomnia", "Reduces anxiety quickly", "Manages cravings", "Lowers heart rate"],
        difficulty: .beginner,
        phases: [
            BreathingPhase(type: .inhale, duration: 4),
            BreathingPhase(type: .holdFull, duration: 7),
            BreathingPhase(type: .exhale, duration: 8)
        ],
        recommendedDuration: 240,
        cycleCount: 8,
        systemIcon: "moon.stars"
    )

    /// Coherent / Resonant Breathing — Stephen Elliott
    static let coherentBreathing = BreathingTechnique(
        name: "Coherent Breathing",
        subtitle: "5.5-5.5 · HRV & Calm",
        description: "Researched by Stephen Elliott and popularized by James Nestor. 5.5 breaths per minute maximizes heart rate variability and creates the strongest relaxation response.",
        benefits: ["Maximizes HRV", "Deep parasympathetic activation", "Reduces blood pressure", "Improves mood", "Enhances respiratory efficiency"],
        difficulty: .beginner,
        phases: [
            BreathingPhase(type: .inhale, duration: 5.5),
            BreathingPhase(type: .exhale, duration: 5.5)
        ],
        recommendedDuration: 600,
        systemIcon: "heart.circle"
    )

    /// Wim Hof Method
    static let wimHof = BreathingTechnique(
        name: "Wim Hof Method",
        subtitle: "Hyperventilation + Retention",
        description: "30 rapid deep breaths followed by breath retention after exhale, then inhale and hold. Research shows effects on immune response, energy, and cold tolerance.",
        benefits: ["Energizes the body", "Reduces inflammation", "Strengthens immune system", "Increases stress tolerance", "Improves athletic performance"],
        difficulty: .advanced,
        phases: [
            BreathingPhase(type: .inhale, duration: 1.5),
            BreathingPhase(type: .exhale, duration: 1.5)
        ],
        recommendedDuration: 900,
        cycleCount: 30,
        isWimHof: true,
        systemIcon: "flame"
    )

    /// Triangle Breathing
    static let triangleBreathing = BreathingTechnique(
        name: "Triangle Breathing",
        subtitle: "4-4-4 · Anxiety Relief",
        description: "Three equal phases create a calming rhythm without the challenge of empty-lung holds. Ideal for anxiety management and quick stress relief.",
        benefits: ["Quick anxiety relief", "Easy to learn", "Grounding effect", "Suitable anytime, anywhere", "Calms racing thoughts"],
        difficulty: .beginner,
        phases: [
            BreathingPhase(type: .inhale, duration: 4),
            BreathingPhase(type: .holdFull, duration: 4),
            BreathingPhase(type: .exhale, duration: 4)
        ],
        recommendedDuration: 300,
        systemIcon: "triangle"
    )

    /// 2:1 Breathing (Exhale Emphasis)
    static let twoToOneBreathing = BreathingTechnique(
        name: "2:1 Breathing",
        subtitle: "4-8 · Deep Relaxation",
        description: "Exhale twice as long as inhale. This ratio strongly activates the parasympathetic nervous system. Based on yoga and pranayama traditions; backed by modern HRV research.",
        benefits: ["Strong relaxation response", "Lowers heart rate rapidly", "Reduces fight-or-flight", "Improves sleep quality", "Relieves tension headaches"],
        difficulty: .beginner,
        phases: [
            BreathingPhase(type: .inhale, duration: 4),
            BreathingPhase(type: .exhale, duration: 8)
        ],
        recommendedDuration: 300,
        systemIcon: "arrow.down.circle"
    )

    /// Diaphragmatic Breathing
    static let diaphragmaticBreathing = BreathingTechnique(
        name: "Diaphragmatic Breathing",
        subtitle: "Belly Breathing · Foundation",
        description: "The foundational breath. Slow, deep belly breathing is the basis for all other techniques. Research consistently shows reduced cortisol, improved oxygenation, and vagal activation.",
        benefits: ["Improves oxygen exchange", "Reduces cortisol", "Strengthens diaphragm", "Foundation for all breath work", "Reduces muscle tension"],
        difficulty: .beginner,
        phases: [
            BreathingPhase(type: .inhale, duration: 4),
            BreathingPhase(type: .exhale, duration: 6)
        ],
        recommendedDuration: 300,
        systemIcon: "lungs"
    )

    /// Resonant / Cardiac Coherence
    static let resonantBreathing = BreathingTechnique(
        name: "Cardiac Coherence",
        subtitle: "5-5 · Heart Rhythm",
        description: "From HeartMath Institute research. Six breaths per minute synchronizes heart rhythm, respiration, and blood pressure oscillations into a coherent state linked to optimal cognitive performance.",
        benefits: ["Cardiac coherence state", "Optimal cognitive function", "Emotional stability", "Immune function enhancement", "Reduces PTSD symptoms"],
        difficulty: .intermediate,
        phases: [
            BreathingPhase(type: .inhale, duration: 5),
            BreathingPhase(type: .exhale, duration: 5)
        ],
        recommendedDuration: 300,
        systemIcon: "waveform.path.ecg"
    )

    /// Physiological Sigh — Dr. Andrew Huberman / Stanford
    static let physiologicalSigh = BreathingTechnique(
        name: "Physiological Sigh",
        subtitle: "Double Inhale + Long Exhale",
        description: "Researched at Stanford by Dr. Mark Krasnow & popularized by Dr. Andrew Huberman. Double inhale re-inflates collapsed alveoli; long exhale rapidly offloads CO₂ and activates calm.",
        benefits: ["Fastest known anxiety reduction", "Re-inflates collapsed air sacs", "Rapid CO₂ offload", "Can work in 1-3 cycles", "Backed by strong clinical research"],
        difficulty: .beginner,
        phases: [
            BreathingPhase(type: .inhale, duration: 1.5),
            BreathingPhase(type: .inhale, duration: 0.5),
            BreathingPhase(type: .exhale, duration: 6)
        ],
        recommendedDuration: 120,
        systemIcon: "bolt.circle"
    )
}
