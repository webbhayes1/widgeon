import SwiftUI

/// Widgeon Plus paywall: the five locked characters in their crowned glory.
struct PaywallView: View {
    @ObservedObject private var store = Store.shared
    @Environment(\.dismiss) private var dismiss

    private let p = Theme.palette()
    private let lockedCharacters: [PetCharacter] = [.cat, .dog, .turtle, .plant, .pixel]

    var body: some View {
        ZStack {
            BrandBackground(palette: p).ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()
                Text("Widgeon Plus")
                    .font(Theme.serif(40))
                    .foregroundStyle(p.ink)
                Text("Five more companions, one small tip jar.")
                    .font(.system(size: 15))
                    .foregroundStyle(p.muted)

                HStack(spacing: 10) {
                    ForEach(lockedCharacters) { c in
                        VStack(spacing: 6) {
                            PixelSpriteView(
                                sprite: c.stages.last!.sprite,
                                accessibilityLabel: c.displayName
                            )
                            .frame(width: 56, height: 56)
                            Text(c.displayName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(p.ink.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(p.cardBG))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(p.cardBorder))
                    }
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 8) {
                    benefit("🐾", "All five extra characters, every stage")
                    benefit("💛", "Progress carries over — same pet, new look")
                    benefit("🔓", "One-time purchase. No subscription, ever.")
                }
                .padding(.horizontal, 36)

                Spacer()

                Button {
                    Task {
                        if await store.buyPlus() { dismiss() }
                    }
                } label: {
                    Text(store.purchasing
                        ? "One sec…"
                        : "Unlock for \(store.plusProduct?.displayPrice ?? "$2.99")")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(p.isDay ? p.ink : p.base)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(p.gold))
                }
                .disabled(store.purchasing)
                .padding(.horizontal, 40)

                Button("Restore purchase") {
                    Task {
                        await store.restore()
                        if store.hasPlus { dismiss() }
                    }
                }
                .font(.footnote)
                .foregroundStyle(p.muted)
                .padding(.bottom, 20)
            }
        }
    }

    private func benefit(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(p.ink.opacity(0.9))
        }
    }
}
