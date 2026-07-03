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
        let timeline = Timeline(
            entries: [DayEntry(date: Date())],
            policy: .after(SharedStore.nextMidnight())
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
