import SwiftUI

@main
struct WidgeonApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var tab: String =
        ProcessInfo.processInfo.environment["WIDGEON_TAB"] ?? "today"

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag("today")
            PetView()
                .tabItem { Label("Pet", systemImage: "bird.fill") }
                .tag("pet")
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag("settings")
        }
        .preferredColorScheme(.dark)
        .tint(Theme.petGreen)
    }
}
