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
        // Screenshot hook (like WIDGEON_TOD): render the countdown widget's
        // systemSmall card in-app, since the sim's widget gallery can't be scripted.
        if ProcessInfo.processInfo.environment["WIDGEON_WIDGETPREVIEW"] != nil {
            widgetPreview
        } else {
            tabs
        }
    }

    private var widgetPreview: some View {
        let p = Theme.palette()
        return ZStack {
            Color(white: 0.15).ignoresSafeArea()
            CountdownWidgetView(date: .now)
                .padding(16)
                .frame(width: 170, height: 170)
                .background(BrandBackground(palette: p))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private var tabs: some View {
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
