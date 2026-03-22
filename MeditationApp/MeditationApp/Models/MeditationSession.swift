import Foundation

// MARK: - Meditation Session

struct MeditationSession: Identifiable, Codable {
    let id: UUID
    let techniqueId: UUID
    let techniqueName: String
    let startDate: Date
    let duration: TimeInterval        // actual elapsed seconds
    let targetDuration: TimeInterval  // planned session length
    let completedCycles: Int
    let wasCompleted: Bool            // did user finish vs quit early
    let ambientSound: AmbientSound
    let notes: String

    init(
        id: UUID = UUID(),
        techniqueId: UUID,
        techniqueName: String,
        startDate: Date = Date(),
        duration: TimeInterval,
        targetDuration: TimeInterval,
        completedCycles: Int,
        wasCompleted: Bool,
        ambientSound: AmbientSound,
        notes: String = ""
    ) {
        self.id = id
        self.techniqueId = techniqueId
        self.techniqueName = techniqueName
        self.startDate = startDate
        self.duration = duration
        self.targetDuration = targetDuration
        self.completedCycles = completedCycles
        self.wasCompleted = wasCompleted
        self.ambientSound = ambientSound
        self.notes = notes
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes == 0 {
            return "\(seconds)s"
        } else if seconds == 0 {
            return "\(minutes)m"
        } else {
            return "\(minutes)m \(seconds)s"
        }
    }

    var completionPercentage: Double {
        guard targetDuration > 0 else { return 0 }
        return min(1.0, duration / targetDuration)
    }
}

// MARK: - Session Statistics

struct SessionStats {
    let totalSessions: Int
    let totalMinutes: Int
    let currentStreak: Int
    let longestStreak: Int
    let favoritesTechnique: String?
    let avgSessionDuration: TimeInterval
    let completionRate: Double

    static let empty = SessionStats(
        totalSessions: 0,
        totalMinutes: 0,
        currentStreak: 0,
        longestStreak: 0,
        favoritesTechnique: nil,
        avgSessionDuration: 0,
        completionRate: 0
    )
}
