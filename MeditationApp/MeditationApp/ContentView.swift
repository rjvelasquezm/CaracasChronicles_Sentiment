import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab { case home, history, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Breathe", systemImage: "wind")
                }
                .tag(Tab.home)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(Tab.history)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .accentColor(Color("AccentTeal"))
        .background(Color("BackgroundDeep"))
    }
}
