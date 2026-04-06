import SwiftUI

@main
struct FinancialTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) var appDelegate
    @StateObject private var localization = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .environmentObject(localization)
                .environment(\.locale, localization.locale)
        }
    }
}
