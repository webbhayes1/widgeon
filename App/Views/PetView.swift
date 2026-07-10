import SwiftUI
import WidgetKit

struct PetView: View {
    @State private var pet = Pet.load()
    @State private var dancing = false
    @State private var draftName = ""
    @State private var draftCharacter: PetCharacter = .duck
    @State private var editing = false
    @State private var hearts: [Heart] = []
    @State private var evolvedStage: PetStage? = nil
    @ObservedObject private var steps = StepsManager.shared

    struct Heart: Identifiable {
        let id = UUID()
        let x: CGFloat
        let drift: CGFloat
        let delay: Double
        let size: CGFloat
    }

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
            // Training happens in the background (step goal) — if it pushed
            // the pet past a threshold since we last looked, celebrate now.
            checkForEvolution(announce: pet.feeds > 0)
            Task { await steps.refresh() }
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

                // Hearts float up from the pet when it gets fed.
                ForEach(hearts) { heart in
                    FloatingHeart(heart: heart)
                        .position(x: geo.size.width / 2, y: ground - petSize / 2)
                }
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

                trainCard

                Spacer()

                Button {
                    var updated = pet
                    if Pet.feed(&updated) {
                        Pet.save(updated)
                        pet = updated
                        celebrate()
                        spawnHearts()
                        checkForEvolution(announce: true)
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

            if let evolved = evolvedStage {
                evolutionBanner(evolved)
            }
        }
    }

    // MARK: Train card — real steps train the pet (the Digimon mechanic)

    private var trainCard: some View {
        let goal = StepsManager.goal
        let trained = Pet.trainedToday(pet)
        let pct = min(1, Double(steps.todaySteps) / Double(goal))

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trained ? "⚡ Trained today" : "👟 Training")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(trained ? mp.gold : mp.ink.opacity(0.9))
                Spacer()
                Text(trained
                    ? "+30 XP"
                    : "\(steps.todaySteps.formatted()) / \(goal.formatted())")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(mp.ink.opacity(0.7))
            }
            CapsuleBar(
                pct: trained ? 1 : pct,
                fill: trained ? mp.gold : mp.accent,
                track: mp.ink.opacity(0.15),
                height: 6
            )
            if !trained {
                Text("Hit your step goal to train \(pet.name) (+30 XP)")
                    .font(.system(size: 11))
                    .foregroundStyle(mp.ink.opacity(0.6))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(mp.cardBG))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(mp.cardBorder))
        .padding(.horizontal, 24)
    }

    // MARK: Evolution celebration

    private func evolutionBanner(_ stage: PetStage) -> some View {
        VStack {
            VStack(spacing: 10) {
                Text("✨ Evolution! ✨")
                    .font(Theme.serif(26))
                    .foregroundStyle(mp.gold)
                PixelSpriteView(sprite: stage.sprite, accessibilityLabel: stage.title)
                    .frame(width: 72, height: 72)
                Text("\(pet.name) is now \(stage.title)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(mp.ink)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 28)
            .background(RoundedRectangle(cornerRadius: 24).fill(mp.base))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(mp.gold, lineWidth: 2))
            .shadow(color: mp.gold.opacity(0.4), radius: 24)
            .padding(.top, 150)
            .onTapGesture { withAnimation(.easeIn(duration: 0.25)) { evolvedStage = nil } }
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    /// Shows the evolution banner if the pet's stage rose past the last one
    /// the user saw (feeds do it live; step-goal training does it silently
    /// in the background, so onAppear checks too).
    private func checkForEvolution(announce: Bool) {
        let seenKey = "pet.seenStage"
        let index = Pet.stageIndex(pet)
        let seen = SharedStore.defaults.integer(forKey: seenKey)
        defer { SharedStore.defaults.set(index, forKey: seenKey) }
        guard announce, index > seen, evolvedStage == nil else { return }
        withAnimation(.spring(duration: 0.5)) {
            evolvedStage = Pet.stage(for: pet)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeIn(duration: 0.4)) { evolvedStage = nil }
        }
    }

    private func spawnHearts() {
        let burst = (0..<8).map { _ in
            Heart(
                x: .random(in: -45...45),
                drift: .random(in: -25...25),
                delay: .random(in: 0...0.5),
                size: .random(in: 16...28)
            )
        }
        hearts.append(contentsOf: burst)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            hearts.removeAll { b in burst.contains { $0.id == b.id } }
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

/// One heart from a feed burst: rises from the pet, drifting and fading.
private struct FloatingHeart: View {
    let heart: PetView.Heart
    @State private var risen = false

    var body: some View {
        Text("💛")
            .font(.system(size: heart.size))
            .opacity(risen ? 0 : 0.95)
            .offset(
                x: heart.x + (risen ? heart.drift : 0),
                y: risen ? -150 : -10
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.6).delay(heart.delay)) {
                    risen = true
                }
            }
    }
}
