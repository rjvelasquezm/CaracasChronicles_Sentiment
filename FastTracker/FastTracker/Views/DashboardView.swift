import SwiftUI

struct DashboardView: View {
    @ObservedObject var manager: FastingManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Timer Ring
                timerSection

                // Current Phase
                phaseCard

                // Stats Grid
                statsGrid

                // Fuel Sources
                fuelSourcesCard

                // Next Event Preview
                if let nextEvent = manager.nextEvent {
                    nextEventCard(event: nextEvent)
                }

                // End Fast Button
                endFastButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Timer Section
    private var timerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 200, height: 200)

                // Progress ring
                Circle()
                    .trim(from: 0, to: manager.progressPercentage)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .orange, .red]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: manager.progressPercentage)

                // Center content
                VStack(spacing: 4) {
                    Text(manager.formattedElapsedTime)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    Text("\(Int(manager.progressPercentage * 100))%")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(.orange)

                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Time remaining
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                Text("Remaining: \(manager.formattedTimeRemaining)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let session = manager.currentSession {
                Text("Ends: \(session.endDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    // MARK: - Phase Card
    private var phaseCard: some View {
        HStack {
            Image(systemName: "bolt.circle.fill")
                .font(.title2)
                .foregroundColor(.purple)
            VStack(alignment: .leading) {
                Text("Current Phase")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(manager.currentPhase)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            Spacer()
            Text("Day \(Int(manager.elapsedDays) + 1)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: "Calories Burned",
                value: String(format: "%.0f", manager.caloriesBurned),
                unit: "kcal",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                title: "Weight Lost",
                value: String(format: "%.1f", manager.estimatedWeightLossKg),
                unit: "kg",
                icon: "scalemass.fill",
                color: .green
            )
            StatCard(
                title: "Weight Lost",
                value: String(format: "%.1f", manager.estimatedWeightLossLbs),
                unit: "lbs",
                icon: "scalemass",
                color: .blue
            )
            StatCard(
                title: "Daily Burn",
                value: String(format: "%.0f", manager.dailyBurnRate),
                unit: "kcal/day",
                icon: "chart.bar.fill",
                color: .red
            )
        }
    }

    // MARK: - Fuel Sources
    private var fuelSourcesCard: some View {
        let sources = manager.fuelSources
        return VStack(alignment: .leading, spacing: 12) {
            Text("Energy Sources")
                .font(.headline)

            FuelBar(label: "Glucose", percentage: sources.glucose, color: .blue)
            FuelBar(label: "Fat", percentage: sources.fat, color: .orange)
            FuelBar(label: "Ketones", percentage: sources.ketones, color: .purple)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Next Event
    private func nextEventCard(event: PhysiologicalEvent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Coming Up Next")
                    .font(.headline)
                Spacer()
                let hoursUntil = event.hourMark - Int(manager.elapsedHours)
                Text("in ~\(hoursUntil)h")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }

            HStack(spacing: 12) {
                Image(systemName: event.icon)
                    .font(.title2)
                    .foregroundColor(event.category.color)
                    .frame(width: 40, height: 40)
                    .background(event.category.color.opacity(0.15))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - End Fast
    private var endFastButton: some View {
        Button(action: {
            manager.endFast()
        }) {
            HStack {
                Image(systemName: "stop.circle.fill")
                Text("End Fast")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.top, 8)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            HStack(spacing: 4) {
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Fuel Bar
struct FuelBar: View {
    let label: String
    let percentage: Double
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * percentage, height: 8)
                        .animation(.easeInOut, value: percentage)
                }
            }
            .frame(height: 8)

            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .frame(width: 35, alignment: .trailing)
        }
    }
}
