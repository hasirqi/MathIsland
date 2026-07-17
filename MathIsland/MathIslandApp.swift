import SwiftUI
import SwiftData

@main
struct MathIslandApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(for: [PlayerProfileEntity.self, LearningRecordEntity.self, SkillMasteryEntity.self])
    }
}
