import SwiftUI
import WidgetKit

struct PetView: View {
    @State private var pet = Pet.load()
    @State private var dancing = false
    @State private var draftName = ""
    @State private var draftCharacter: PetCharacter = .duck
    @State private var editing = false

    private let p = Theme.palette()
    /// Dark text that reads on the gold action buttons in both modes.
    private var onGold: Color { p.isDay ? p.ink : p.base }
    /// Ink for text floating directly on the meadow: picked by actual sky
    /// brightness (which drifts from the 6:30 palette flip at dawn/dusk).
    private let mp = Meadow.skyIsLight() ? Theme.day : Theme.night

    var body: some View {
        ZStack {
            if pet.feeds == 0 {
                BrandBackground(palette: p).ignoresSafeArea()
                onboarding
            } else {
                MeadowView().ignoresSafeArea()
                petHome
            }
        }
        .onAppear {
            pet = Pet.load()
            draftName = pet.name
            draftCharacter = pet.character
        }
        .sheet(isPresented: $editing) { editSheet }
    }

    // MARK: First run: name it, pick a character, hatch it

    private var onboarding: some View {
        VStack(spacing: 22) {
            Spacer()
            PixelSpriteView(sprite: "egg", accessibilityLabel: "A mysterious egg")
                .frame(width: 96, height: 96)
            Text("Meet your pet")
                .font(Theme.serif(40))
                .foregroundStyle(p.ink)
            Text("Name it, pick a character, and feed it every day to watch it evolve.")
                .font(.system(size: 15))
                .foregroundStyle(p.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            TextField("Name your pet", text: $draftName)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(p.cardBG))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(p.cardBorder))
                .foregroundStyle(p.ink)
                .padding(.horizontal, 40)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(PetCharacter.allCases) { c in
                    Button {
                        draftCharacter = c
                    } label: {
                        VStack(spacing: 6) {
                            PixelSpriteView(sprite: c.stages[4].sprite, accessibilityLabel: c.displayName)
                                .frame(width: 44, height: 44)
                            Text(c.displayName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(p.ink.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(draftCharacter == c ? p.gold.opacity(0.18) : p.cardBG)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(
                                    draftCharacter == c ? p.gold : p.cardBorder,
                                    lineWidth: draftCharacter == c ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                var updated = pet
                updated.name = draftName.trimmingCharacters(in: .whitespaces).isEmpty
                    ? "Widge" : draftName.trimmingCharacters(in: .whitespaces)
                updated.character = draftCharacter
                Pet.feed(&updated)
                Pet.save(updated)
                pet = updated
                celebrate()
            } label: {
                Text(draftCharacter == .plant ? "Plant it 🌱" : "Hatch it 🐣")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(onGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(p.gold))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
    }

    // MARK: Home: the pet, its stats, and the feed button

    private var petHome: some View {
        let stage = Pet.stage(for: pet)
        let fedToday = Pet.fedToday(pet)

        return ZStack {
            // The pet stands on the meadow's grass line, like the handoff scenes.
            GeometryReader { geo in
                let ground = Meadow.groundY(in: UIScreen.main.bounds.size)
                    - geo.frame(in: .global).minY
                let petSize: CGFloat = 150

                Ellipse()
                    .fill(.black.opacity(0.22))
                    .frame(width: petSize * 0.6, height: 14)
                    .position(x: geo.size.width / 2, y: ground + 4)

                PixelSpriteView(sprite: stage.sprite, accessibilityLabel: stage.title)
                    .frame(width: petSize, height: petSize)
                    .shadow(color: p.gold.opacity(0.35), radius: 30)
                    .rotationEffect(.degrees(dancing ? 12 : 0))
                    .offset(y: dancing ? -22 : 0)
                    .animation(
                        dancing
                            ? .easeInOut(duration: 0.4).repeatCount(5, autoreverses: true)
                            : .default,
                        value: dancing
                    )
                    .position(x: geo.size.width / 2, y: ground - petSize / 2 + 6)
            }

            VStack(spacing: 12) {
                HStack {
                    Text(pet.name)
                        .font(Theme.serif(38))
                        .foregroundStyle(mp.ink)
                        .shadow(color: meadowShadow, radius: 5)
                    Spacer()
                    Button {
                        draftName = pet.name
                        draftCharacter = pet.character
                        editing = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(mp.ink.opacity(0.7))
                            .shadow(color: meadowShadow, radius: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Text(stage.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(mp.gold)
                    .shadow(color: meadowShadow, radius: 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                HStack(spacing: 10) {
                    statChip("Day \(pet.feeds)")
                    if pet.streak >= 2 { statChip("🔥 \(pet.streak) streak") }
                    if Pet.trainedToday(pet) { statChip("⚡ trained") }
                    else if pet.best >= 2 { statChip("⭐ best \(pet.best)") }
                    Spacer()
                }
                .padding(.horizontal, 24)

                VStack(spacing: 4) {
                    CapsuleBar(pct: Pet.stageProgress(pet), fill: mp.gold, track: mp.ink.opacity(0.18), height: 8)
                    Text("\(Pet.petXP(pet)) XP · feed +20 · step goal +30")
                        .font(.system(size: 11))
                        .foregroundStyle(mp.ink.opacity(0.75))
                        .shadow(color: meadowShadow, radius: 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)

                if !Pet.trainedToday(pet) {
                    Text("Hit your step goal to train \(pet.name) 👟")
                        .font(.system(size: 12))
                        .foregroundStyle(mp.ink.opacity(0.75))
                        .shadow(color: meadowShadow, radius: 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                }

                Spacer()

                Button {
                    var updated = pet
                    if Pet.feed(&updated) {
                        Pet.save(updated)
                        pet = updated
                        celebrate()
                    }
                } label: {
                    Text(fedToday ? "Fed today ✓" : "Feed \(pet.name) 🍞")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(fedToday ? mp.ink.opacity(0.6) : (mp.isDay ? mp.ink : mp.base))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(fedToday ? mp.cardBG : mp.gold))
                }
                .disabled(fedToday)
                .padding(.horizontal, 40)

                Text("🏆 Achievements — coming soon")
                    .font(.footnote)
                    .foregroundStyle(mp.ink.opacity(0.55))
                    .shadow(color: meadowShadow, radius: 3)
                    .padding(.bottom, 8)
            }
        }
    }

    private var editSheet: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $draftName)
                Picker("Character", selection: $draftCharacter) {
                    ForEach(PetCharacter.allCases) { c in
                        Text("\(c.stages[4].emoji) \(c.displayName)").tag(c)
                    }
                }
                Text("Switching characters keeps all progress — same pet, new look.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Edit pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        var updated = pet
                        updated.name = draftName.trimmingCharacters(in: .whitespaces).isEmpty
                            ? pet.name : draftName.trimmingCharacters(in: .whitespaces)
                        updated.character = draftCharacter
                        Pet.save(updated)
                        pet = updated
                        WidgetCenter.shared.reloadTimelines(ofKind: "pet")
                        editing = false
                    }
                }
            }
        }
        .tint(p.accent)
        .presentationDetents([.medium])
    }

    /// Soft halo behind meadow-floating text: dark on night sky, light on day.
    private var meadowShadow: Color {
        mp.isDay ? .white.opacity(0.5) : .black.opacity(0.45)
    }

    private func statChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(mp.ink.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(mp.cardBG))
            .overlay(Capsule().strokeBorder(mp.cardBorder))
    }

    private func celebrate() {
        dancing = true
        WidgetCenter.shared.reloadTimelines(ofKind: "pet")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            dancing = false
        }
    }
}
