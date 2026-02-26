import Foundation
import SwiftUI

/// Represents a physiological milestone during fasting
struct PhysiologicalEvent: Identifiable {
    let id = UUID()
    let hourMark: Int
    let title: String
    let description: String
    let icon: String
    let category: EventCategory
    let motivationalQuote: String

    var dayMark: Double {
        Double(hourMark) / 24.0
    }

    enum EventCategory: String {
        case metabolic = "Metabolic"
        case cellular = "Cellular"
        case hormonal = "Hormonal"
        case neurological = "Neurological"
        case immune = "Immune"

        var color: Color {
            switch self {
            case .metabolic: return .orange
            case .cellular: return .green
            case .hormonal: return .purple
            case .neurological: return .blue
            case .immune: return .red
            }
        }
    }
}

/// All known physiological events during an extended fast
struct PhysiologicalTimeline {
    static let events: [PhysiologicalEvent] = [
        // Hours 0-12
        PhysiologicalEvent(
            hourMark: 0,
            title: "Fast Begins",
            description: "Your body begins using readily available glucose from your last meal. Insulin levels start to drop.",
            icon: "flag.fill",
            category: .metabolic,
            motivationalQuote: "Every journey begins with a single step. You've got this!"
        ),
        PhysiologicalEvent(
            hourMark: 4,
            title: "Blood Sugar Stabilizes",
            description: "Post-meal insulin spike subsides. Blood glucose levels begin normalizing as your body finishes processing the last meal.",
            icon: "chart.line.downtrend.xyaxis",
            category: .hormonal,
            motivationalQuote: "Your body is already starting to adjust. Stay strong!"
        ),
        PhysiologicalEvent(
            hourMark: 8,
            title: "Glycogen Depletion Begins",
            description: "Your liver begins tapping into stored glycogen (sugar reserves). This is your body's first fuel switch.",
            icon: "bolt.fill",
            category: .metabolic,
            motivationalQuote: "Your body is switching gears — burning through stored sugar now."
        ),
        // Hours 12-24
        PhysiologicalEvent(
            hourMark: 12,
            title: "Entering Early Ketosis",
            description: "Glycogen stores are running low. Your liver starts converting fatty acids into ketone bodies for fuel. Growth hormone begins to rise.",
            icon: "flame.fill",
            category: .metabolic,
            motivationalQuote: "Welcome to fat-burning mode! Your metabolism is shifting."
        ),
        PhysiologicalEvent(
            hourMark: 14,
            title: "Growth Hormone Surge",
            description: "Human growth hormone (HGH) levels begin increasing significantly, promoting fat burning and muscle preservation.",
            icon: "arrow.up.circle.fill",
            category: .hormonal,
            motivationalQuote: "HGH is rising — your body is protecting muscle while burning fat!"
        ),
        PhysiologicalEvent(
            hourMark: 16,
            title: "Autophagy Initiates",
            description: "Your cells begin \"self-cleaning\" — recycling damaged proteins and components. This is cellular housekeeping at its finest.",
            icon: "arrow.3.trianglepath",
            category: .cellular,
            motivationalQuote: "Autophagy is online! Your cells are literally cleaning house."
        ),
        PhysiologicalEvent(
            hourMark: 18,
            title: "Fat Burning Accelerates",
            description: "Your body is now primarily burning fat for fuel. Ketone levels continue to rise, providing clean energy to your brain.",
            icon: "flame.circle.fill",
            category: .metabolic,
            motivationalQuote: "You're a fat-burning machine now. Keep pushing!"
        ),
        // Day 1 (24h)
        PhysiologicalEvent(
            hourMark: 24,
            title: "Day 1 Complete — Full Ketosis",
            description: "Glycogen is mostly depleted. Ketone bodies are now a significant energy source. Insulin is at baseline. Inflammation markers start to decrease.",
            icon: "1.circle.fill",
            category: .metabolic,
            motivationalQuote: "Day 1 done! You've crossed into deep metabolic territory. Amazing!"
        ),
        PhysiologicalEvent(
            hourMark: 24,
            title: "Anti-Inflammatory Response",
            description: "Pro-inflammatory cytokines begin decreasing. Your body starts to reduce systemic inflammation.",
            icon: "shield.fill",
            category: .immune,
            motivationalQuote: "Your immune system is recalibrating. Inflammation is dropping."
        ),
        // Day 2 (48h)
        PhysiologicalEvent(
            hourMark: 36,
            title: "Deep Autophagy",
            description: "Autophagy is now in full effect. Damaged mitochondria and misfolded proteins are being aggressively recycled.",
            icon: "sparkles",
            category: .cellular,
            motivationalQuote: "Deep cellular repair is happening right now. You're renewing from within!"
        ),
        PhysiologicalEvent(
            hourMark: 48,
            title: "Day 2 Complete — Growth Hormone Peak",
            description: "HGH can be up to 5x baseline levels. Ketone-fueled brain clarity often peaks around this time. BDNF (brain growth factor) increases.",
            icon: "2.circle.fill",
            category: .hormonal,
            motivationalQuote: "Day 2 conquered! HGH is surging and your brain is getting sharper."
        ),
        PhysiologicalEvent(
            hourMark: 48,
            title: "BDNF Increases",
            description: "Brain-Derived Neurotrophic Factor rises, supporting neuron growth, learning, and memory. Many report enhanced mental clarity.",
            icon: "brain.head.profile",
            category: .neurological,
            motivationalQuote: "Your brain is growing new connections. Mental clarity is your reward!"
        ),
        // Day 3 (72h)
        PhysiologicalEvent(
            hourMark: 54,
            title: "Electrolyte Awareness",
            description: "Pay attention to sodium, potassium, and magnesium. Supplementing electrolytes becomes important for wellbeing.",
            icon: "drop.triangle.fill",
            category: .metabolic,
            motivationalQuote: "Stay on top of electrolytes — they're your best friend right now."
        ),
        PhysiologicalEvent(
            hourMark: 60,
            title: "Hunger Hormones Subside",
            description: "Ghrelin (the hunger hormone) starts to decrease. Many fasters report that hunger pangs become less intense.",
            icon: "arrow.down.circle.fill",
            category: .hormonal,
            motivationalQuote: "Hunger is fading! Your body has adapted to burning its own fuel."
        ),
        PhysiologicalEvent(
            hourMark: 72,
            title: "Day 3 Complete — Immune Reset Begins",
            description: "Research suggests immune system regeneration begins. Old white blood cells are broken down, triggering stem cell-based renewal.",
            icon: "3.circle.fill",
            category: .immune,
            motivationalQuote: "Day 3 done! Your immune system is regenerating. You're incredible!"
        ),
        PhysiologicalEvent(
            hourMark: 72,
            title: "Stem Cell Activation",
            description: "Hematopoietic stem cells shift toward self-renewal. Your body begins building a fresher, more efficient immune system.",
            icon: "leaf.fill",
            category: .cellular,
            motivationalQuote: "Stem cells are waking up. Renewal at the deepest level!"
        ),
        // Day 4 (96h)
        PhysiologicalEvent(
            hourMark: 84,
            title: "Ketone Adaptation",
            description: "Your brain is now highly efficient at using ketones. Many report euphoria, extreme mental clarity, and sustained energy.",
            icon: "brain",
            category: .neurological,
            motivationalQuote: "Your brain is fully keto-adapted. Ride the clarity wave!"
        ),
        PhysiologicalEvent(
            hourMark: 96,
            title: "Day 4 Complete — Deep Cellular Renewal",
            description: "Autophagy is at advanced levels. Damaged cellular components have been significantly cleared. Insulin sensitivity is greatly improved.",
            icon: "4.circle.fill",
            category: .cellular,
            motivationalQuote: "Day 4 down! You're in rare territory. Your body is thanking you."
        ),
        PhysiologicalEvent(
            hourMark: 96,
            title: "Insulin Sensitivity Restored",
            description: "Your cells have become highly sensitive to insulin again. This helps with glucose regulation long after the fast ends.",
            icon: "heart.circle.fill",
            category: .hormonal,
            motivationalQuote: "Your metabolic health is resetting. This benefit lasts well beyond the fast!"
        ),
        // Day 5 (120h)
        PhysiologicalEvent(
            hourMark: 108,
            title: "Peak Autophagy & Immune Renewal",
            description: "Cellular cleanup is at its maximum. Your immune system has been significantly refreshed with new white blood cells.",
            icon: "star.circle.fill",
            category: .immune,
            motivationalQuote: "You're at the summit! Peak cellular renewal is happening right now."
        ),
        PhysiologicalEvent(
            hourMark: 120,
            title: "Day 5 Complete — Fast Finished!",
            description: "Congratulations! You've completed a 5-day fast. Your body has undergone significant metabolic, cellular, and immune renewal. Refeed slowly and mindfully.",
            icon: "trophy.fill",
            category: .metabolic,
            motivationalQuote: "YOU DID IT! 5 days of incredible transformation. Be proud — you're a champion!"
        )
    ]

    /// Get events that have occurred by a given elapsed hour
    static func eventsCompleted(byHour hour: Int) -> [PhysiologicalEvent] {
        events.filter { $0.hourMark <= hour }
    }

    /// Get the next upcoming event
    static func nextEvent(afterHour hour: Int) -> PhysiologicalEvent? {
        events.first { $0.hourMark > hour }
    }

    /// Get the current/most recent event
    static func currentEvent(atHour hour: Int) -> PhysiologicalEvent? {
        events.last { $0.hourMark <= hour }
    }
}
