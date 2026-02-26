import SwiftUI

@main
struct FastTrackerApp: App {
    @StateObject private var fastingManager = FastingManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fastingManager)
        }
    }
}
