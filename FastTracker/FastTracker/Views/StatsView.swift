import SwiftUI

struct StatsView: View {
    @ObservedObject var manager: FastingManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if manager.currentSession != nil {
                    weightSection
                    caloriesSection
                    metabolicSection
                    bodyCompositionSection
                } else {
                    emptyState
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Weight Section
    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Weight Tracking", systemImage: "scalemass.fill")
                .font(.headline)

            if let session = manager.currentSession {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Starting")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", session.startingWeightKg))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: "arrow.right")
                        .foregroundColor(.orange)

                    VStack(spacing: 4) {
                        Text("Estimated Now")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", manager.estimatedCurrentWeightKg))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text("Lost")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "-%.1f", manager.estimatedWeightLossKg))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Weight loss breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Weight Loss Breakdown")
                    .font(.subheadline)
                    .fontWeight(.medium)

                let waterLoss = min(manager.elapsedDays * 0.8, 1.6)
                let fatLoss = manager.estimatedWeightLossKg - waterLoss

                HStack {
                    Circle().fill(.blue).frame(width: 8, height: 8)
                    Text("Water weight")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.1f kg", max(waterLoss, 0)))
                        .font(.caption)
                        .fontWeight(.medium)
                }

                HStack {
                    Circle().fill(.orange).frame(width: 8, height: 8)
                    Text("Fat loss")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.1f kg", max(fatLoss, 0)))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Calories Section
    private var caloriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Calorie Burn", systemImage: "flame.fill")
                .font(.headline)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", manager.caloriesBurned))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Total kcal burned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Text("Daily rate:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f kcal", manager.dailyBurnRate))
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Hourly rate:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f kcal", manager.dailyBurnRate / 24))
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    if let session = manager.currentSession {
                        HStack {
                            Text("BMR:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            let bmr = CalorieWeightModel.bmr(
                                weightKg: session.startingWeightKg,
                                heightCm: session.heightCm,
                                age: session.age,
                                isMale: session.isMale
                            )
                            Text(String(format: "%.0f kcal", bmr))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }

            // Daily breakdown
            if manager.elapsedDays >= 1 {
                Divider()
                Text("Daily Breakdown")
                    .font(.subheadline)
                    .fontWeight(.medium)

                let totalDays = Int(manager.elapsedDays) + 1
                ForEach(1...min(totalDays, 5), id: \.self) { day in
                    let dayHoursStart = Double((day - 1) * 24)
                    let dayHoursEnd = min(Double(day * 24), manager.elapsedHours)
                    let isCurrentDay = day == totalDays

                    if dayHoursEnd > dayHoursStart, let session = manager.currentSession {
                        let dayCalories = CalorieWeightModel.caloriesBurned(session: session, elapsedHours: dayHoursEnd) -
                            CalorieWeightModel.caloriesBurned(session: session, elapsedHours: dayHoursStart)

                        HStack {
                            Text("Day \(day)")
                                .font(.caption)
                                .fontWeight(isCurrentDay ? .bold : .regular)
                            if isCurrentDay {
                                Text("(in progress)")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            Spacer()
                            Text(String(format: "%.0f kcal", dayCalories))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Metabolic Section
    private var metabolicSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Metabolic State", systemImage: "waveform.path.ecg")
                .font(.headline)

            let sources = manager.fuelSources

            VStack(spacing: 12) {
                MetabolicRow(
                    label: "Glucose",
                    percentage: sources.glucose,
                    description: glucoseDescription,
                    color: .blue
                )
                MetabolicRow(
                    label: "Fat Oxidation",
                    percentage: sources.fat,
                    description: fatDescription,
                    color: .orange
                )
                MetabolicRow(
                    label: "Ketone Bodies",
                    percentage: sources.ketones,
                    description: ketoneDescription,
                    color: .purple
                )
            }

            Divider()

            // Estimated ketone level
            VStack(alignment: .leading, spacing: 4) {
                Text("Estimated Blood Ketones")
                    .font(.subheadline)
                    .fontWeight(.medium)

                let ketoneLevel = estimatedKetoneLevel
                HStack {
                    Text(String(format: "~%.1f mmol/L", ketoneLevel))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Spacer()
                    Text(ketoneDescription(level: ketoneLevel))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Body Composition
    private var bodyCompositionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Key Insights", systemImage: "lightbulb.fill")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                InsightRow(
                    icon: "flame.fill",
                    title: "Fat Burned",
                    value: String(format: "~%.0f g", (manager.caloriesBurned / 9.0)),
                    description: "Approximate grams of body fat metabolized"
                )

                InsightRow(
                    icon: "bolt.fill",
                    title: "Metabolic Rate",
                    value: manager.elapsedDays > 2 ? "~90% baseline" : "~100% baseline",
                    description: "Your metabolism adjusts slightly during extended fasts"
                )

                InsightRow(
                    icon: "arrow.up.circle.fill",
                    title: "Growth Hormone",
                    value: growthHormoneEstimate,
                    description: "HGH rises significantly during fasting"
                )

                InsightRow(
                    icon: "heart.fill",
                    title: "Insulin Level",
                    value: insulinEstimate,
                    description: "Low insulin promotes fat burning and cellular repair"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No Active Fast")
                .font(.title3)
                .fontWeight(.medium)
            Text("Start a fasting session to see detailed statistics")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helpers
    private var estimatedKetoneLevel: Double {
        let hours = manager.elapsedHours
        if hours < 12 { return 0.1 }
        if hours < 24 { return 0.5 }
        if hours < 48 { return 1.5 }
        if hours < 72 { return 3.0 }
        if hours < 96 { return 4.0 }
        return 5.0
    }

    private func ketoneDescription(level: Double) -> String {
        if level < 0.5 { return "Not in ketosis" }
        if level < 1.0 { return "Light ketosis" }
        if level < 3.0 { return "Moderate ketosis" }
        return "Deep ketosis"
    }

    private var glucoseDescription: String {
        if manager.elapsedHours < 12 { return "Primary fuel source from glycogen" }
        if manager.elapsedHours < 24 { return "Glycogen depleting, glucose dropping" }
        return "Minimal glucose via gluconeogenesis"
    }

    private var fatDescription: String {
        if manager.elapsedHours < 12 { return "Some fat being used for energy" }
        if manager.elapsedHours < 24 { return "Fat oxidation increasing rapidly" }
        return "Major fuel source via fat oxidation"
    }

    private var ketoneDescription: String {
        if manager.elapsedHours < 12 { return "Minimal ketone production" }
        if manager.elapsedHours < 24 { return "Ketone production ramping up" }
        return "Ketones are a primary energy source"
    }

    private var growthHormoneEstimate: String {
        if manager.elapsedHours < 14 { return "~1x baseline" }
        if manager.elapsedHours < 24 { return "~2x baseline" }
        if manager.elapsedHours < 48 { return "~3x baseline" }
        return "~5x baseline"
    }

    private var insulinEstimate: String {
        if manager.elapsedHours < 8 { return "Decreasing" }
        if manager.elapsedHours < 24 { return "Low" }
        return "Very low (baseline)"
    }
}

// MARK: - Metabolic Row
struct MetabolicRow: View {
    let label: String
    let percentage: Double
    let description: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(percentage * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                    Capsule().fill(color).frame(width: geo.size.width * percentage, height: 6)
                }
            }
            .frame(height: 6)

            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Insight Row
struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
