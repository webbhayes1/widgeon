import Foundation

struct DrinkState: Codable {
    var date: String
    var count: Int
}

enum Drink {
    private static let stateKey = "drink.state"

    static var label: String {
        get { SharedStore.defaults.string(forKey: "drink.label") ?? "Water" }
        set { SharedStore.defaults.set(newValue, forKey: "drink.label") }
    }
    static var target: Int {
        get { max(1, SharedStore.defaults.integer(forKey: "drink.target") == 0 ? 8 : SharedStore.defaults.integer(forKey: "drink.target")) }
        set { SharedStore.defaults.set(newValue, forKey: "drink.target") }
    }
    /// Goal mode: fill the bar, celebrate at target (water).
    /// Limit mode: warn approaching target, tell the user off past it (booze).
    static var isLimit: Bool {
        get { SharedStore.defaults.bool(forKey: "drink.isLimit") }
        set { SharedStore.defaults.set(newValue, forKey: "drink.isLimit") }
    }
    static var emoji: String {
        get { SharedStore.defaults.string(forKey: "drink.emoji") ?? (isLimit ? "🥃" : "💧") }
        set { SharedStore.defaults.set(newValue, forKey: "drink.emoji") }
    }

    /// Limit mode uses a 6 AM day boundary — a night out doesn't end at midnight.
    static func dayKey(_ date: Date = Date()) -> String {
        let anchor = isLimit ? date.addingTimeInterval(-6 * 3600) : date
        return SharedStore.dayKey(anchor)
    }

    static func load() -> DrinkState {
        let today = dayKey()
        guard
            let data = SharedStore.defaults.data(forKey: stateKey),
            let state = try? JSONDecoder().decode(DrinkState.self, from: data),
            state.date == today
        else { return DrinkState(date: today, count: 0) }
        return state
    }

    static func save(_ state: DrinkState) {
        if let data = try? JSONEncoder().encode(state) {
            SharedStore.defaults.set(data, forKey: stateKey)
        }
    }

    @discardableResult
    static func increment() -> DrinkState {
        var state = load()
        state.count += 1
        save(state)
        if !isLimit && state.count == target {
            XP.award("drink.goal", 15)
        }
        return state
    }

    static func status(_ state: DrinkState) -> String {
        if !isLimit {
            return state.count >= target
                ? "Goal hit. Hydration royalty. 👑"
                : "\(target - state.count) to go. Tap to add."
        }
        let over = state.count - target
        if over < 0 {
            return over == -1 ? "One away from the limit. Easy." : "\(-over) below your limit. Pace yourself."
        }
        if over == 0 { return "Limit reached. Water time. 💧" }
        return "\(over) OVER the limit. Close the tab. 🚕"
    }
}
