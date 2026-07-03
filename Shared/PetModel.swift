import Foundation

struct PetStage {
    let minXP: Int
    let emoji: String
    let title: String
}

enum PetCharacter: String, CaseIterable, Codable, Identifiable {
    case duck, cat, dog, turtle, plant, pixel
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .duck: return "Duck"
        case .cat: return "Cat"
        case .dog: return "Dog"
        case .turtle: return "Turtle"
        case .plant: return "Plant"
        case .pixel: return "Pixel Pal"
        }
    }

    var stages: [PetStage] {
        switch self {
        case .duck: return [
            .init(minXP: 0, emoji: "🥚", title: "A mysterious egg"),
            .init(minXP: 20, emoji: "🐣", title: "Hatchling"),
            .init(minXP: 100, emoji: "🐤", title: "Duckling"),
            .init(minXP: 250, emoji: "🐥", title: "Big duckling"),
            .init(minXP: 500, emoji: "🦆", title: "Proper duck"),
            .init(minXP: 900, emoji: "🦆", title: "✨ Radiant duck"),
            .init(minXP: 1500, emoji: "🦆", title: "🎩 Distinguished duck"),
            .init(minXP: 2500, emoji: "🦆", title: "👑 Duck royalty"),
        ]
        case .cat: return [
            .init(minXP: 0, emoji: "🥚", title: "A suspicious egg"),
            .init(minXP: 20, emoji: "🐱", title: "Kitten"),
            .init(minXP: 100, emoji: "😸", title: "Playful kitten"),
            .init(minXP: 250, emoji: "😺", title: "Happy cat"),
            .init(minXP: 500, emoji: "🐈", title: "Proper cat"),
            .init(minXP: 900, emoji: "🐈‍⬛", title: "✨ Mystic cat"),
            .init(minXP: 1500, emoji: "😼", title: "🎩 Distinguished cat"),
            .init(minXP: 2500, emoji: "🐅", title: "👑 Apex feline"),
        ]
        case .dog: return [
            .init(minXP: 0, emoji: "🥚", title: "A wiggly egg"),
            .init(minXP: 20, emoji: "🐶", title: "Puppy"),
            .init(minXP: 100, emoji: "🐕", title: "Growing pup"),
            .init(minXP: 250, emoji: "🐕", title: "Good dog"),
            .init(minXP: 500, emoji: "🦮", title: "Very good dog"),
            .init(minXP: 900, emoji: "🐕‍🦺", title: "✨ Best in show"),
            .init(minXP: 1500, emoji: "🐩", title: "🎩 Distinguished dog"),
            .init(minXP: 2500, emoji: "🐺", title: "👑 Alpha wolf"),
        ]
        case .turtle: return [
            .init(minXP: 0, emoji: "🥚", title: "A patient egg"),
            .init(minXP: 20, emoji: "🐢", title: "Hatchling"),
            .init(minXP: 100, emoji: "🐢", title: "Tiny turtle"),
            .init(minXP: 250, emoji: "🐢", title: "Steady turtle"),
            .init(minXP: 500, emoji: "🐢", title: "Proper turtle"),
            .init(minXP: 900, emoji: "🐢", title: "✨ Wise turtle"),
            .init(minXP: 1500, emoji: "🐢", title: "🎩 Elder turtle"),
            .init(minXP: 2500, emoji: "🐉", title: "👑 Ancient dragon"),
        ]
        case .plant: return [
            .init(minXP: 0, emoji: "🌰", title: "A hopeful seed"),
            .init(minXP: 20, emoji: "🌱", title: "Sprout"),
            .init(minXP: 100, emoji: "🌿", title: "Seedling"),
            .init(minXP: 250, emoji: "🪴", title: "Potted & proud"),
            .init(minXP: 500, emoji: "🌳", title: "Young tree"),
            .init(minXP: 900, emoji: "🌸", title: "✨ In bloom"),
            .init(minXP: 1500, emoji: "🌺", title: "🎩 Show-stopper"),
            .init(minXP: 2500, emoji: "🌻", title: "👑 Garden royalty"),
        ]
        case .pixel: return [
            .init(minXP: 0, emoji: "🥚", title: "A glitchy egg"),
            .init(minXP: 20, emoji: "👾", title: "8-bit blob"),
            .init(minXP: 100, emoji: "👾", title: "16-bit critter"),
            .init(minXP: 250, emoji: "👾", title: "32-bit creature"),
            .init(minXP: 500, emoji: "👾", title: "64-bit being"),
            .init(minXP: 900, emoji: "👾", title: "✨ HD remaster"),
            .init(minXP: 1500, emoji: "👾", title: "🎩 Ray-traced"),
            .init(minXP: 2500, emoji: "👾", title: "👑 Final boss"),
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
    // Digimon rules: your real steps train the pet. Optional for
    // backward-compatible decoding of previously saved states.
    var lastTrained: String? = nil
    var trainedDays: Int? = 0
    // Pet XP drives evolution (feed +20, train +30). Optional for
    // back-compat; nil migrates from feeds/trainedDays on read.
    var xp: Int? = nil
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

    static func petXP(_ state: PetState) -> Int {
        state.xp ?? (state.feeds * 20 + (state.trainedDays ?? 0) * 30)
    }

    static func stage(for state: PetState) -> PetStage {
        let stages = state.character.stages
        let xp = petXP(state)
        var current = stages[0]
        for s in stages where xp >= s.minXP { current = s }
        return current
    }

    /// Progress toward the next evolution stage, 0...1 (1 at final stage).
    static func stageProgress(_ state: PetState) -> Double {
        let stages = state.character.stages
        let xp = petXP(state)
        guard let next = stages.first(where: { $0.minXP > xp }) else { return 1 }
        let currentMin = stage(for: state).minXP
        return Double(xp - currentMin) / Double(next.minXP - currentMin)
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
        state.xp = petXP(state) + 20
        XP.award("pet.feed", 20)
        return true
    }

    static func trainedToday(_ state: PetState) -> Bool {
        state.lastTrained == SharedStore.dayKey()
    }

    /// Called when the daily step goal is hit — the pet counts it as training.
    static func train() {
        var state = load()
        let today = SharedStore.dayKey()
        guard state.lastTrained != today else { return }
        state.lastTrained = today
        state.trainedDays = (state.trainedDays ?? 0) + 1
        state.xp = petXP(state) + 30
        save(state)
        XP.award("pet.train", 30)
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
