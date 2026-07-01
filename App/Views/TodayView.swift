import SwiftUI
import WidgetKit

struct TodayView: View {
    @ObservedObject private var steps = StepsManager.shared

    var body: some View {
        NavigationStack {
            List {
                let word = DailyPick.vocab()

                Section("Word of the day") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(word.w)
                                .font(.title2.bold())
                            Text(word.p)
                                .font(.subheadline.italic())
                                .foregroundStyle(.secondary)
                        }
                        Text(word.d)
                        Text("“\(word.e)”")
                            .font(.callout.italic())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Daily roast") {
                    Text(DailyPick.roast())
                        .font(.body.weight(.medium))
                }

                Section("Affirmation") {
                    Text(DailyPick.affirmation())
                        .font(.body.weight(.medium))
                }

                Section("Steps") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(steps.todaySteps.formatted())
                                .font(.title.bold())
                            Text("of \(StepsManager.goal.formatted())")
                                .foregroundStyle(.secondary)
                            Spacer()
                            if steps.todaySteps >= StepsManager.goal {
                                Text("🏆")
                            }
                        }
                        ProgressView(value: min(1, Double(steps.todaySteps) / Double(StepsManager.goal)))
                            .tint(.green)
                        Button("Refresh from Health") {
                            Task { await steps.requestAuthorization() }
                        }
                        .font(.callout)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Today")
            .task {
                await steps.requestAuthorization()
            }
        }
    }
}
