import SwiftUI
import WidgetKit

struct SettingsView: View {
    @State private var pet = Pet.load()
    @State private var drinkLabel = Drink.label
    @State private var drinkTarget = Drink.target
    @State private var drinkIsLimit = Drink.isLimit
    @State private var stepGoal = StepsManager.goal
    @State private var wisdomTradition = Wisdom.tradition
    @State private var roastSpicy = DailyPick.roastSpicy
    @State private var lifeMode = SharedStore.defaults.bool(forKey: "life.mode")
    @State private var birthday: Date = {
        let ts = SharedStore.defaults.double(forKey: "life.birthday")
        return ts > 0 ? Date(timeIntervalSince1970: ts) : Date(timeIntervalSince1970: 852_076_800) // 1997-01-01
    }()

    private let p = Theme.palette()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(Theme.serif(44))
                    .foregroundStyle(p.ink)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
            Form {
                Section("Pet") {
                    TextField("Name", text: $pet.name)
                    Picker("Character", selection: $pet.character) {
                        ForEach(PetCharacter.allCases) { c in
                            Text("\(c.stages.last!.emoji) \(c.displayName)").tag(c)
                        }
                    }
                }
                .listRowBackground(p.cardBG)

                Section("Drink counter") {
                    TextField("Label", text: $drinkLabel)
                    Stepper("Target: \(drinkTarget)", value: $drinkTarget, in: 1...30)
                    Toggle("Limit mode (nights out)", isOn: $drinkIsLimit)
                    if drinkIsLimit {
                        Text("Counts against a limit instead of toward a goal, and the day resets at 6 AM instead of midnight.")
                            .font(.footnote)
                            .foregroundStyle(p.muted)
                    }
                }
                .listRowBackground(p.cardBG)

                Section("Daily roast") {
                    Toggle("Spicy mode", isOn: $roastSpicy)
                    Text(roastSpicy
                        ? "Uncensored tough love. Not for the faint of heart."
                        : "Clean tough love. Flip the switch if you can take it.")
                        .font(.footnote)
                        .foregroundStyle(p.muted)
                }
                .listRowBackground(p.cardBG)

                Section("Daily wisdom") {
                    Picker("Tradition", selection: $wisdomTradition) {
                        ForEach(WisdomTradition.allCases) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    Text("More traditions (Quran, Dhammapada, Bhagavad Gita, Tao Te Ching) coming soon.")
                        .font(.footnote)
                        .foregroundStyle(p.muted)
                }
                .listRowBackground(p.cardBG)

                Section("Steps") {
                    Stepper("Daily goal: \(stepGoal.formatted())", value: $stepGoal, in: 1000...40000, step: 500)
                }
                .listRowBackground(p.cardBG)

                Section("Life progress") {
                    Toggle("Life mode (vs. year mode)", isOn: $lifeMode)
                    if lifeMode {
                        DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                    }
                }
                .listRowBackground(p.cardBG)

                Section {
                    Button("Apply & refresh widgets") {
                        save()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(p.gold)
                    .fontWeight(.semibold)
                }
                .listRowBackground(p.cardBG)
            }
            .foregroundStyle(p.ink)
            .scrollContentBackground(.hidden)
            }
            .background(BrandBackground(palette: p).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(p.accent)
    }

    private func save() {
        Pet.save(pet)
        Drink.label = drinkLabel
        Drink.target = drinkTarget
        Drink.isLimit = drinkIsLimit
        StepsManager.goal = stepGoal
        Wisdom.tradition = wisdomTradition
        DailyPick.roastSpicy = roastSpicy
        SharedStore.defaults.set(lifeMode, forKey: "life.mode")
        SharedStore.defaults.set(birthday.timeIntervalSince1970, forKey: "life.birthday")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
