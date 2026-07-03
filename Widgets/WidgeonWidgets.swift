import WidgetKit
import SwiftUI

@main
struct WidgeonWidgetBundle: WidgetBundle {
    var body: some Widget {
        VocabWidget()
        RoastWidget()
        AffirmationWidget()
        LifeProgressWidget()
        StepsWidget()
        DrinkWidget()
        PetWidget()
        FortuneWidget()
        XPWidget()
        WisdomWidget()
    }
}

// MARK: - Simple day-based timeline shared by the static widgets
// (Color/CapsuleBar/WidgetHeader helpers live in Shared/Theme.swift)

struct DayEntry: TimelineEntry {
    let date: Date
}

struct DailyProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry { DayEntry(date: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(DayEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        // Content is fixed for the day, but emit an entry at each 6:30 day/night
        // flip so the palette updates on schedule; refresh after midnight.
        let now = Date()
        let midnight = SharedStore.nextMidnight()
        var dates = [now]
        var flip = Theme.nextFlip(after: now)
        while flip < midnight {
            dates.append(flip)
            flip = Theme.nextFlip(after: flip)
        }
        let timeline = Timeline(
            entries: dates.map { DayEntry(date: $0) },
            policy: .after(midnight)
        )
        completion(timeline)
    }
}

/// Refreshes more often than daily, for stateful widgets (pet, drink, steps).
struct FrequentProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry { DayEntry(date: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(DayEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let timeline = Timeline(
            entries: [DayEntry(date: Date())],
            policy: .after(Date().addingTimeInterval(15 * 60))
        )
        completion(timeline)
    }
}
