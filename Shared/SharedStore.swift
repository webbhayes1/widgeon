import Foundation

enum SharedStore {
    static let appGroup = "group.com.webbhayes.widgeon"

    /// App-group defaults shared between the app and widgets.
    /// Falls back to standard defaults when the group isn't provisioned yet
    /// (e.g. building before signing is configured).
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(_ date: Date = Date()) -> String {
        keyFormatter.string(from: date)
    }

    static func nextMidnight(after date: Date = Date()) -> Date {
        let cal = Calendar.current
        return cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: date)!)
    }
}
