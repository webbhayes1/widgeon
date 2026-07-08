import SwiftUI

/// The living meadow from the design handoff: a pixel-art scene whose sky,
/// sun/moon, stars, and fireflies track the real time of day. Ported from the
/// handoff HTML's `renderLive` canvas routine (keyframes in `this._KF`).
enum Meadow {

    // MARK: Sky keyframes (hour → colors + star/firefly intensity)

    struct RGB {
        var r, g, b: Double
        init(_ hex: UInt32) {
            r = Double((hex >> 16) & 0xFF)
            g = Double((hex >> 8) & 0xFF)
            b = Double(hex & 0xFF)
        }
        init(r: Double, g: Double, b: Double) { self.r = r; self.g = g; self.b = b }
        func mixed(with o: RGB, _ t: Double) -> RGB {
            RGB(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t)
        }
        var color: Color { Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255) }
        func color(alpha: Double) -> Color {
            Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: alpha)
        }
        /// Relative luminance, 0…1.
        var luminance: Double { (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255 }
    }

    struct Keyframe {
        let t: Double
        let top, mid, hor, hf, hn, grass, dirt: RGB
        let star, fire: Double
    }

    struct Sample {
        let top, mid, hor, hf, hn, grass, dirt: RGB
        let star, fire: Double
        /// 0 = full night, 1 = full day (drives plant/flower tinting).
        var day: Double { max(0, 1 - star) }
    }

    static let keyframes: [Keyframe] = [
        Keyframe(t: 0, top: RGB(0x0A0C24), mid: RGB(0x141A40), hor: RGB(0x2A2A56),
                 hf: RGB(0x232A52), hn: RGB(0x171C3A), grass: RGB(0x212C4C), dirt: RGB(0x0F1228),
                 star: 1, fire: 1),
        Keyframe(t: 5.0, top: RGB(0x26356E), mid: RGB(0x7A5E92), hor: RGB(0xF0A66A),
                 hf: RGB(0x6A5E86), hn: RGB(0x463E5E), grass: RGB(0x5C5A6A), dirt: RGB(0x3C3446),
                 star: 0.35, fire: 0.35),
        Keyframe(t: 7.5, top: RGB(0x8FC8EA), mid: RGB(0xBFE2EC), hor: RGB(0xF1F0D6),
                 hf: RGB(0xB7E3C4), hn: RGB(0x95D6A6), grass: RGB(0x84D397), dirt: RGB(0xD8C79A),
                 star: 0, fire: 0),
        Keyframe(t: 13, top: RGB(0x79BEEE), mid: RGB(0xA9DCEE), hor: RGB(0xEAF4D6),
                 hf: RGB(0xB7E6C4), hn: RGB(0x95D6A6), grass: RGB(0x84D397), dirt: RGB(0xD8C79A),
                 star: 0, fire: 0),
        Keyframe(t: 17.5, top: RGB(0x4A5A9A), mid: RGB(0xB0688E), hor: RGB(0xFFB055),
                 hf: RGB(0x6E5E84), hn: RGB(0x463E5C), grass: RGB(0x54566A), dirt: RGB(0x40384A),
                 star: 0.15, fire: 0.45),
        Keyframe(t: 20, top: RGB(0x12163A), mid: RGB(0x2A2656), hor: RGB(0x5A3E6E),
                 hf: RGB(0x2E3358), hn: RGB(0x1B2040), grass: RGB(0x243052), dirt: RGB(0x141636),
                 star: 0.7, fire: 0.9),
        Keyframe(t: 24, top: RGB(0x0A0C24), mid: RGB(0x141A40), hor: RGB(0x2A2A56),
                 hf: RGB(0x232A52), hn: RGB(0x171C3A), grass: RGB(0x212C4C), dirt: RGB(0x0F1228),
                 star: 1, fire: 1),
    ]

    static func sample(at tod: Double) -> Sample {
        let t = ((tod.truncatingRemainder(dividingBy: 24)) + 24)
            .truncatingRemainder(dividingBy: 24)
        var i = 0
        while i < keyframes.count - 1, !(t >= keyframes[i].t && t < keyframes[i + 1].t) { i += 1 }
        let a = keyframes[i]
        let b = i + 1 < keyframes.count ? keyframes[i + 1] : a
        let u = b.t == a.t ? 0 : (t - a.t) / (b.t - a.t)
        return Sample(
            top: a.top.mixed(with: b.top, u), mid: a.mid.mixed(with: b.mid, u),
            hor: a.hor.mixed(with: b.hor, u), hf: a.hf.mixed(with: b.hf, u),
            hn: a.hn.mixed(with: b.hn, u), grass: a.grass.mixed(with: b.grass, u),
            dirt: a.dirt.mixed(with: b.dirt, u),
            star: a.star + (b.star - a.star) * u, fire: a.fire + (b.fire - a.fire) * u
        )
    }

    /// Fractional hour of day (e.g. 13.5 for 1:30 PM) in the local calendar.
    static func hourOfDay(_ date: Date = Date()) -> Double {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60 + Double(c.second ?? 0) / 3600
    }

    /// Screenshot/preview override (e.g. SIMCTL_CHILD_WIDGEON_TOD=20.5).
    static let envTod: Double? =
        ProcessInfo.processInfo.environment["WIDGEON_TOD"].flatMap(Double.init)

    /// The hour the scene should show: env override, else the clock. Anything
    /// styled to match the meadow (ink, chips) must use this same source.
    static func effectiveTod(_ date: Date = Date()) -> Double {
        envTod ?? hourOfDay(date)
    }

    /// True when the sky is bright enough that dark ink reads better than cream.
    static func skyIsLight(at tod: Double = effectiveTod()) -> Bool {
        let s = sample(at: tod)
        return s.top.mixed(with: s.mid, 0.5).luminance > 0.5
    }

    // MARK: Scene geometry (deterministic per index, animated by `ms`)

    private static let stars: [(x: Double, y: Double, s: Double, gold: Bool)] = (0..<70).map { i in
        let fi = Double(i)
        return ((fi * 0.1371 + 0.02).truncatingRemainder(dividingBy: 1),
                ((fi * fi * 0.191).truncatingRemainder(dividingBy: 1)) * 0.82,
                (fi * 0.37).truncatingRemainder(dividingBy: 1),
                i % 9 == 0)
    }

    /// (fractional x, plant type) — types: 0/1 flowers, 2 grass tuft.
    private static let scatter: [(Double, Int)] = [
        (0.05, 2), (0.1, 0), (0.16, 2), (0.22, 1), (0.3, 2), (0.37, 0), (0.46, 2),
        (0.54, 1), (0.62, 2), (0.69, 0), (0.76, 2), (0.85, 1), (0.93, 2),
    ]

    /// (fractional x, height above ground in cells)
    private static let fireflies: [(Double, Double)] = [
        (0.14, 6), (0.26, 10), (0.4, 5), (0.55, 12), (0.68, 7), (0.82, 9), (0.9, 5),
    ]

    /// Y position (points) of the grass line for a canvas of `size` — where
    /// sprites should stand. Mirrors the grid math in `draw`.
    static func groundY(in size: CGSize) -> CGFloat {
        let px = max(6, (size.width / 44).rounded(.down))
        let rows = Int((size.height / px).rounded(.up))
        let groundTop = rows - max(4, Int((Double(rows) * 0.24).rounded()))
        return CGFloat(groundTop) * px
    }

    // MARK: Renderer

    /// Draws the full meadow into a SwiftUI Canvas. `tod` is the fractional
    /// hour; `ms` is a monotonic millisecond clock driving twinkle/sway/pulse.
    static func draw(in ctx: GraphicsContext, size: CGSize, tod: Double, ms: Double) {
        let px = max(6, (size.width / 44).rounded(.down))
        let cols = Int((size.width / px).rounded(.up))
        let rows = Int((size.height / px).rounded(.up))
        guard cols > 4, rows > 8 else { return }
        let S = sample(at: tod)
        let groundTop = rows - max(4, Int((Double(rows) * 0.24).rounded()))
        let gt = Double(groundTop)

        func rect(_ x: Int, _ y: Int, _ c: Color, w: Int = 1, h: Int = 1) {
            ctx.fill(
                Path(CGRect(x: CGFloat(x) * px, y: CGFloat(y) * px,
                            width: CGFloat(w) * px, height: CGFloat(h) * px)),
                with: .color(c)
            )
        }

        // Sky: vertical gradient top → mid → horizon, one row at a time.
        for y in 0..<groundTop {
            let f = Double(y) / gt
            let c = f < 0.5 ? S.top.mixed(with: S.mid, f / 0.5)
                            : S.mid.mixed(with: S.hor, (f - 0.5) / 0.5)
            ctx.fill(
                Path(CGRect(x: 0, y: CGFloat(y) * px, width: size.width, height: px + 1)),
                with: .color(c.color)
            )
        }

        // Stars, twinkling.
        if S.star > 0.02 {
            for st in stars {
                let x = Int((st.x * Double(cols)).rounded())
                let y = Int((st.y * gt).rounded())
                let tw = 0.35 + 0.65 * (0.5 + 0.5 * sin(ms * 0.003 + st.s * 9))
                let a = S.star * tw
                let base = st.gold ? RGB(0xFFDC82) : RGB(0xFFFFFF)
                rect(x, y, base.color(alpha: a))
            }
        }

        // Sun and moon travel the same arc across the sky.
        func arc(_ p: Double) -> (Double, Double) {
            (Double(cols) * (0.1 + 0.8 * p), gt - sin(.pi * p) * (gt * 0.8) - 1)
        }

        // Celestial radius keys off the smaller axis: on tall full-screen
        // canvases the handoff's rows-based radius overwhelms the scene.
        let celestial = Double(min(cols, rows))

        let sp = (tod - 5.5) / 13
        if sp >= 0, sp <= 1 {
            let P = arc(sp)
            let r = max(2, Int((celestial * 0.12).rounded()))
            let cx = Int(P.0.rounded()), cy = Int(P.1.rounded())
            var a = 0.0
            while a < 360 { // halo ring
                rect(Int((Double(cx) + cos(a * .pi / 180) * Double(r + 1)).rounded()),
                     Int((Double(cy) + sin(a * .pi / 180) * Double(r + 1)).rounded()),
                     RGB(0xFFE08A).color(alpha: 0.28))
                a += 12
            }
            for y in -r...r {
                for x in -r...r where x * x + y * y <= r * r {
                    rect(cx + x, cy + y, RGB(0xFFE79A).color)
                }
            }
        }

        let mt = tod < 5.5 ? tod + 24 : tod
        let mp = (mt - 18.5) / 11
        if mp >= 0, mp <= 1 {
            let P = arc(mp)
            let r = max(2, Int((celestial * 0.11).rounded()))
            let cx = Int(P.0.rounded()), cy = Int(P.1.rounded())
            for y in -r...r {
                for x in -r...r where x * x + y * y <= r * r {
                    rect(cx + x, cy + y, RGB(0xFFF3CE).color)
                }
            }
            // Crescent: punch an offset disc back out in sky color — but only
            // inside the moon itself, or the cut shows as a box on the sky.
            // Sample the gradient at the moon's own row so the cut blends in.
            let off = Int((Double(r) * 0.5).rounded())
            let r2 = Double(r) * 0.85
            let mf = min(1, max(0, Double(cy) / gt))
            let cut = (mf < 0.5 ? S.top.mixed(with: S.mid, mf / 0.5)
                                : S.mid.mixed(with: S.hor, (mf - 0.5) / 0.5)).color
            for y in -r...r {
                for x in -r...r where x * x + y * y <= r * r {
                    let dx = Double(x + off)
                    if dx * dx + Double(y * y) <= r2 * r2 { rect(cx + x, cy + y, cut) }
                }
            }
        }

        // Rolling hills, far then near. The height formulas can dip below zero
        // (harmless no-op in the JS original; must clamp for Swift ranges).
        for x in 0..<cols {
            let h = max(0, Int((3 + 3 * sin(Double(x) / 11) + 1.5 * sin(Double(x) / 4)).rounded()))
            for y in max(0, groundTop - h)..<groundTop { rect(x, y, S.hf.color) }
        }
        for x in 0..<cols {
            let h = max(0, Int((2 + 2.5 * sin(Double(x) / 8 + 1.7)).rounded()))
            for y in max(0, groundTop - h)..<groundTop { rect(x, y, S.hn.color) }
        }

        // Grass strip + dirt.
        ctx.fill(Path(CGRect(x: 0, y: gt * px, width: size.width, height: 2 * px)),
                 with: .color(S.grass.color))
        ctx.fill(Path(CGRect(x: 0, y: (gt + 2) * px, width: size.width,
                             height: max(0, size.height - (gt + 2) * px))),
                 with: .color(S.dirt.color))

        // Plants sway; their colors dim toward navy at night.
        let day = S.day
        let stem = RGB(0x1E2E48).mixed(with: RGB(0x4FB06E), day).color
        let fA = RGB(0x242A44).mixed(with: RGB(0xFFFFFF), day).color
        let fB = RGB(0x242A44).mixed(with: RGB(0xFFF3C4), day).color
        let ctr = RGB(0x3A3355).mixed(with: RGB(0xFFC85C), day).color
        let blade = RGB(0x233052).mixed(with: RGB(0x57BC72), day).color

        for (fx, type) in scatter {
            let x = Int((Double(cols) * fx).rounded())
            let gy = groundTop
            let sw = Int(sin(ms * 0.0016 + Double(x) * 0.5).rounded())
            switch type {
            case 0:
                rect(x, gy - 1, stem); rect(x, gy - 2, stem)
                rect(x + sw - 1, gy - 3, fA); rect(x + sw + 1, gy - 3, fA)
                rect(x + sw, gy - 4, fA); rect(x + sw, gy - 3, ctr)
            case 1:
                rect(x, gy - 1, stem); rect(x, gy - 2, stem)
                rect(x + sw - 1, gy - 3, fB); rect(x + sw + 1, gy - 3, fB)
                rect(x + sw, gy - 4, fB); rect(x + sw, gy - 3, ctr)
            default:
                rect(x - 1, gy - 1, blade); rect(x, gy - 1, blade)
                rect(x + 1, gy - 1, blade); rect(x + sw, gy - 2, blade)
            }
        }

        // Fireflies drift and pulse after dusk.
        if S.fire > 0.05 {
            for (i, f) in fireflies.enumerated() {
                let fi = Double(i)
                let bx = Int((Double(cols) * f.0 + sin(ms * 0.0007 + fi) * 2).rounded())
                let by = Int((gt - f.1 + cos(ms * 0.0009 + fi * 1.7) * 2).rounded())
                let pulse = 0.4 + 0.6 * (0.5 + 0.5 * sin(ms * 0.004 + fi * 2))
                let a = S.fire * pulse
                rect(bx, by, RGB(0xFFE28A).color(alpha: a))
                let g = RGB(0xFFD26E).color(alpha: a * 0.3)
                rect(bx - 1, by, g); rect(bx + 1, by, g); rect(bx, by - 1, g)
            }
        }
    }
}

/// Live meadow background: redraws ~8×/s so stars twinkle, plants sway,
/// and fireflies drift, while the sky tracks the real clock.
struct MeadowView: View {
    /// Fixed hour for previews (screenshots use WIDGEON_TOD instead).
    var todOverride: Double? = nil

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 8.0)) { tl in
            Canvas(rendersAsynchronously: true) { ctx, size in
                Meadow.draw(
                    in: ctx, size: size,
                    tod: todOverride ?? Meadow.effectiveTod(tl.date),
                    ms: tl.date.timeIntervalSinceReferenceDate * 1000
                )
            }
        }
        .accessibilityHidden(true)
    }
}
