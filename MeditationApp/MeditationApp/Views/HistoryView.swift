import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showingDeleteAll = false

    private var groupedSessions: [(String, [MeditationSession])] {
        let formatter = RelativeDateFormatter()
        let grouped = Dictionary(grouping: sessionManager.sessions) { session in
            formatter.string(from: session.startDate)
        }
        return grouped.sorted { a, b in
            let aDate = sessionManager.sessions.first(where: { formatter.string(from: $0.startDate) == a.key })?.startDate ?? Date()
            let bDate = sessionManager.sessions.first(where: { formatter.string(from: $0.startDate) == b.key })?.startDate ?? Date()
            return aDate > bDate
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.07, blue: 0.14),
                             Color(red: 0.03, green: 0.12, blue: 0.18)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                if sessionManager.sessions.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Stats summary
                            HistoryStatsView(stats: sessionManager.stats)
                                .padding(.horizontal, 20)

                            // Session list grouped by day
                            ForEach(groupedSessions, id: \.0) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(group.0)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.4))
                                        .textCase(.uppercase)
                                        .tracking(1)
                                        .padding(.horizontal, 20)

                                    ForEach(group.1) { session in
                                        SessionHistoryRow(session: session)
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }

                            Spacer(minLength: 32)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !sessionManager.sessions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") { showingDeleteAll = true }
                            .foregroundColor(.red.opacity(0.8))
                            .font(.system(size: 14))
                    }
                }
            }
            .alert("Clear All Sessions?", isPresented: $showingDeleteAll) {
                Button("Clear All", role: .destructive) { sessionManager.deleteAll() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

// MARK: - Stats Summary

struct HistoryStatsView: View {
    let stats: SessionStats

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                HistoryStat(icon: "calendar.badge.checkmark",
                            value: "\(stats.totalSessions)",
                            label: "Total Sessions")
                HistoryStat(icon: "clock",
                            value: "\(stats.totalMinutes)m",
                            label: "Total Time")
            }
            HStack(spacing: 12) {
                HistoryStat(icon: "flame",
                            value: "\(stats.currentStreak)",
                            label: "Current Streak")
                HistoryStat(icon: "trophy",
                            value: "\(stats.longestStreak)",
                            label: "Longest Streak")
            }
            if let fav = stats.favoritesTechnique {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color("AccentTeal"))
                    Text("Favorite: \(fav)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(String(format: "%.0f%% completion", stats.completionRate * 100))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
}

struct HistoryStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color("AccentTeal"))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Session Row

struct SessionHistoryRow: View {
    let session: MeditationSession

    var body: some View {
        HStack(spacing: 14) {
            // Completion ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: session.completionPercentage)
                    .stroke(session.wasCompleted ? Color("AccentTeal") : .orange,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: session.wasCompleted ? "checkmark" : "pause.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(session.wasCompleted ? Color("AccentTeal") : .orange)
            }
            .frame(width: 38, height: 38)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(session.techniqueName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    Text(session.formattedDuration)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    Text("·")
                        .foregroundColor(.white.opacity(0.3))
                    Text("\(session.completedCycles) cycles")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    if session.ambientSound != .none {
                        Text("·")
                            .foregroundColor(.white.opacity(0.3))
                        Image(systemName: session.ambientSound.systemIcon)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            Text(session.startDate, format: .dateTime.hour().minute())
                .font(.system(size: 12).monospacedDigit())
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Empty State

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wind")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.2))
            Text("No sessions yet")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.white.opacity(0.4))
            Text("Complete your first breathing session\nto see your history here.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
}

// MARK: - Relative Date Formatter

private struct RelativeDateFormatter {
    private let calendar = Calendar.current

    func string(from date: Date) -> String {
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: target, to: today).day ?? 0

        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        case 2...6: return "\(days) days ago"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}
