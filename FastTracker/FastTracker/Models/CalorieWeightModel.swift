import Foundation

/// Calculates estimated calorie burn and weight loss during fasting
struct CalorieWeightModel {
    /// Calculate Basal Metabolic Rate using Mifflin-St Jeor equation
    static func bmr(weightKg: Double, heightCm: Double, age: Int, isMale: Bool) -> Double {
        if isMale {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        } else {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
    }

    /// Calculate Total Daily Energy Expenditure
    static func tdee(weightKg: Double, heightCm: Double, age: Int, isMale: Bool, activity: ActivityLevel) -> Double {
        bmr(weightKg: weightKg, heightCm: heightCm, age: age, isMale: isMale) * activity.multiplier
    }

    /// Estimated total calories burned since start of fast
    static func caloriesBurned(session: FastingSession, elapsedHours: Double) -> Double {
        let dailyTDEE = tdee(
            weightKg: session.startingWeightKg,
            heightCm: session.heightCm,
            age: session.age,
            isMale: session.isMale,
            activity: session.activityLevel
        )
        // During fasting, metabolism may slow ~10-15% after day 2
        let days = elapsedHours / 24.0
        let metabolicAdjustment: Double
        if days <= 1 {
            metabolicAdjustment = 1.0
        } else if days <= 2 {
            metabolicAdjustment = 0.97
        } else if days <= 3 {
            metabolicAdjustment = 0.93
        } else {
            metabolicAdjustment = 0.90
        }
        return (dailyTDEE * metabolicAdjustment * elapsedHours) / 24.0
    }

    /// Estimated weight lost in kg
    /// Uses a mix of water weight (early) and fat loss
    static func estimatedWeightLossKg(session: FastingSession, elapsedHours: Double) -> Double {
        let days = elapsedHours / 24.0

        // Water weight: ~1-2 kg in first 1-2 days (glycogen depletion releases water)
        let waterWeightLoss: Double
        if days <= 2 {
            waterWeightLoss = min(days * 0.8, 1.6) // up to 1.6 kg water
        } else {
            waterWeightLoss = 1.6
        }

        // Fat loss: ~3500 calories per pound of fat = 7700 cal per kg
        let totalCalBurned = caloriesBurned(session: session, elapsedHours: elapsedHours)
        let fatLossKg = totalCalBurned / 7700.0

        return waterWeightLoss + fatLossKg
    }

    /// Estimated weight lost in pounds
    static func estimatedWeightLossLbs(session: FastingSession, elapsedHours: Double) -> Double {
        estimatedWeightLossKg(session: session, elapsedHours: elapsedHours) * 2.20462
    }

    /// Estimated current weight
    static func estimatedCurrentWeightKg(session: FastingSession, elapsedHours: Double) -> Double {
        max(session.startingWeightKg - estimatedWeightLossKg(session: session, elapsedHours: elapsedHours), session.startingWeightKg * 0.9)
    }

    /// Daily calorie burn rate
    static func dailyBurnRate(session: FastingSession) -> Double {
        tdee(
            weightKg: session.startingWeightKg,
            heightCm: session.heightCm,
            age: session.age,
            isMale: session.isMale,
            activity: session.activityLevel
        )
    }

    /// Fuel source breakdown (approximate percentages)
    static func fuelSources(elapsedHours: Double) -> (glucose: Double, fat: Double, ketones: Double) {
        let hours = elapsedHours
        if hours < 8 {
            return (glucose: 0.70, fat: 0.25, ketones: 0.05)
        } else if hours < 16 {
            return (glucose: 0.40, fat: 0.45, ketones: 0.15)
        } else if hours < 24 {
            return (glucose: 0.15, fat: 0.50, ketones: 0.35)
        } else if hours < 48 {
            return (glucose: 0.05, fat: 0.45, ketones: 0.50)
        } else {
            return (glucose: 0.03, fat: 0.37, ketones: 0.60)
        }
    }
}
