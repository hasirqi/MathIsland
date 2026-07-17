import Foundation
import Testing
@testable import MathIsland

struct MathIslandTests {
    private var mission: Mission {
        Mission(
            id: "apple_decrease_result_001", schemaVersion: 1, title: "消失的苹果", chapterID: "missing_apples", grade: 2, difficulty: 1,
            learningObjectives: [.init(id: "decrease", title: "识别减少", description: "理解减少关系")],
            story: .init(scene: "shop", text: "12个苹果拿走5个", narration: nil, characters: []),
            quantities: .init(initial: 12, change: 5, result: 7, unknown: .result),
            relationship: .init(type: .decrease, equation: "12 - 5 = 7", answer: 7),
            informationItems: [
                .init(id: "initial", text: "12", role: .known),
                .init(id: "change", text: "5", role: .known),
                .init(id: "question", text: "剩余", role: .question)
            ],
            representations: [.objects, .equation],
            equationChoices: [
                .init(id: "correct", expression: "12 - 5", isCorrect: true, errorType: nil),
                .init(id: "add", expression: "12 + 5", isCorrect: false, errorType: .operationSelectionError),
                .init(id: "reverse", expression: "5 - 12", isCorrect: false, errorType: .equationOrderError)
            ],
            reasoningOptions: [.init(id: "reason", text: "拿走后变少", isCorrect: true)],
            hints: [.init(id: "h1", level: 1, text: "观察动作")]
        )
    }

    @Test func errorAnalyzerSeparatesErrorTypes() {
        let analyzer = ErrorAnalyzer()
        #expect(analyzer.analyzeRelationshipSelection(selected: .increase, mission: mission) == .relationshipReversed)
        #expect(analyzer.analyzeEquationSelection(choice: mission.equationChoices[1]) == .operationSelectionError)
        #expect(analyzer.analyzeEquationSelection(choice: mission.equationChoices[2]) == .equationOrderError)
        #expect(analyzer.analyzeCalculation(answer: 8, mission: mission) == .calculationError)
        #expect(analyzer.analyzeCalculation(answer: 7, mission: mission) == nil)
    }

    @Test @MainActor func normalMissionFlowReachesCompleted() throws {
        let controller = MissionSessionController(mission: mission)
        controller.start()
        controller.advanceFromIntroduction()
        mission.informationItems.forEach { controller.toggleInformation($0.id) }
        try controller.submitInformationSelection()
        controller.selectRelationship(.decrease)
        try controller.enterModelExploration()
        for _ in 0..<5 { controller.removeApple() }
        controller.submitModelExploration()
        controller.selectEquation(id: "correct")
        controller.submitAnswer(7)
        controller.selectReasoning(id: "reason")
        let record = try controller.completeMission(playerID: UUID())
        #expect(controller.phase == .completed)
        #expect(record.removedAppleCount == 5)
        #expect(record.completed)
    }

    @Test @MainActor func incompleteInformationCannotAdvance() {
        let controller = MissionSessionController(mission: mission)
        controller.start(); controller.advanceFromIntroduction()
        #expect(throws: MissionSessionError.incompleteInformationSelection) { try controller.submitInformationSelection() }
    }

    @Test @MainActor func restartClearsSessionState() throws {
        let controller = MissionSessionController(mission: mission)
        controller.start(); controller.advanceFromIntroduction(); controller.toggleInformation("initial"); controller.requestHint(); controller.restartMission()
        #expect(controller.phase == .introduction)
        #expect(controller.selectedInformationIDs.isEmpty)
        #expect(controller.currentHintLevel == 0)
    }
}
