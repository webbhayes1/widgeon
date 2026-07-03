import SwiftUI
import WidgetKit

struct Card<Content: View>: View {
    let header: String
    let palette: Palette
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(header)
                .font(.system(size: 11, weight: .heavy))
                .kerning(1.5)
                .foregroundStyle(palette.gold)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(palette.cardBG))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(palette.cardBorder))
    }
}

struct TodayView: View {
    @ObservedObject private var steps = StepsManager.shared
    private let p = Theme.palette()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                vocabCard
                roastCard
                affirmationCard
                wisdomCard
                fortuneCard
                stepsCard
            }
            .padding(16)
        }
        .background(BrandBackground(palette: p).ignoresSafeArea())
        .task { await steps.requestAuthorization() }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .kerning(1.5)
                    .foregroundStyle(p.gold)
                Text("Today")
                    .font(Theme.serif(44))
                    .foregroundStyle(p.ink)
            }
            Spacer()
            VStack(spacing: 1) {
                Text("LVL \(XP.level)")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(p.gold)
                Text("\(XP.total.formatted()) XP")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(p.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(p.cardBG))
            .overlay(Capsule().strokeBorder(p.cardBorder))
        }
        .padding(.top, 8)
    }

    private var vocabCard: some View {
        let word = DailyPick.vocab()
        return Card(header: "WORD OF THE DAY", palette: p) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(word.w)
                    .font(Theme.serif(34))
                    .foregroundStyle(p.ink)
                Text(word.p)
                    .font(Theme.serif(16, italic: true))
                    .foregroundStyle(p.muted)
            }
            Text(word.d)
                .font(.system(size: 16))
                .foregroundStyle(p.ink.opacity(0.9))
            Text("“\(word.e)”")
                .font(Theme.serif(16, italic: true))
                .foregroundStyle(p.muted)
        }
    }

    private var roastCard: some View {
        Card(header: "🔥 DAILY ROAST", palette: p) {
            Text(DailyPick.roast())
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(p.ink)
        }
    }

    private var affirmationCard: some View {
        Card(header: "🌤 AFFIRMATION", palette: p) {
            Text(DailyPick.affirmation())
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(p.ink)
        }
    }

    private var wisdomCard: some View {
        let wisdom = Wisdom.today()
        return Card(header: "✦ DAILY WISDOM", palette: p) {
            Text(wisdom.t)
                .font(Theme.serif(20))
                .foregroundStyle(p.ink)
            Text(wisdom.c.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(p.gold.opacity(0.9))
        }
    }

    private var fortuneCard: some View {
        Card(header: "🎱 DAILY FORTUNE", palette: p) {
            Text(DailyPick.fortune())
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(p.ink)
        }
    }

    private var stepsCard: some View {
        let goal = StepsManager.goal
        let done = steps.todaySteps >= goal
        return Card(header: "👟 STEPS", palette: p) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(steps.todaySteps.formatted())
                    .font(Theme.serif(38))
                    .foregroundStyle(p.ink)
                Text("of \(goal.formatted())")
                    .font(.system(size: 15))
                    .foregroundStyle(p.muted)
                Spacer()
                if done { Text("🏆").font(.system(size: 26)) }
            }
            CapsuleBar(
                pct: Double(steps.todaySteps) / Double(goal),
                fill: p.accent,
                track: p.ink.opacity(0.1),
                height: 12
            )
            Button {
                Task { await steps.requestAuthorization() }
            } label: {
                Text("Refresh from Health")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(p.accent)
            }
        }
    }
}
