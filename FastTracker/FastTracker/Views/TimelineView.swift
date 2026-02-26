import SwiftUI

struct TimelineView: View {
    @ObservedObject var manager: FastingManager
    @State private var selectedCategory: PhysiologicalEvent.EventCategory?

    private var filteredEvents: [PhysiologicalEvent] {
        if let category = selectedCategory {
            return PhysiologicalTimeline.events.filter { $0.category == category }
        }
        return PhysiologicalTimeline.events
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Category Filter
                categoryFilter

                // Progress header
                progressHeader

                // Events list
                ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { index, event in
                    TimelineEventRow(
                        event: event,
                        isCompleted: event.hourMark <= Int(manager.elapsedHours),
                        isCurrent: isCurrentEvent(event),
                        isLast: index == filteredEvents.count - 1
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: .gray
                ) {
                    selectedCategory = nil
                }

                ForEach([
                    PhysiologicalEvent.EventCategory.metabolic,
                    .cellular,
                    .hormonal,
                    .neurological,
                    .immune
                ], id: \.rawValue) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Physiological Timeline")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("\(manager.completedEvents.count)/\(PhysiologicalTimeline.events.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * manager.progressPercentage, height: 4)
                        .animation(.easeInOut, value: manager.progressPercentage)
                }
            }
            .frame(height: 4)
        }
        .padding(.bottom, 16)
    }

    private func isCurrentEvent(_ event: PhysiologicalEvent) -> Bool {
        guard let current = PhysiologicalTimeline.currentEvent(atHour: Int(manager.elapsedHours)) else {
            return false
        }
        return current.hourMark == event.hourMark && current.title == event.title
    }
}

// MARK: - Timeline Event Row
struct TimelineEventRow: View {
    let event: PhysiologicalEvent
    let isCompleted: Bool
    let isCurrent: Bool
    let isLast: Bool

    @State private var isExpanded = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            VStack(spacing: 0) {
                // Dot
                ZStack {
                    Circle()
                        .fill(isCompleted ? event.category.color : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)

                    if isCurrent {
                        Circle()
                            .stroke(event.category.color, lineWidth: 3)
                            .frame(width: 32, height: 32)
                            .scaleEffect(isCurrent ? 1.2 : 1.0)

                        Circle()
                            .fill(event.category.color.opacity(0.3))
                            .frame(width: 32, height: 32)
                    }

                    Image(systemName: isCompleted ? "checkmark" : "circle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }

                // Line
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? event.category.color.opacity(0.3) : Color.gray.opacity(0.2))
                        .frame(width: 2)
                        .frame(minHeight: 60)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Time label
                HStack {
                    Text(event.hourMark >= 24
                        ? "Day \(event.hourMark / 24) (\(event.hourMark)h)"
                        : "\(event.hourMark)h"
                    )
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(event.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(event.category.color.opacity(0.1))
                    .cornerRadius(4)

                    Text(event.category.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                // Title
                HStack {
                    Image(systemName: event.icon)
                        .foregroundColor(event.category.color)
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isCompleted ? .primary : .secondary)
                }

                // Description
                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)

                // Motivational quote (shown if completed or current)
                if isCompleted || isCurrent {
                    Text(event.motivationalQuote)
                        .font(.caption)
                        .italic()
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                }

                if event.description.count > 80 {
                    Button(isExpanded ? "Show less" : "Show more") {
                        withAnimation { isExpanded.toggle() }
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCurrent
                        ? event.category.color.opacity(0.05)
                        : Color(.systemBackground)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrent ? event.category.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(.systemBackground))
                .cornerRadius(16)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
