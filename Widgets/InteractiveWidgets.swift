import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Pet (interactive: tap the pet to feed, right in the widget)

struct PetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "pet", provider: FrequentProvider()) { entry in
            PetWidgetView(entry: entry)
                .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("Widge Pet")
        .description("A creature on your lock screen. Feed it daily, watch it evolve.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct PetWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    var body: some View {
        let p = Theme.palette(for: entry.date)
        let state = Pet.load()
        let stage = Pet.stage(for: state)
        let fed = Pet.fedToday(state)
        let mood = Pet.mood(state)
        let streakBadge = state.streak >= 2 && fed ? " 🔥\(state.streak)" : ""

        switch family {
        case .accessoryInline:
            Text("\(stage.emoji) \(state.name): \(mood)")
        case .accessoryCircular:
            Button(intent: FeedPetIntent()) {
                Text(fed || state.feeds == 0 ? stage.emoji : "🍞")
                    .font(.system(size: 26))
            }
            .buttonStyle(.plain)
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Button(intent: FeedPetIntent()) {
                    Text(stage.emoji).font(.system(size: 32))
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 0) {
                    Text(state.name.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                    Text(state.feeds > 0 ? "Day \(state.feeds) · \(stage.title)\(streakBadge)" : "Ready to hatch!")
                        .font(.system(size: 10))
                        .opacity(0.8)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(mood)
                        .font(.system(size: 10))
                        .opacity(0.7)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(spacing: 4) {
                Text(state.name.uppercased() + streakBadge)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(p.gold)
                Spacer(minLength: 0)
                Button(intent: FeedPetIntent()) {
                    PixelSpriteView(sprite: stage.sprite, accessibilityLabel: stage.title)
                        .frame(
                            width: family == .systemSmall ? 72 : 96,
                            height: family == .systemSmall ? 72 : 96
                        )
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
                Text(mood)
                    .font(.system(size: family == .systemSmall ? 11 : 14, weight: .medium))
                    .foregroundStyle(p.ink)
                    .lineLimit(1)
                Text(state.feeds > 0 ? "Day \(state.feeds) · \(stage.title)" : "Feed it daily. See what happens.")
                    .font(.system(size: family == .systemSmall ? 9 : 11))
                    .foregroundStyle(p.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Drink Counter (interactive: tap +1 right in the widget)

struct DrinkWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "drink", provider: FrequentProvider()) { entry in
            DrinkWidgetView(entry: entry)
                .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("Drink Counter")
        .description("Count water toward a goal — or count drinks against a limit on a night out.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct DrinkWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    /// Over-limit warning stays red regardless of palette (semantic).
    private let warn = Color(hex: 0xFF5C7A)

    var body: some View {
        let p = Theme.palette(for: entry.date)
        let state = Drink.load()
        let target = Drink.target
        let over = Drink.isLimit && state.count >= target
        let pct = Double(state.count) / Double(target)
        let accent: Color = over ? warn : p.gold

        switch family {
        case .accessoryInline:
            Text("\(Drink.emoji) \(Drink.label) \(state.count)/\(target)")
        case .accessoryCircular:
            Button(intent: AddDrinkIntent()) {
                VStack(spacing: 0) {
                    Text("\(state.count)")
                        .font(.system(size: 20, weight: .bold))
                    Text(Drink.isLimit ? "max \(target)" : "of \(target)")
                        .font(.system(size: 8))
                        .opacity(0.7)
                }
            }
            .buttonStyle(.plain)
        case .accessoryRectangular:
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(Drink.emoji) \(Drink.label.uppercased()) · \(state.count)/\(target)\(over ? " ⚠️" : "")")
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    CapsuleBar(pct: pct, height: 7)
                    Text(Drink.status(state))
                        .font(.system(size: 10))
                        .opacity(0.75)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Button(intent: AddDrinkIntent()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    WidgetHeader(
                        text: "\(Drink.emoji) \(Drink.label.uppercased())\(Drink.isLimit ? " · LIMIT \(target)" : "")",
                        color: accent
                    )
                    Spacer()
                    Button(intent: AddDrinkIntent()) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
                Text("\(state.count) / \(target)")
                    .font(Theme.serif(family == .systemSmall ? 38 : 50))
                    .foregroundStyle(over ? warn : p.ink)
                CapsuleBar(
                    pct: pct,
                    fill: accent,
                    track: p.ink.opacity(0.12),
                    height: family == .systemSmall ? 10 : 12
                )
                Text(Drink.status(state))
                    .font(.system(size: family == .systemSmall ? 10 : 12))
                    .foregroundStyle(p.muted)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Steps (HealthKit-backed progress ring/bar)

struct StepsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "steps", provider: FrequentProvider()) { entry in
            StepsWidgetView(entry: entry)
                .containerBackground(for: .widget) { BrandBackground(palette: Theme.palette(for: entry.date)) }
        }
        .configurationDisplayName("Step Tracker")
        .description("Today's steps against your goal, from Apple Health.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct StepsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    var body: some View {
        let p = Theme.palette(for: entry.date)
        let steps = StepsManager.cachedSteps()
        let goal = StepsManager.goal
        let pct = Double(steps) / Double(goal)
        let done = steps >= goal

        switch family {
        case .accessoryInline:
            Text("👟 \(steps.formatted()) / \(goal.formatted()) steps")
        case .accessoryCircular:
            Gauge(value: min(1, pct)) {
                Image(systemName: "figure.walk")
            } currentValueLabel: {
                Text(steps >= 1000 ? "\(steps / 1000)k" : "\(steps)")
                    .font(.system(size: 14, weight: .bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                Text("👟 \(steps.formatted()) steps\(done ? " ✓" : "")")
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                CapsuleBar(pct: pct, height: 7)
                Text(done ? "Goal crushed. Victory lap?" : "\((goal - steps).formatted()) to go · goal \(goal.formatted())")
                    .font(.system(size: 10))
                    .opacity(0.75)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 6) {
                WidgetHeader(text: "👟 STEPS", color: p.gold)
                Spacer(minLength: 0)
                Text(steps.formatted())
                    .font(Theme.serif(family == .systemSmall ? 38 : 50))
                    .foregroundStyle(p.ink)
                CapsuleBar(
                    pct: pct,
                    fill: p.gold,
                    track: p.ink.opacity(0.12),
                    height: family == .systemSmall ? 10 : 12
                )
                Text(done ? "Goal crushed. Victory lap? 🏆" : "\((goal - steps).formatted()) to go · goal \(goal.formatted())")
                    .font(.system(size: family == .systemSmall ? 10 : 12))
                    .foregroundStyle(p.muted)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
