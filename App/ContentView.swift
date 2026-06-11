import SwiftUI

struct ContentView: View {
    @EnvironmentObject var status: AppStatus
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSetup = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Unquarantine")
                .font(.title2).bold()
            Text(status.lastMessage)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Enable the Finder extension in System Settings \u{2192} General \u{2192} Login Items & Extensions.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.tertiary)
            Button("Set Up Permissions\u{2026}") { showSetup = true }
        }
        .padding(24)
        .frame(width: 380, height: 240)
        .onAppear {
            if !hasCompletedOnboarding { showSetup = true }
        }
        .sheet(isPresented: $showSetup) {
            OnboardingView()
        }
    }
}
