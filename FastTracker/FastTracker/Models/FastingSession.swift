import Foundation

/// Represents a single fasting session
struct FastingSession: Codable, Identifiable {
    let id: UUID
    var startDate: Date
    var targetDurationHours: Int // e.g. 120 for 5 days
    var startingWeightKg: Double
    var heightCm: Double
    var age: Int
    var isMale: Bool
    var activityLevel: ActivityLevel
    var isActive: Bool

    var endDate: Date {
        startDate.addingTimeInterval(TimeInterval(targetDurationHours * 3600))
    }

    var targetDurationDays: Int {
        targetDurationHours / 24
    }

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        targetDurationHours: Int = 120,
        startingWeightKg: Double = 80,
        heightCm: Double = 175,
        age: Int = 30,
        isMale: Bool = true,
        activityLevel: ActivityLevel = .sedentary,
        isActive: Bool = true
    ) {
        self.id = id
        self.startDate = startDate
        self.targetDurationHours = targetDurationHours
        self.startingWeightKg = startingWeightKg
        self.heightCm = heightCm
        self.age = age
        self.isMale = isMale
        self.activityLevel = activityLevel
        self.isActive = isActive
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "Sedentary"
    case light = "Lightly Active"
    case moderate = "Moderately Active"
    case active = "Very Active"

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        }
    }
}
