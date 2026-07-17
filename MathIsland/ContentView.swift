import SwiftUI

struct ContentView: View {
    @State private var mission: Mission?
    @State private var loadError: String?
    private let playerID = UUID(uuidString: "A693C020-1B45-4C78-A9B3-57FD69A52676")!

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                Text("🏝️").font(.system(size: 86))
                Text(L10n.text("app.title")).font(.largeTitle.bold())
                Text(L10n.text("app.subtitle"))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let mission {
                    NavigationLink {
                        MissionFlowView(mission: mission, playerID: playerID)
                    } label: {
                        Label(L10n.text("home.startAppleMission"), systemImage: "apple.logo")
                            .frame(maxWidth: 320)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else if let loadError {
                    ContentUnavailableView(
                        L10n.text("home.loadFailed"),
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else {
                    ProgressView(L10n.text("home.preparing"))
                }

                NavigationLink(L10n.text("home.parentDashboard")) {
                    ParentDashboardView()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                Spacer()
            }
            .padding(32)
            .task {
                guard mission == nil else { return }
                do {
                    mission = try MissionContentLoader().loadMission(id: "apple_decrease_result_001")
                } catch {
                    loadError = error.localizedDescription
                }
            }
        }
    }
}

#Preview { ContentView() }