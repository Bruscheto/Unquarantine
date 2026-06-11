import SwiftUI

struct ContentView: View {
    @EnvironmentObject var status: AppStatus

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
        }
        .padding(24)
        .frame(width: 380, height: 200)
    }
}
