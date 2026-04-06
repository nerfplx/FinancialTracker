import SwiftUI

struct ContentView: View {
    @StateObject private var vm = SmartSpendViewModel()
    @State private var showMain = false
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        Group {
            if !showMain {
                SplashView(showMain: $showMain)
                    .environmentObject(vm)
            } else if vm.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(vm)
            } else {
                OnboardingView()
                    .environmentObject(vm)
            }
        }
        .id(localization.language)
        .animation(.easeInOut, value: showMain)
        .animation(.spring(), value: vm.hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
}
