import SwiftUI
import WidgetKit

struct Card<Content: View>: View {
    let header: String
    let accent: Color
    var bg: Color = Color(hex: 0x15151E)
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(header)
                .font(.system(size: 11, weight: .heavy))
                .kerning(1.5)
                .foregroundStyle(accent)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(bg))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.07)))
    }
}

struct TodayView: View {
    @ObservedObject private var steps = StepsManager.shared

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
        .background(Theme.bg.ignoresSafeArea())
        .task { await steps.requestAuthorization() }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .kerning(1.5)
                    .foregroundStyle(Theme.gold)
                Text("Today")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(.white)
            }
            Spacer()
            VStack(spacing: 1) {
                Text("LVL \(XP.level)")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Color(hex: 0xFFD34D))
                Text("\(XP.total.formatted()) XP")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.07)))
        }
        .padding(.top, 8)
    }

    private var vocabCard: some View {
        let word = DailyPick.vocab()
        return Card(header: "WORD OF THE DAY", accent: Theme.gold, bg: Color(hex: 0x171420)) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(word.w)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                Text(word.p)
                    .font(.system(size: 14).italic())
                    .foregroundStyle(.white.opacity(0.5))
            }
            Text(word.d)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.9))
            Text("“\(word.e)”")
                .font(.system(size: 14).italic())
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    private var roastCard: some View {
        Card(header: "🔥 DAILY ROAST", accent: Theme.ember, bg: Color(hex: 0x1D120C)) {
            Text(DailyPick.roast())
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var affirmationCard: some View {
        Card(header: "🌤 AFFIRMATION", accent: Theme.teal, bg: Color(hex: 0x0E2A2F)) {
            Text(DailyPick.affirmation())
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private var wisdomCard: some View {
        let wisdom = Wisdom.today()
        return Card(header: "✦ DAILY WISDOM", accent: Color(hex: 0xE8DCC0), bg: Color(hex: 0x141210)) {
            Text(wisdom.t)
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundStyle(.white)
            Text(wisdom.c.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(Color(hex: 0xE8DCC0).opacity(0.8))
        }
    }

    private var fortuneCard: some View {
        Card(header: "🎱 DAILY FORTUNE", accent: Color(hex: 0xD48CFF), bg: Color(hex: 0x1A1024)) {
            Text(DailyPick.fortune())
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private var stepsCard: some View {
        let goal = StepsManager.goal
        let done = steps.todaySteps >= goal
        return Card(header: "👟 STEPS", accent: Theme.green, bg: Color(hex: 0x102015)) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(steps.todaySteps.formatted())
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                Text("of \(goal.formatted())")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                if done { Text("🏆").font(.system(size: 26)) }
            }
            CapsuleBar(
                pct: Double(steps.todaySteps) / Double(goal),
                fill: Theme.green,
                track: .white.opacity(0.1),
                height: 12
            )
            Button {
                Task { await steps.requestAuthorization() }
            } label: {
                Text("Refresh from Health")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.green)
            }
        }
    }
}
