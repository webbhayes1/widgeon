import Foundation

/// Deterministic date-based content selection, ported from the Scriptable
/// prototypes. The prime step scrambles order so consecutive days aren't
/// list neighbors; primes are coprime with each bank size, guaranteeing a
/// full cycle with no repeats.
enum DailyPick {
    private static let reference = DateComponents(
        calendar: Calendar(identifier: .gregorian),
        year: 2001, month: 1, day: 1
    ).date!

    static func dayNumber(_ date: Date = Date()) -> Int {
        let cal = Calendar.current
        return cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: reference),
            to: cal.startOfDay(for: date)
        ).day ?? 0
    }

    static func index(count: Int, prime: Int, date: Date = Date()) -> Int {
        guard count > 0 else { return 0 }
        return (dayNumber(date) * prime) % count
    }

    static func vocab(for date: Date = Date()) -> VocabEntry {
        ContentBank.vocab[index(count: ContentBank.vocab.count, prime: 131, date: date)]
    }

    static func roast(for date: Date = Date()) -> String {
        ContentBank.roasts[index(count: ContentBank.roasts.count, prime: 37, date: date)]
    }

    static func affirmation(for date: Date = Date()) -> String {
        ContentBank.affirmations[index(count: ContentBank.affirmations.count, prime: 53, date: date)]
    }

    static func fortune(for date: Date = Date()) -> String {
        ContentBank.fortunes[index(count: ContentBank.fortunes.count, prime: 41, date: date)]
    }
}
