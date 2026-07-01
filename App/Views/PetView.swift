import SwiftUI
import WidgetKit

struct PetView: View {
    @State private var pet = Pet.load()
    @State private var dancing = false

    private var stage: PetStage { Pet.stage(for: pet) }
    private var fedToday: Bool { Pet.fedToday(pet) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                Text(stage.emoji)
                    .font(.system(size: 120))
                    .rotationEffect(.degrees(dancing ? 12 : 0))
                    .offset(y: dancing ? -20 : 0)
                    .animation(
                        dancing
                            ? .easeInOut(duration: 0.4).repeatCount(5, autoreverses: true)
                            : .default,
                        value: dancing
                    )

                Text(pet.name)
                    .font(.largeTitle.bold())

                Text(pet.feeds > 0 ? "Day \(pet.feeds) together · \(stage.title)" : "A new friend awaits.")
                    .foregroundStyle(.secondary)

                if pet.streak >= 2 {
                    Text("🔥 \(pet.streak)-day streak · best \(pet.best)")
                        .font(.callout.weight(.semibold))
                }

                Spacer()

                Button {
                    var updated = pet
                    if Pet.feed(&updated) {
                        Pet.save(updated)
                        pet = updated
                        dancing = true
                        WidgetCenter.shared.reloadTimelines(ofKind: "pet")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            dancing = false
                        }
                    }
                } label: {
                    Label(
                        fedToday ? "Fed today ✓" : (pet.feeds == 0 ? "Hatch" : "Feed \(pet.name)"),
                        systemImage: "fork.knife"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(fedToday)
                .padding(.horizontal)

                // Achievements land here in a coming session: evolution
                // milestones, streak trophies, night-owl feeds, and more.
                Text("🏆 Achievements — coming soon")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom)
            }
            .navigationTitle("Pet")
            .onAppear { pet = Pet.load() }
        }
    }
}
