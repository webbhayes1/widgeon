import AppIntents
import WidgetKit

/// Tap-to-feed, directly in the widget — no app launch. This is the upgrade
/// Scriptable couldn't do.
struct FeedPetIntent: AppIntent {
    static var title: LocalizedStringResource = "Feed Pet"
    static var description = IntentDescription("Feeds your Widgeon pet for today.")

    func perform() async throws -> some IntentResult {
        var state = Pet.load()
        Pet.feed(&state)
        Pet.save(state)
        WidgetCenter.shared.reloadTimelines(ofKind: "pet")
        return .result()
    }
}

/// Tap-to-add-one on the drink counter, directly in the widget.
struct AddDrinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Drink"
    static var description = IntentDescription("Adds one to today's drink count.")

    func perform() async throws -> some IntentResult {
        Drink.increment()
        WidgetCenter.shared.reloadTimelines(ofKind: "drink")
        return .result()
    }
}
