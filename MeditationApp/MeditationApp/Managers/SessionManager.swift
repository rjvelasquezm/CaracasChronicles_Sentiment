import Foundation
import Combine

// MARK: - Session Manager

/// Persists and retrieves meditation sessions; computes statistics.
@MainActor
final class SessionManager: ObservableObject {

    static let shared = SessionManager()

    @Published private(set) var sessions: [MeditationSession] = []

    private let storageKey = "meditationSessions"

    private init() {
        load()
    }

    // MARK: - CRUD

    func save(session: MeditationSession) {
        sessions.insert(session, at: 0)  // newest first
        persist()
    }

    func delete(sessionId: UUID) {
        sessions.removeAll { $0.id == sessionId }
        persist()
    }

    func deleteAll() {
        sessions.removeAll()
        persist()
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([MeditationSession].self, from: data)
        else { return }
        sessions = decoded
    }

    // MARK: - Statistics

    var stats: SessionStats {
        guard !sessions.isEmpty else { return .empty }

        let totalSessions = sessions.count
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        let totalMinutes = Int(totalSeconds) / 60
        let avgDuration = totalSeconds / Double(totalSessions)
        let completedCount = sessions.filter(\.wasCompleted).count
        let completionRate = Double(completedCount) / Double(totalSessions)

        // Favourite technique
        let techniqueCounts = Dictionary(grouping: sessions, by: \.techniqueName)
            .mapValues(\.count)
        let favTechnique = techniqueCounts.max(by: { $0.value < $1.value })?.key

        // Streak calculation
        let (current, longest) = computeStreaks()

        return SessionStats(
            totalSessions: totalSessions,
            totalMinutes: totalMinutes,
            currentStreak: current,
            longestStreak: longest,
            favoritesTechnique: favTechnique,
            avgSessionDuration: avgDuration,
            completionRate: completionRate
        )
    }

    private func computeStreaks() -> (current: Int, longest: Int) {
        let calendar = Calendar.current
        let dates = sessions
            .map { calendar.startOfDay(for: $0.startDate) }
            .sorted(by: >)

        var uniqueDates = [Date]()
        for d in dates {
            if uniqueDates.last != d { uniqueDates.append(d) }
        }

        guard !uniqueDates.isEmpty else { return (0, 0) }

        var current = 0
        let today = calendar.startOfDay(for: Date())
        if uniqueDates.first == today || uniqueDates.first == calendar.date(byAdding: .day, value: -1, to: today) {
            current = 1
            for i in 1..<uniqueDates.count {
                let diff = calendar.dateComponents([.day], from: uniqueDates[i], to: uniqueDates[i-1]).day ?? 0
                if diff == 1 { current += 1 } else { break }
            }
        }

        var longest = 1
        var runLength = 1
        for i in 1..<uniqueDates.count {
            let diff = calendar.dateComponents([.day], from: uniqueDates[i], to: uniqueDates[i-1]).day ?? 0
            if diff == 1 {
                runLength += 1
                longest = max(longest, runLength)
            } else {
                runLength = 1
            }
        }

        return (current, longest)
    }

    // MARK: - Filtered Views

    func sessions(for techniqueId: UUID) -> [MeditationSession] {
        sessions.filter { $0.techniqueId == techniqueId }
    }

    func sessionsThisWeek() -> [MeditationSession] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.startDate >= weekAgo }
    }

    func sessionsThisMonth() -> [MeditationSession] {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return sessions.filter { $0.startDate >= monthAgo }
    }
}
