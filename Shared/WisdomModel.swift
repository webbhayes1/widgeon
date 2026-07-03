import Foundation

struct WisdomEntry: Codable, Hashable {
    let t: String  // text
    let c: String  // citation
}

enum WisdomTradition: String, CaseIterable, Identifiable {
    case stoic, bible
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stoic: return "Stoic philosophy"
        case .bible: return "Bible (KJV)"
        }
    }

    var bank: [WisdomEntry] {
        switch self {
        case .stoic: return ContentBank.wisdomStoic
        case .bible: return ContentBank.wisdomBible
        }
    }
}

enum Wisdom {
    static var tradition: WisdomTradition {
        get {
            WisdomTradition(
                rawValue: SharedStore.defaults.string(forKey: "wisdom.tradition") ?? ""
            ) ?? .stoic
        }
        set { SharedStore.defaults.set(newValue.rawValue, forKey: "wisdom.tradition") }
    }

    static func today(for date: Date = Date()) -> WisdomEntry {
        let bank = tradition.bank
        return bank[DailyPick.index(count: bank.count, prime: 61, date: date)]
    }
}
