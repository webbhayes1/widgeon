import WidgetKit
import SwiftUI

// MARK: - New You at Midnight (live countdown to the daily reset)

/// Hourly entries keep the day-elapsed fraction fresh; the countdown text and
/// progress rings themselves tick live via timerInterval APIs.
struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry { DayEntry(date: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(DayEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let now = Date()
        let midnight = SharedStore.nextMidnight()
        var dates = [now]
        // Top-of-hour entries plus the 6:30 palette flips.
        if let nextHour = Calendar.current.nextDate(
            after: now, matching: DateComponents(minute: 0), matchingPolicy: .nextTime
        ) {
            var d = nextHour
            while d < midnight {
                dates.append(d)
                d = d.addingTimeInterval(3600)
            }
        }
        var flip = Theme.nextFlip(after: now)
        while flip < midnight {
            dates.append(flip)
            flip = Theme.nextFlip(after: flip)
        }
        completion(Timeline(
            entries: dates.sorted().map(DayEntry.init),
            policy: .after(midnight)
        ))
    }
}

struct CountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "countdown", provider: CountdownProvider()) { entry in
            CountdownWidgetView(date: entry.date)
                .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("New You at Midnight")
        .description("A live countdown to the daily reset — everything starts fresh at 12:00.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}
