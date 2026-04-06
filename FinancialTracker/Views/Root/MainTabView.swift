import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label(L10n.Tabs.today, systemImage: "house.fill") }
            AnalyticsView()
                .tabItem { Label(L10n.Tabs.analytics, systemImage: "chart.bar.fill") }
            AddExpenseView()
                .tabItem { Label(L10n.Tabs.add, systemImage: "plus.circle.fill") }
            HistoryView()
                .tabItem { Label(L10n.Tabs.history, systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label(L10n.Tabs.settings, systemImage: "gearshape.fill") }
        }
    }
}
