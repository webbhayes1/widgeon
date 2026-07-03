import WidgetKit
import SwiftUI

// MARK: - Daily Vocab

struct VocabWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "vocab", provider: DailyProvider()) { entry in
            VocabWidgetView(entry: entry)
                .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("Daily Vocab")
        .description("A new word every midnight — smart, usable, never repeats for 500 days.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct VocabWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    var body: some View {
        let p = Theme.palette(for: entry.date)
        let word = DailyPick.vocab(for: entry.date)
        switch family {
        case .accessoryInline:
            Text("\(word.w) — \(word.d)")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(word.w)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("(\(word.p)) \(word.d)")
                    .font(.system(size: 11))
                    .lineLimit(2)
                    .opacity(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(text: "WORD OF THE DAY", color: p.gold)
                Spacer(minLength: 2)
                Text(word.w)
                    .font(Theme.serif(family == .systemSmall ? 24 : 30))
                    .foregroundStyle(p.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(word.p)
                    .font(Theme.serif(13, italic: true))
                    .foregroundStyle(p.muted)
                Text(word.d)
                    .font(.system(size: family == .systemSmall ? 12 : 14))
                    .foregroundStyle(p.ink)
                    .lineLimit(family == .systemSmall ? 3 : 2)
                if family != .systemSmall {
                    Text("“\(word.e)”")
                        .font(Theme.serif(13, italic: true))
                        .foregroundStyle(p.muted)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Daily Roast

struct RoastWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "roast", provider: DailyProvider()) { entry in
            LineWidgetView(
                entry: entry,
                header: "🔥 DAILY ROAST",
                line: { DailyPick.roast(for: $0) }
            )
            .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("Daily Roast")
        .description("Tough-love motivation, one line a day.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Daily Affirmation

struct AffirmationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "affirmation", provider: DailyProvider()) { entry in
            LineWidgetView(
                entry: entry,
                header: "🌤 TODAY'S AFFIRMATION",
                line: { DailyPick.affirmation(for: $0) }
            )
            .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("Daily Affirmation")
        .description("One first-person affirmation per day.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

/// Shared layout for one-line-a-day widgets (roast, affirmation).
struct LineWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry
    let header: String
    let line: (Date) -> String

    var body: some View {
        let p = Theme.palette(for: entry.date)
        let text = line(entry.date)
        switch family {
        case .accessoryInline:
            Text(text)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(header)
                    .font(.system(size: 9, weight: .semibold))
                    .opacity(0.7)
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 6) {
                WidgetHeader(text: header, color: p.gold)
                Spacer(minLength: 0)
                Text(text)
                    .font(.system(size: family == .systemSmall ? 14 : 18, weight: .bold))
                    .foregroundStyle(p.ink)
                    .lineLimit(family == .systemSmall ? 5 : 4)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Life Progress

struct LifeProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "life", provider: DailyProvider()) { entry in
            LifeProgressView(entry: entry)
                .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("Life Progress")
        .description("How much of the year — or your life — is already gone.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct LifeProgressView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    struct Data {
        let label: String
        let pct: Double
        let footer: String
    }

    private func compute() -> Data {
        let now = entry.date
        let cal = Calendar.current
        let birthdayTs = SharedStore.defaults.double(forKey: "life.birthday")
        let lifeMode = SharedStore.defaults.bool(forKey: "life.mode") && birthdayTs > 0

        if lifeMode {
            let birth = Date(timeIntervalSince1970: birthdayTs)
            let end = cal.date(byAdding: .year, value: 90, to: birth)!
            let pct = min(1, max(0, now.timeIntervalSince(birth) / end.timeIntervalSince(birth)))
            let weeksLeft = max(0, Int(end.timeIntervalSince(now) / (7 * 86400)))
            return Data(label: "LIFE", pct: pct, footer: "~\(weeksLeft.formatted()) weekends left. Make them count.")
        }
        let year = cal.component(.year, from: now)
        let start = cal.date(from: DateComponents(year: year))!
        let end = cal.date(from: DateComponents(year: year + 1))!
        let pct = now.timeIntervalSince(start) / end.timeIntervalSince(start)
        let daysLeft = Int(ceil(end.timeIntervalSince(now) / 86400))
        return Data(label: "\(year)", pct: pct, footer: "\(daysLeft) days left. Use them.")
    }

    var body: some View {
        let p = Theme.palette(for: entry.date)
        let data = compute()
        let pctText = String(format: "%.1f%%", data.pct * 100)

        switch family {
        case .accessoryInline:
            Text("\(data.label): \(pctText) gone")
        case .accessoryCircular:
            Gauge(value: data.pct) {
                Text(data.label)
            } currentValueLabel: {
                Text(pctText).font(.system(size: 12, weight: .bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                Text("\(data.label) · \(pctText) complete")
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                CapsuleBar(pct: data.pct, height: 7)
                Text(data.footer)
                    .font(.system(size: 10))
                    .opacity(0.75)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 6) {
                WidgetHeader(
                    text: data.label == "LIFE" ? "⏳ LIFE PROGRESS" : "⏳ YEAR PROGRESS",
                    color: p.gold
                )
                Spacer(minLength: 0)
                Text(pctText)
                    .font(Theme.serif(family == .systemSmall ? 40 : 52))
                    .foregroundStyle(p.ink)
                CapsuleBar(
                    pct: data.pct,
                    fill: p.gold,
                    track: p.ink.opacity(0.12),
                    height: family == .systemSmall ? 10 : 12
                )
                Text(data.footer)
                    .font(.system(size: family == .systemSmall ? 11 : 13))
                    .foregroundStyle(p.muted)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
