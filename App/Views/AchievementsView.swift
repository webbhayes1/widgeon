import SwiftUI

/// Trophy case: every achievement, earned ones lit up with their unlock date.
struct AchievementsView: View {
    let pet: PetState
    @Environment(\.dismiss) private var dismiss

    private let p = Theme.palette()

    var body: some View {
        let unlocked = Achievements.unlocked()
        let count = Achievements.all.filter { unlocked[$0.id] != nil }.count

        ZStack {
            BrandBackground(palette: p).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Achievements")
                            .font(Theme.serif(34))
                            .foregroundStyle(p.ink)
                        Spacer()
                        Text("\(count)/\(Achievements.all.count)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(p.gold)
                    }
                    .padding(.top, 24)

                    ForEach(Achievements.all) { a in
                        row(a, unlockedOn: unlocked[a.id])
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func row(_ a: Achievement, unlockedOn: String?) -> some View {
        let isUnlocked = unlockedOn != nil
        return HStack(spacing: 14) {
            Text(a.emoji)
                .font(.system(size: 26))
                .frame(width: 52, height: 52)
                .background(Circle().fill(isUnlocked ? p.gold.opacity(0.22) : p.cardBG))
                .overlay(Circle().strokeBorder(isUnlocked ? p.gold : p.cardBorder))
                .saturation(isUnlocked ? 1 : 0)
                .opacity(isUnlocked ? 1 : 0.45)

            VStack(alignment: .leading, spacing: 3) {
                Text(a.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(p.ink.opacity(isUnlocked ? 1 : 0.55))
                Text(a.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(p.muted)
            }
            Spacer()
            if let day = unlockedOn {
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(p.gold)
                    Text(day)
                        .font(.system(size: 10))
                        .foregroundStyle(p.muted)
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(p.muted.opacity(0.6))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18).fill(p.cardBG))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(
            isUnlocked ? p.gold.opacity(0.5) : p.cardBorder))
    }
}
