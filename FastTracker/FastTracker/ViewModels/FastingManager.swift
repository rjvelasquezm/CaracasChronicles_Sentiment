import Foundation
import SwiftUI
import Combine
import UserNotifications

/// Main view model managing fasting session state
class FastingManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSession: FastingSession?
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var completedEvents: [PhysiologicalEvent] = []
    @Published var nextEvent: PhysiologicalEvent?
    @Published var isTimerRunning = false

    // MARK: - Computed Properties
    var elapsedHours: Double {
        elapsedSeconds / 3600.0
    }

    var elapsedDays: Double {
        elapsedHours / 24.0
    }

    var progressPercentage: Double {
        guard let session = currentSession else { return 0 }
        return min(elapsedHours / Double(session.targetDurationHours), 1.0)
    }

    var timeRemaining: TimeInterval {
        guard let session = currentSession else { return 0 }
        return max(TimeInterval(session.targetDurationHours * 3600) - elapsedSeconds, 0)
    }

    var caloriesBurned: Double {
        guard let session = currentSession else { return 0 }
        return CalorieWeightModel.caloriesBurned(session: session, elapsedHours: elapsedHours)
    }

    var estimatedWeightLossKg: Double {
        guard let session = currentSession else { return 0 }
        return CalorieWeightModel.estimatedWeightLossKg(session: session, elapsedHours: elapsedHours)
    }

    var estimatedWeightLossLbs: Double {
        estimatedWeightLossKg * 2.20462
    }

    var estimatedCurrentWeightKg: Double {
        guard let session = currentSession else { return 0 }
        return CalorieWeightModel.estimatedCurrentWeightKg(session: session, elapsedHours: elapsedHours)
    }

    var dailyBurnRate: Double {
        guard let session = currentSession else { return 0 }
        return CalorieWeightModel.dailyBurnRate(session: session)
    }

    var fuelSources: (glucose: Double, fat: Double, ketones: Double) {
        CalorieWeightModel.fuelSources(elapsedHours: elapsedHours)
    }

    var formattedElapsedTime: String {
        let totalSeconds = Int(elapsedSeconds)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if days > 0 {
            return String(format: "%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
        } else if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else {
            return String(format: "%dm %02ds", minutes, seconds)
        }
    }

    var formattedTimeRemaining: String {
        let totalSeconds = Int(timeRemaining)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 0 {
            return String(format: "%dd %dh %dm", days, hours, minutes)
        } else if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }

    var currentPhase: String {
        let hours = elapsedHours
        if hours < 8 { return "Fed State" }
        if hours < 12 { return "Early Fasting" }
        if hours < 18 { return "Glycogen Depletion" }
        if hours < 24 { return "Early Ketosis" }
        if hours < 48 { return "Ketosis" }
        if hours < 72 { return "Deep Ketosis" }
        if hours < 96 { return "Immune Renewal" }
        return "Extended Fast"
    }

    // MARK: - Private Properties
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let sessionKey = "currentFastingSession"
    private let startTimeKey = "fastingStartTime"

    // MARK: - Init
    init() {
        loadSession()
    }

    // MARK: - Session Management
    func startFast(
        durationDays: Int = 5,
        weightKg: Double,
        heightCm: Double,
        age: Int,
        isMale: Bool,
        activityLevel: ActivityLevel
    ) {
        let session = FastingSession(
            startDate: Date(),
            targetDurationHours: durationDays * 24,
            startingWeightKg: weightKg,
            heightCm: heightCm,
            age: age,
            isMale: isMale,
            activityLevel: activityLevel,
            isActive: true
        )

        currentSession = session
        elapsedSeconds = 0
        saveSession()
        startTimer()
        scheduleAllNotifications()
    }

    func endFast() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        currentSession?.isActive = false
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        clearSession()
    }

    // MARK: - Timer
    func startTimer() {
        guard let session = currentSession, session.isActive else { return }

        isTimerRunning = true
        elapsedSeconds = Date().timeIntervalSince(session.startDate)
        updateEvents()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let session = self.currentSession else { return }
            self.elapsedSeconds = Date().timeIntervalSince(session.startDate)
            self.updateEvents()

            // Auto-complete
            if self.elapsedSeconds >= TimeInterval(session.targetDurationHours * 3600) {
                self.endFast()
            }
        }
    }

    private func updateEvents() {
        let currentHour = Int(elapsedHours)
        completedEvents = PhysiologicalTimeline.eventsCompleted(byHour: currentHour)
        nextEvent = PhysiologicalTimeline.nextEvent(afterHour: currentHour)
    }

    // MARK: - Persistence
    private func saveSession() {
        guard let session = currentSession else { return }
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    private func loadSession() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(FastingSession.self, from: data),
              session.isActive else { return }

        currentSession = session
        elapsedSeconds = Date().timeIntervalSince(session.startDate)

        if elapsedSeconds < TimeInterval(session.targetDurationHours * 3600) {
            startTimer()
        } else {
            endFast()
        }
    }

    private func clearSession() {
        currentSession = nil
        elapsedSeconds = 0
        completedEvents = []
        nextEvent = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                print("Notification permission granted")
            }
        }
    }

    private func scheduleAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        guard let session = currentSession else { return }

        for event in PhysiologicalTimeline.events {
            guard event.hourMark > 0 else { continue }

            let triggerDate = session.startDate.addingTimeInterval(TimeInterval(event.hourMark * 3600))
            guard triggerDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "🔥 \(event.title)"
            content.body = "\(event.description)\n\n💪 \(event.motivationalQuote)"
            content.sound = .default
            content.categoryIdentifier = "FASTING_MILESTONE"

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: "fast-\(event.hourMark)h",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }

        // Schedule periodic motivational check-ins every 6 hours
        for hourOffset in stride(from: 6, through: session.targetDurationHours, by: 6) {
            // Skip if there's already a physiological event near this hour
            let hasNearbyEvent = PhysiologicalTimeline.events.contains { abs($0.hourMark - hourOffset) <= 2 }
            if hasNearbyEvent { continue }

            let triggerDate = session.startDate.addingTimeInterval(TimeInterval(hourOffset * 3600))
            guard triggerDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "⏱ Fasting Check-in"
            content.body = motivationalMessage(forHour: hourOffset)
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: "checkin-\(hourOffset)h",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    private func motivationalMessage(forHour hour: Int) -> String {
        let messages = [
            "You're \(hour) hours in! Your body is transforming. Stay strong! 💪",
            "\(hour) hours of fasting! Remember why you started. You've got this!",
            "Hour \(hour) — Your willpower is incredible. Keep going!",
            "\(hour)h in! Think about how amazing you'll feel at the finish line!",
            "Still going at \(hour) hours! Most people can't do what you're doing. 🏆",
            "\(hour) hours and counting! Your cells are thanking you right now.",
        ]
        return messages[hour % messages.count]
    }
}
