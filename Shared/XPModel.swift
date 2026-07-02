import Foundation
import WidgetKit

/// Life XP: every Widgeon ritual grants XP, once per day per event.
/// Level thresholds are quadratic — early levels come fast, later ones
/// are a grind worth bragging about.
enum XP {
    static var total: Int {
        SharedStore.defaults.integer(forKey: "xp.total")
    }

    /// Awards points for an event, at most once per day per event kind.
    static func award(_ event: String, _ points: Int) {
        let dedupeKey = "xp.awarded.\(event)"
        let today = SharedStore.dayKey()
        guard SharedStore.defaults.string(forKey: dedupeKey) != today else { return }
        SharedStore.defaults.set(today, forKey: dedupeKey)
        SharedStore.defaults.set(total + points, forKey: "xp.total")
        WidgetCenter.shared.reloadTimelines(ofKind: "xp")
    }

    static func xpRequired(forLevel level: Int) -> Int {
        100 * (level - 1) * (level - 1)
    }

    static func level(for xp: Int) -> Int {
        Int((Double(xp) / 100).squareRoot()) + 1
    }

    static var level: Int { level(for: total) }

    /// Progress through the current level, 0...1.
    static var levelProgress: Double {
        let current = xpRequired(forLevel: level)
        let next = xpRequired(forLevel: level + 1)
        guard next > current else { return 0 }
        return Double(total - current) / Double(next - current)
    }

    static var toNextLevel: Int {
        max(0, xpRequired(forLevel: level + 1) - total)
    }
}
