import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: FastingManager

    var body: some View {
        Group {
            if manager.currentSession != nil && manager.isTimerRunning {
                mainTabView
            } else {
                SetupView(manager: manager)
            }
        }
        .onAppear {
            manager.requestNotificationPermission()
        }
    }

    private var mainTabView: some View {
        TabView {
            NavigationView {
                DashboardView(manager: manager)
                    .navigationTitle("FastTracker")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "timer")
                Text("Dashboard")
            }

            NavigationView {
                TimelineView(manager: manager)
                    .navigationTitle("Timeline")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "list.bullet.below.rectangle")
                Text("Timeline")
            }

            NavigationView {
                StatsView(manager: manager)
                    .navigationTitle("Statistics")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Stats")
            }
        }
        .tint(.orange)
    }
}
