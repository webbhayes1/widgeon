import WidgetKit
import SwiftUI

/// The countdown widget's content, shared so the app can render it too
/// (debug preview harness — the widget gallery can't be scripted on the sim).
struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let date: Date

    var body: some View {
        let p = Theme.palette(for: date)
        let midnight = SharedStore.nextMidnight(after: date)
        let dayStart = Calendar.current.startOfDay(for: date)

        switch family {
        case .accessoryInline:
            (Text("🌙 New you in ")
                + Text(timerInterval: date...midnight, countsDown: true))

        case .accessoryCircular:
            ProgressView(timerInterval: dayStart...midnight, countsDown: true) {
                Text("🌙")
            } currentValueLabel: {
                Text(timerInterval: date...midnight, countsDown: true,
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
                Text(timerInterval: date...midnight, countsDown: true)
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
                Text(timerInterval: date...midnight, countsDown: true)
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
