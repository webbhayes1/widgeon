import Foundation

struct Achievement: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let detail: String
    /// Whether the current state satisfies this achievement. Unlocks are
    /// persisted, so a broken streak never re-locks an earned badge.
    let earned: (PetState) -> Bool
}

enum Achievements {
    private static let key = "achievements.unlocked"

    static let all: [Achievement] = [
        // Feeding
        .init(id: "feed.1", emoji: "🍞", title: "First bite",
              detail: "Feed your pet for the first time") { $0.feeds >= 1 },
        .init(id: "feed.7", emoji: "🥐", title: "Regular",
              detail: "Feed your pet 7 times") { $0.feeds >= 7 },
        .init(id: "feed.30", emoji: "🥖", title: "Devoted",
              detail: "Feed your pet 30 times") { $0.feeds >= 30 },
        .init(id: "feed.100", emoji: "🎂", title: "Centurion",
              detail: "Feed your pet 100 times") { $0.feeds >= 100 },
        .init(id: "feed.365", emoji: "🏵️", title: "A full year",
              detail: "Feed your pet 365 times") { $0.feeds >= 365 },
        // Streaks (best-ever, so a broken streak keeps the badge)
        .init(id: "streak.3", emoji: "🔥", title: "Warming up",
              detail: "Reach a 3-day feed streak") { $0.best >= 3 },
        .init(id: "streak.7", emoji: "📅", title: "One week strong",
              detail: "Reach a 7-day feed streak") { $0.best >= 7 },
        .init(id: "streak.30", emoji: "💪", title: "Unbreakable",
              detail: "Reach a 30-day feed streak") { $0.best >= 30 },
        .init(id: "streak.100", emoji: "💎", title: "Legendary streak",
              detail: "Reach a 100-day feed streak") { $0.best >= 100 },
        // Training (real steps)
        .init(id: "train.1", emoji: "👟", title: "First workout",
              detail: "Hit your step goal once") { ($0.trainedDays ?? 0) >= 1 },
        .init(id: "train.10", emoji: "🏃", title: "In the habit",
              detail: "Hit your step goal 10 times") { ($0.trainedDays ?? 0) >= 10 },
        .init(id: "train.50", emoji: "🏅", title: "Iron legs",
              detail: "Hit your step goal 50 times") { ($0.trainedDays ?? 0) >= 50 },
        // Evolution
        .init(id: "stage.4", emoji: "🌟", title: "All grown up",
              detail: "Evolve your pet to its adult form") { Pet.stageIndex($0) >= 4 },
        .init(id: "stage.6", emoji: "🎩", title: "Distinguished",
              detail: "Evolve your pet to its top-hat form") { Pet.stageIndex($0) >= 6 },
        .init(id: "stage.7", emoji: "👑", title: "Royalty",
              detail: "Reach the final crowned form") { Pet.stageIndex($0) >= 7 },
        // Life XP
        .init(id: "level.5", emoji: "⭐", title: "Level 5",
              detail: "Reach life level 5") { _ in XP.level >= 5 },
        .init(id: "level.10", emoji: "🌠", title: "Level 10",
              detail: "Reach life level 10") { _ in XP.level >= 10 },
        .init(id: "level.20", emoji: "🚀", title: "Level 20",
              detail: "Reach life level 20") { _ in XP.level >= 20 },
    ]

    /// Achievement id → dayKey it was unlocked.
    static func unlocked() -> [String: String] {
        SharedStore.defaults.dictionary(forKey: key) as? [String: String] ?? [:]
    }

    /// Persists any newly earned achievements and returns them (in `all` order).
    @discardableResult
    static func check(_ pet: PetState) -> [Achievement] {
        var dates = unlocked()
        var fresh: [Achievement] = []
        for a in all where dates[a.id] == nil && a.earned(pet) {
            dates[a.id] = SharedStore.dayKey()
            fresh.append(a)
        }
        if !fresh.isEmpty { SharedStore.defaults.set(dates, forKey: key) }
        return fresh
    }
}
