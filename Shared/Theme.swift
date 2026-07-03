import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Brand palette from the Widgeon design handoff. The whole UI flips
/// between night and day at 6:30 AM / 6:30 PM.
struct Palette {
    let isDay: Bool
    let base: Color        // screen background
    let baseTop: Color     // gradient top (day mode mint)
    let ink: Color         // primary text
    let muted: Color       // secondary text
    let soft: Color        // pale gold highlights
    let accent: Color      // gold (night) / spring green (day) for actions
    let gold: Color        // stays gold in both modes
    let cardBG: Color
    let cardBorder: Color
}

enum Theme {
    static let night = Palette(
        isDay: false,
        base: Color(hex: 0x0B0D24), baseTop: Color(hex: 0x0B0D24),
        ink: Color(hex: 0xFBF7EA), muted: Color(hex: 0x8C89B0),
        soft: Color(hex: 0xFFD877), accent: Color(hex: 0xFFC44D),
        gold: Color(hex: 0xFFC44D),
        cardBG: .white.opacity(0.06), cardBorder: .white.opacity(0.1)
    )

    static let day = Palette(
        isDay: true,
        base: Color(hex: 0xF3F8E6), baseTop: Color(hex: 0xE7F5EC),
        ink: Color(hex: 0x183A2A), muted: Color(hex: 0x5A7A67),
        soft: Color(hex: 0xFFC44D), accent: Color(hex: 0x22A868),
        gold: Color(hex: 0xD89A2B),
        cardBG: .white.opacity(0.62), cardBorder: .white.opacity(0.85)
    )

    static func palette(for date: Date = Date()) -> Palette {
        let cal = Calendar.current
        let t = Double(cal.component(.hour, from: date)) + Double(cal.component(.minute, from: date)) / 60
        return (t >= 6.5 && t < 18.5) ? day : night
    }

    /// The next 6:30 AM/PM day↔night boundary strictly after `date`.
    /// Widgets emit a timeline entry here so the palette flips on schedule.
    static func nextFlip(after date: Date = Date()) -> Date {
        let startOfDay = Calendar.current.startOfDay(for: date)
        // 6:30 today, 18:30 today, 6:30 tomorrow (30.5h).
        for hours in [6.5, 18.5, 30.5] {
            let candidate = startOfDay.addingTimeInterval(hours * 3600)
            if candidate > date { return candidate }
        }
        return startOfDay.addingTimeInterval(30.5 * 3600)
    }

    static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
        .custom(italic ? "InstrumentSerif-Italic" : "InstrumentSerif-Regular", size: size)
    }

    // Legacy tokens still referenced by widget views (migrating incrementally).
    static let bg = Color(hex: 0x0B0D24)
    static let gold = Color(hex: 0xFFC44D)
    static let ember = Color(hex: 0xFF6B35)
    static let teal = Color(hex: 0x7FD4C1)
    static let green = Color(hex: 0x5CFF8F)
    static let petGreen = Color(hex: 0xFFC44D)
    static let purple = Color(hex: 0x9B8CFF)
    static let blue = Color(hex: 0x5CC8FF)
}

/// The modern capsule progress bar used across the pack (app + widgets).
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

/// The brand day/night gradient used behind screens and home-screen widgets.
struct BrandBackground: View {
    var palette: Palette = Theme.palette()

    var body: some View {
        LinearGradient(
            colors: [palette.baseTop, palette.base],
            startPoint: .top, endPoint: .bottom
        )
    }
}
