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
                Text("小小调查员：数字岛").font(.largeTitle.bold())
                Text("先弄清楚发生了什么，再决定怎么算。")
                    .font(.title3).foregroundStyle(.secondary)

                if let mission {
                    NavigationLink {
                        MissionFlowView(mission: mission, playerID: playerID)
                    } label: {
                        Label("开始苹果调查", systemImage: "apple.logo")
                            .frame(maxWidth: 320)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                } else if let loadError {
                    ContentUnavailableView("任务加载失败", systemImage: "exclamationmark.triangle", description: Text(loadError))
                } else {
                    ProgressView("正在准备任务…")
                }

                NavigationLink("家长查看") { ParentDashboardView() }
                    .buttonStyle(.bordered).controlSize(.large)
                Spacer()
            }
            .padding(32)
            .task {
                guard mission == nil else { return }
                do { mission = try MissionContentLoader().loadMission(id: "apple_decrease_result_001") }
                catch { loadError = error.localizedDescription }
            }
        }
    }
}

#Preview { ContentView() }
