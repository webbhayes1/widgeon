import Foundation

struct PetStage {
    let minFeeds: Int
    let emoji: String
    let title: String
}

enum PetCharacter: String, CaseIterable, Codable, Identifiable {
    case duck, cat, plant, pixel
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .duck: return "Duck"
        case .cat: return "Cat"
        case .plant: return "Plant"
        case .pixel: return "Pixel Pal"
        }
    }

    var stages: [PetStage] {
        switch self {
        case .duck: return [
            .init(minFeeds: 0, emoji: "🥚", title: "A mysterious egg"),
            .init(minFeeds: 1, emoji: "🐣", title: "Hatchling"),
            .init(minFeeds: 3, emoji: "🐤", title: "Duckling"),
            .init(minFeeds: 7, emoji: "🐥", title: "Big duckling"),
            .init(minFeeds: 14, emoji: "🦆", title: "Proper duck"),
            .init(minFeeds: 30, emoji: "🦆", title: "✨ Radiant duck"),
            .init(minFeeds: 60, emoji: "🦆", title: "🎩 Distinguished duck"),
            .init(minFeeds: 100, emoji: "🦆", title: "👑 Duck royalty"),
        ]
        case .cat: return [
            .init(minFeeds: 0, emoji: "🥚", title: "A suspicious egg"),
            .init(minFeeds: 1, emoji: "🐱", title: "Kitten"),
            .init(minFeeds: 3, emoji: "😸", title: "Playful kitten"),
            .init(minFeeds: 7, emoji: "😺", title: "Happy cat"),
            .init(minFeeds: 14, emoji: "🐈", title: "Proper cat"),
            .init(minFeeds: 30, emoji: "🐈‍⬛", title: "✨ Mystic cat"),
            .init(minFeeds: 60, emoji: "😼", title: "🎩 Distinguished cat"),
            .init(minFeeds: 100, emoji: "🐅", title: "👑 Apex feline"),
        ]
        case .plant: return [
            .init(minFeeds: 0, emoji: "🌰", title: "A hopeful seed"),
            .init(minFeeds: 1, emoji: "🌱", title: "Sprout"),
            .init(minFeeds: 3, emoji: "🌿", title: "Seedling"),
            .init(minFeeds: 7, emoji: "🪴", title: "Potted & proud"),
            .init(minFeeds: 14, emoji: "🌳", title: "Young tree"),
            .init(minFeeds: 30, emoji: "🌸", title: "✨ In bloom"),
            .init(minFeeds: 60, emoji: "🌺", title: "🎩 Show-stopper"),
            .init(minFeeds: 100, emoji: "🌻", title: "👑 Garden royalty"),
        ]
        case .pixel: return [
            .init(minFeeds: 0, emoji: "🥚", title: "A glitchy egg"),
            .init(minFeeds: 1, emoji: "👾", title: "8-bit blob"),
            .init(minFeeds: 3, emoji: "👾", title: "16-bit critter"),
            .init(minFeeds: 7, emoji: "👾", title: "32-bit creature"),
            .init(minFeeds: 14, emoji: "👾", title: "64-bit being"),
            .init(minFeeds: 30, emoji: "👾", title: "✨ HD remaster"),
            .init(minFeeds: 60, emoji: "👾", title: "🎩 Ray-traced"),
            .init(minFeeds: 100, emoji: "👾", title: "👑 Final boss"),
        ]
        }
    }
}

struct PetState: Codable {
    var name: String = "Widge"
    var character: PetCharacter = .duck
    var feeds: Int = 0
    var lastFed: String? = nil
    var streak: Int = 0
    var best: Int = 0
}

enum Pet {
    private static let key = "pet.state"

    static func load() -> PetState {
        guard
            let data = SharedStore.defaults.data(forKey: key),
            let state = try? JSONDecoder().decode(PetState.self, from: data)
        else { return PetState() }
        return state
    }

    static func save(_ state: PetState) {
        if let data = try? JSONEncoder().encode(state) {
            SharedStore.defaults.set(data, forKey: key)
        }
    }

    static func stage(for state: PetState) -> PetStage {
        let stages = state.character.stages
        var current = stages[0]
        for s in stages where state.feeds >= s.minFeeds { current = s }
        return current
    }

    static func fedToday(_ state: PetState) -> Bool {
        state.lastFed == SharedStore.dayKey()
    }

    /// Feeds the pet if it hasn't been fed today. Returns true if a feed happened.
    @discardableResult
    static func feed(_ state: inout PetState) -> Bool {
        let today = SharedStore.dayKey()
        guard state.lastFed != today else { return false }
        let yesterday = SharedStore.dayKey(
            Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
        state.streak = (state.lastFed == yesterday) ? state.streak + 1 : 1
        state.best = max(state.best, state.streak)
        state.feeds += 1
        state.lastFed = today
        return true
    }

    static func mood(_ state: PetState) -> String {
        if state.feeds == 0 {
            return state.character == .plant ? "Tap to plant" : "Tap to hatch"
        }
        if fedToday(state) { return "Fed & happy" }
        guard let last = state.lastFed else { return "Hungry! Tap to feed" }
        let cal = Calendar.current
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let lastDate = f.date(from: last) ?? Date()
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: lastDate), to: cal.startOfDay(for: Date())).day ?? 1
        return days <= 1 ? "Hungry! Tap to feed" : "Missed you for \(days) days... 🥺"
    }
}
