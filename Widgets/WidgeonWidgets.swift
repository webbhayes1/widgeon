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
    }
}

// MARK: - Shared helpers

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// The modern capsule progress bar used across the pack.
struct CapsuleBar: View {
    let pct: Double
    var fill: Color = .white
    var track: Color = .white.opacity(0.2)
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(fill)
                    .frame(width: max(height, geo.size.width * min(1, max(0, pct))))
            }
        }
        .frame(height: height)
    }
}

struct WidgetHeader: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
    }
}

// MARK: - Simple day-based timeline shared by the static widgets

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
