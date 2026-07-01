import SwiftUI
import WidgetKit

struct SettingsView: View {
    @State private var pet = Pet.load()
    @State private var drinkLabel = Drink.label
    @State private var drinkTarget = Drink.target
    @State private var drinkIsLimit = Drink.isLimit
    @State private var stepGoal = StepsManager.goal
    @State private var lifeMode = SharedStore.defaults.bool(forKey: "life.mode")
    @State private var birthday: Date = {
        let ts = SharedStore.defaults.double(forKey: "life.birthday")
        return ts > 0 ? Date(timeIntervalSince1970: ts) : Date(timeIntervalSince1970: 852_076_800) // 1997-01-01
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet") {
                    TextField("Name", text: $pet.name)
                    Picker("Character", selection: $pet.character) {
                        ForEach(PetCharacter.allCases) { c in
                            Text("\(c.stages.last!.emoji) \(c.displayName)").tag(c)
                        }
                    }
                }

                Section("Drink counter") {
                    TextField("Label", text: $drinkLabel)
                    Stepper("Target: \(drinkTarget)", value: $drinkTarget, in: 1...30)
                    Toggle("Limit mode (nights out)", isOn: $drinkIsLimit)
                    if drinkIsLimit {
                        Text("Counts against a limit instead of toward a goal, and the day resets at 6 AM instead of midnight.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Steps") {
                    Stepper("Daily goal: \(stepGoal.formatted())", value: $stepGoal, in: 1000...40000, step: 500)
                }

                Section("Life progress") {
                    Toggle("Life mode (vs. year mode)", isOn: $lifeMode)
                    if lifeMode {
                        DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                    }
                }

                Section {
                    Button("Apply & refresh widgets") {
                        save()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func save() {
        Pet.save(pet)
        Drink.label = drinkLabel
        Drink.target = drinkTarget
        Drink.isLimit = drinkIsLimit
        StepsManager.goal = stepGoal
        SharedStore.defaults.set(lifeMode, forKey: "life.mode")
        SharedStore.defaults.set(birthday.timeIntervalSince1970, forKey: "life.birthday")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
