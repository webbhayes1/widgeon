import SwiftUI
import WidgetKit

struct PetView: View {
    @State private var pet = Pet.load()
    @State private var dancing = false
    @State private var draftName = ""
    @State private var draftCharacter: PetCharacter = .duck
    @State private var editing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0B1F14), Color(hex: 0x123324)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

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
            Text("🥚")
                .font(.system(size: 80))
            Text("Meet your pet")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(.white)
            Text("Name it, pick a character, and feed it every day to watch it evolve.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            TextField("Name your pet", text: $draftName)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.08)))
                .foregroundStyle(.white)
                .padding(.horizontal, 40)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(PetCharacter.allCases) { c in
                    Button {
                        draftCharacter = c
                    } label: {
                        VStack(spacing: 6) {
                            Text(c.stages[4].emoji)
                                .font(.system(size: 38))
                            Text(c.displayName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.white.opacity(draftCharacter == c ? 0.16 : 0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(
                                    draftCharacter == c ? Theme.petGreen : .clear,
                                    lineWidth: 2
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
                    .foregroundStyle(Color(hex: 0x0B1F14))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Theme.petGreen))
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
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    draftName = pet.name
                    draftCharacter = pet.character
                    editing = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            Text(stage.emoji)
                .font(.system(size: 140))
                .shadow(color: Theme.petGreen.opacity(0.35), radius: 30)
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
                .foregroundStyle(Theme.petGreen)

            HStack(spacing: 10) {
                statChip("Day \(pet.feeds)")
                if pet.streak >= 2 { statChip("🔥 \(pet.streak) streak") }
                if pet.best >= 2 { statChip("⭐ best \(pet.best)") }
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
                    .foregroundStyle(fedToday ? .white.opacity(0.5) : Color(hex: 0x0B1F14))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(fedToday ? .white.opacity(0.1) : Theme.petGreen))
            }
            .disabled(fedToday)
            .padding(.horizontal, 40)

            Text("🏆 Achievements — coming soon")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.35))
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
        .presentationDetents([.medium])
    }

    private func statChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(.white.opacity(0.08)))
    }

    private func celebrate() {
        dancing = true
        WidgetCenter.shared.reloadTimelines(ofKind: "pet")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            dancing = false
        }
    }
}
