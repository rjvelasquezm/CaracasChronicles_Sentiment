import SwiftUI

struct SetupView: View {
    @ObservedObject var manager: FastingManager
    @State private var durationDays: Double = 5
    @State private var weightKg: String = "80"
    @State private var heightCm: String = "175"
    @State private var age: String = "30"
    @State private var isMale = true
    @State private var activityLevel: ActivityLevel = .sedentary
    @State private var useMetric = true

    private var weightValue: Double {
        let value = Double(weightKg) ?? 80
        return useMetric ? value : value * 0.453592 // convert lbs to kg
    }

    private var heightValue: Double {
        let value = Double(heightCm) ?? 175
        return useMetric ? value : value * 2.54 // convert inches to cm
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Duration
                durationSection

                // Body Stats
                bodyStatsSection

                // Activity Level
                activitySection

                // Preview
                previewSection

                // Start Button
                startButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Start Your Fast")
                .font(.title)
                .fontWeight(.bold)

            Text("Configure your fasting session below")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }

    // MARK: - Duration
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Duration", systemImage: "calendar")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Text("\(Int(durationDays)) Days")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Spacer()
                    Text("\(Int(durationDays * 24)) Hours")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Slider(value: $durationDays, in: 1...7, step: 1)
                    .tint(.orange)

                HStack {
                    ForEach([1, 2, 3, 5, 7], id: \.self) { day in
                        Button("\(day)d") {
                            withAnimation { durationDays = Double(day) }
                        }
                        .font(.caption)
                        .fontWeight(Int(durationDays) == day ? .bold : .regular)
                        .foregroundColor(Int(durationDays) == day ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Int(durationDays) == day ? Color.orange : Color(.systemGray5))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Body Stats
    private var bodyStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Body Stats", systemImage: "figure.stand")
                    .font(.headline)
                Spacer()
                Picker("Units", selection: $useMetric) {
                    Text("Metric").tag(true)
                    Text("Imperial").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }

            // Gender
            HStack {
                Text("Gender")
                    .foregroundColor(.secondary)
                Spacer()
                Picker("Gender", selection: $isMale) {
                    Text("Male").tag(true)
                    Text("Female").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }

            // Weight
            HStack {
                Text("Weight")
                    .foregroundColor(.secondary)
                Spacer()
                TextField(useMetric ? "kg" : "lbs", text: $weightKg)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                Text(useMetric ? "kg" : "lbs")
                    .foregroundColor(.secondary)
                    .frame(width: 30)
            }

            // Height
            HStack {
                Text("Height")
                    .foregroundColor(.secondary)
                Spacer()
                TextField(useMetric ? "cm" : "in", text: $heightCm)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                Text(useMetric ? "cm" : "in")
                    .foregroundColor(.secondary)
                    .frame(width: 30)
            }

            // Age
            HStack {
                Text("Age")
                    .foregroundColor(.secondary)
                Spacer()
                TextField("Age", text: $age)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                Text("yrs")
                    .foregroundColor(.secondary)
                    .frame(width: 30)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Activity Level
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Activity Level", systemImage: "figure.walk")
                .font(.headline)

            ForEach(ActivityLevel.allCases, id: \.self) { level in
                Button {
                    withAnimation { activityLevel = level }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(level.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text(activityDescription(level))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if activityLevel == level {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(activityLevel == level
                                ? Color.orange.opacity(0.1)
                                : Color(.systemGray6)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(activityLevel == level ? Color.orange : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Preview
    private var previewSection: some View {
        let dailyBurn = CalorieWeightModel.tdee(
            weightKg: weightValue,
            heightCm: heightValue,
            age: Int(age) ?? 30,
            isMale: isMale,
            activity: activityLevel
        )
        let totalEstBurn = dailyBurn * durationDays * 0.93
        let estWeightLoss = totalEstBurn / 7700 + 1.6 // fat + water

        return VStack(alignment: .leading, spacing: 12) {
            Label("Estimated Results", systemImage: "chart.bar.fill")
                .font(.headline)

            HStack {
                PreviewStat(title: "Daily Burn", value: "\(Int(dailyBurn))", unit: "kcal")
                Spacer()
                PreviewStat(title: "Total Burn", value: "\(Int(totalEstBurn))", unit: "kcal")
                Spacer()
                PreviewStat(title: "Weight Loss", value: String(format: "%.1f", estWeightLoss), unit: "kg")
            }

            Text("These are estimates based on the Mifflin-St Jeor equation. Actual results may vary.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Start Button
    private var startButton: some View {
        Button {
            manager.requestNotificationPermission()
            manager.startFast(
                durationDays: Int(durationDays),
                weightKg: weightValue,
                heightCm: heightValue,
                age: Int(age) ?? 30,
                isMale: isMale,
                activityLevel: activityLevel
            )
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Begin \(Int(durationDays))-Day Fast")
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .orange.opacity(0.3), radius: 10, y: 5)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers
    private func activityDescription(_ level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return "Little or no exercise, desk job"
        case .light: return "Light exercise 1-3 days/week"
        case .moderate: return "Moderate exercise 3-5 days/week"
        case .active: return "Hard exercise 6-7 days/week"
        }
    }
}

struct PreviewStat: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
