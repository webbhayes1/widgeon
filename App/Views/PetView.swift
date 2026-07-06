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

    var body: some View {
        ZStack {
            BrandBackground(palette: p).ignoresSafeArea()

            if pet.feeds == 0 {
                onboarding
            } else {
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

        return VStack(spacing: 14) {
            HStack {
                Text(pet.name)
                    .font(Theme.serif(38))
                    .foregroundStyle(p.ink)
                Spacer()
                Button {
                    draftName = pet.name
                    draftCharacter = pet.character
                    editing = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(p.muted)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            PixelSpriteView(sprite: stage.sprite, accessibilityLabel: stage.title)
                .frame(width: 176, height: 176)
                .shadow(color: p.gold.opacity(0.35), radius: 30)
                .rotationEffect(.degrees(dancing ? 12 : 0))
                .offset(y: dancing ? -22 : 0)
                .animation(
                    dancing
                        ? .easeInOut(duration: 0.4).repeatCount(5, autoreverses: true)
                        : .default,
                    value: dancing
                )

            Text(stage.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(p.gold)

            HStack(spacing: 10) {
                statChip("Day \(pet.feeds)")
                if pet.streak >= 2 { statChip("🔥 \(pet.streak) streak") }
                if Pet.trainedToday(pet) { statChip("⚡ trained") }
                else if pet.best >= 2 { statChip("⭐ best \(pet.best)") }
            }

            VStack(spacing: 4) {
                CapsuleBar(pct: Pet.stageProgress(pet), fill: p.gold, track: p.ink.opacity(0.12), height: 8)
                Text("\(Pet.petXP(pet)) XP · feed +20 · step goal +30")
                    .font(.system(size: 11))
                    .foregroundStyle(p.muted)
            }
            .padding(.horizontal, 60)

            if !Pet.trainedToday(pet) {
                Text("Hit your step goal to train \(pet.name) 👟")
                    .font(.system(size: 12))
                    .foregroundStyle(p.muted)
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
                    .foregroundStyle(fedToday ? p.muted : onGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(fedToday ? p.cardBG : p.gold))
            }
            .disabled(fedToday)
            .padding(.horizontal, 40)

            Text("🏆 Achievements — coming soon")
                .font(.footnote)
                .foregroundStyle(p.muted.opacity(0.7))
                .padding(.bottom, 24)
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

    private func statChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(p.ink.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(p.cardBG))
            .overlay(Capsule().strokeBorder(p.cardBorder))
    }

    private func celebrate() {
        dancing = true
        WidgetCenter.shared.reloadTimelines(ofKind: "pet")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            dancing = false
        }
    }
}
