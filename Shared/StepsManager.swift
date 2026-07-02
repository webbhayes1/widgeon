import Foundation
import HealthKit
import WidgetKit

/// Fetches today's step count from HealthKit and caches it in the shared
/// store so widgets can render it. The app refreshes on launch/foreground;
/// widgets read the cache.
final class StepsManager: ObservableObject {
    static let shared = StepsManager()

    private let store = HKHealthStore()

    @Published var todaySteps: Int = StepsManager.cachedSteps()
    @Published var authorized = false

    static var goal: Int {
        get {
            let g = SharedStore.defaults.integer(forKey: "steps.goal")
            return g == 0 ? 10_000 : g
        }
        set { SharedStore.defaults.set(newValue, forKey: "steps.goal") }
    }

    static func cachedSteps() -> Int {
        guard SharedStore.defaults.string(forKey: "steps.date") == SharedStore.dayKey() else { return 0 }
        return SharedStore.defaults.integer(forKey: "steps.today")
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let stepType = HKQuantityType(.stepCount)
        do {
            try await store.requestAuthorization(toShare: [], read: [stepType])
            await MainActor.run { self.authorized = true }
            await refresh()
        } catch {
            // User declined or Health unavailable; widget will show 0.
        }
    }

    func refresh() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let stepType = HKQuantityType(.stepCount)
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())

        let steps: Int = await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(value))
            }
            store.execute(query)
        }

        SharedStore.defaults.set(steps, forKey: "steps.today")
        SharedStore.defaults.set(SharedStore.dayKey(), forKey: "steps.date")
        await MainActor.run { self.todaySteps = steps }
        WidgetCenter.shared.reloadTimelines(ofKind: "steps")

        // Digimon rules: hitting the step goal trains the pet and earns XP.
        if steps >= StepsManager.goal {
            XP.award("steps.goal", 30)
            Pet.train()
            WidgetCenter.shared.reloadTimelines(ofKind: "pet")
        }
    }
}
