import WidgetKit
import SwiftUI

// MARK: - Daily Fortune (one per midnight, 8-ball energy)

struct FortuneWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "fortune", provider: DailyProvider()) { entry in
            LineWidgetView(
                entry: entry,
                header: "🎱 DAILY FORTUNE",
                line: { DailyPick.fortune(for: $0) }
            )
            .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("Daily Fortune")
        .description("One fortune per midnight. The 8-ball has spoken.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Daily Wisdom (scripture or philosophy, user's choice, reverent & minimal)

struct WisdomWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "wisdom", provider: DailyProvider()) { entry in
            WisdomWidgetView(entry: entry)
                .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("Daily Wisdom")
        .description("A daily verse or philosophy passage — pick your tradition in the app.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct WisdomWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    var body: some View {
        let p = Theme.palette(for: entry.date)
        let wisdom = Wisdom.today(for: entry.date)

        switch family {
        case .accessoryInline:
            Text("\(wisdom.t) — \(wisdom.c)")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(wisdom.t)
                    .font(Theme.serif(14))
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                Text(wisdom.c.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .kerning(0.8)
                    .opacity(0.65)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 8) {
                WidgetHeader(text: "✦ DAILY WISDOM", color: p.gold)
                Spacer(minLength: 0)
                Text(wisdom.t)
                    .font(Theme.serif(family == .systemSmall ? 17 : 20))
                    .foregroundStyle(p.ink)
                    .lineLimit(family == .systemSmall ? 6 : 4)
                    .minimumScaleFactor(0.7)
                Text(wisdom.c.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(p.gold.opacity(0.9))
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Life XP (every ritual earns XP; your level lives on the lock screen)

struct XPWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "xp", provider: FrequentProvider()) { entry in
            XPWidgetView(entry: entry)
                .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("Life XP")
        .description("Feed the pet, hit your steps, finish your water — level up your life.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct XPWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    var body: some View {
        let p = Theme.palette(for: entry.date)
        let level = XP.level
        let progress = XP.levelProgress

        switch family {
        case .accessoryInline:
            Text("⭐ Level \(level) · \(XP.toNextLevel) XP to next")
        case .accessoryCircular:
            Gauge(value: progress) {
                Text("LVL")
            } currentValueLabel: {
                Text("\(level)").font(.system(size: 16, weight: .heavy))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                Text("⭐ LEVEL \(level)")
                    .font(.system(size: 13, weight: .heavy))
                CapsuleBar(pct: progress, height: 7)
                Text("\(XP.total.formatted()) XP · \(XP.toNextLevel.formatted()) to Level \(level + 1)")
                    .font(.system(size: 10))
                    .opacity(0.75)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 6) {
                WidgetHeader(text: "⭐ LIFE XP", color: p.gold)
                Spacer(minLength: 0)
                Text("LVL \(level)")
                    .font(Theme.serif(family == .systemSmall ? 40 : 52))
                    .foregroundStyle(p.ink)
                CapsuleBar(
                    pct: progress,
                    fill: p.gold,
                    track: p.ink.opacity(0.12),
                    height: family == .systemSmall ? 10 : 12
                )
                Text("\(XP.total.formatted()) XP · \(XP.toNextLevel.formatted()) to Level \(level + 1)")
                    .font(.system(size: family == .systemSmall ? 10 : 12))
                    .foregroundStyle(p.muted)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
