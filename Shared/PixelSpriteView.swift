import SwiftUI

/// Renders a Widgeon pixel sprite (a square grid of palette chars) crisply,
/// scaling whole pixels to fill the given size. Ported from the design handoff's
/// Canvas stamp routine: each non-transparent cell is a filled scale×scale rect.
struct PixelSpriteView: View {
    /// A sprite key from `PixelSprites.grids` (e.g. "duck", "egg", "catA").
    let sprite: String
    /// Optional accessibility label (the emoji/title the sprite stands in for).
    var accessibilityLabel: String? = nil

    var body: some View {
        Canvas(rendersAsynchronously: false) { ctx, size in
            guard let grid = PixelSprites.grids[sprite], !grid.isEmpty else { return }
            let rows = grid.count
            let cols = grid.map(\.count).max() ?? rows
            // Integer pixel size keeps edges sharp; center the grid in the box.
            let px = (min(size.width / CGFloat(cols), size.height / CGFloat(rows)))
                .rounded(.down)
            guard px >= 1 else { return }
            let gridW = px * CGFloat(cols)
            let gridH = px * CGFloat(rows)
            let ox = ((size.width - gridW) / 2).rounded(.down)
            let oy = ((size.height - gridH) / 2).rounded(.down)

            for (y, line) in grid.enumerated() {
                for (x, ch) in line.enumerated() {
                    guard let hex = PixelSprites.palette[ch],
                          let color = Color(hex: hex) else { continue }
                    let rect = CGRect(
                        x: ox + CGFloat(x) * px,
                        y: oy + CGFloat(y) * px,
                        width: px, height: px
                    )
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .accessibilityLabel(accessibilityLabel ?? sprite)
    }
}

extension Color {
    /// Parses a `#RRGGBB` hex string. Returns nil on malformed input.
    init?(hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}
