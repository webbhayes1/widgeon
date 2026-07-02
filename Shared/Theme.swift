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

enum Theme {
    static let bg = Color(hex: 0x0B0B12)
    static let gold = Color(hex: 0xC8B57E)
    static let ember = Color(hex: 0xFF6B35)
    static let teal = Color(hex: 0x7FD4C1)
    static let green = Color(hex: 0x5CFF8F)
    static let petGreen = Color(hex: 0x8EE6A5)
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
