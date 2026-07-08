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
            CountdownWidgetView(entry: entry)
                .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("New You at Midnight")
        .description("A live countdown to the daily reset — everything starts fresh at 12:00.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    var body: some View {
        let p = Theme.palette(for: entry.date)
        let midnight = SharedStore.nextMidnight(after: entry.date)
        let dayStart = Calendar.current.startOfDay(for: entry.date)

        switch family {
        case .accessoryInline:
            (Text("🌙 New you in ")
                + Text(timerInterval: entry.date...midnight, countsDown: true))

        case .accessoryCircular:
            ProgressView(timerInterval: dayStart...midnight, countsDown: true) {
                Text("🌙")
            } currentValueLabel: {
                Text(timerInterval: entry.date...midnight, countsDown: true,
                     showsHours: true)
                    .font(.system(size: 11, weight: .heavy))
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.center)
            }
            .progressViewStyle(.circular)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                Text("NEW YOU IN")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.4)
                    .opacity(0.75)
                Text(timerInterval: entry.date...midnight, countsDown: true)
                    .font(.system(size: 20, weight: .heavy))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                ProgressView(timerInterval: dayStart...midnight, countsDown: true)
                    .progressViewStyle(.linear)
                    .labelsHidden()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        default: // systemSmall
            VStack(alignment: .leading, spacing: 6) {
                WidgetHeader(text: "🌙 NEW YOU IN", color: p.gold)
                Spacer(minLength: 0)
                Text(timerInterval: entry.date...midnight, countsDown: true)
                    .font(Theme.serif(34))
                    .monospacedDigit()
                    .foregroundStyle(p.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                ProgressView(timerInterval: dayStart...midnight, countsDown: true)
                    .progressViewStyle(.linear)
                    .tint(p.gold)
                    .labelsHidden()
                Text("Everything resets at midnight")
                    .font(.system(size: 11))
                    .foregroundStyle(p.muted)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
