import Foundation
import Observation

protocol ErrorAnalyzing {
    func analyzeRelationshipSelection(selected: RelationshipType, mission: Mission) -> LearningErrorType?
    func analyzeEquationSelection(choice: EquationChoice) -> LearningErrorType?
    func analyzeCalculation(answer: Int, mission: Mission) -> LearningErrorType?
}

struct ErrorAnalyzer: ErrorAnalyzing {
    func analyzeRelationshipSelection(selected: RelationshipType, mission: Mission) -> LearningErrorType? { selected == mission.relationship.type ? nil : .relationshipReversed }
    func analyzeEquationSelection(choice: EquationChoice) -> LearningErrorType? { choice.isCorrect ? nil : choice.errorType ?? .operationSelectionError }
    func analyzeCalculation(answer: Int, mission: Mission) -> LearningErrorType? { answer == mission.relationship.answer ? nil : .calculationError }
}

@Observable @MainActor final class MissionSessionController {
    private(set) var mission: Mission
    private(set) var phase: MissionPhase = .introduction
    private(set) var session: MissionSession
    private(set) var selectedInformationIDs: Set<String> = []
    private(set) var selectedRelationship: RelationshipType?
    private(set) var selectedEquationID: String?
    private(set) var enteredAnswer: Int?
    private(set) var selectedReasoningID: String?
    private(set) var currentHintLevel = 0
    private(set) var errorTypes: Set<LearningErrorType> = []
    private(set) var removedAppleCount = 0
    private let analyzer: ErrorAnalyzing

    init(mission: Mission, analyzer: ErrorAnalyzing = ErrorAnalyzer()) {
        self.mission = mission; self.analyzer = analyzer
        self.session = MissionSession(id: UUID(), missionID: mission.id, startedAt: Date(), completedAt: nil, interactions: [], firstRelationshipSelection: nil, finalRelationshipSelection: nil, firstEquationChoice: nil, finalEquationChoice: nil, correctionCount: 0)
    }

    func start() { phase = .storyObservation; log("start") }
    func advanceFromIntroduction() { if phase == .introduction { start() } else if phase == .storyObservation { phase = .informationSelection; log("observe") } }
    func toggleInformation(_ id: String) { selectedInformationIDs.formSymmetricDifference([id]); log("information", id) }
    func submitInformationSelection() throws {
        guard phase == .informationSelection else { throw MissionSessionError.invalidTransition(from: phase, to: .relationshipDecision) }
        let required = Set(mission.informationItems.map(\.id)); guard selectedInformationIDs == required else { errorTypes.insert(.missedCondition); throw MissionSessionError.incompleteInformationSelection }
        phase = .relationshipDecision
    }
    func selectRelationship(_ relationship: RelationshipType) {
        if session.firstRelationshipSelection == nil { session.firstRelationshipSelection = relationship } else if selectedRelationship != relationship { session.correctionCount += 1 }
        selectedRelationship = relationship; session.finalRelationshipSelection = relationship
        if let error = analyzer.analyzeRelationshipSelection(selected: relationship, mission: mission) { errorTypes.insert(error) }
        log("relationship", relationship.rawValue)
    }
    func enterModelExploration() throws { guard selectedRelationship == mission.relationship.type else { throw MissionSessionError.relationshipNotSelected }; phase = .modelExploration }
    func removeApple() { guard removedAppleCount < (mission.quantities.initial ?? 0) else { return }; removedAppleCount += 1; log("removeApple", "\(removedAppleCount)") }
    func restoreApple() { guard removedAppleCount > 0 else { return }; removedAppleCount -= 1; log("restoreApple", "\(removedAppleCount)") }
    func submitModelExploration() { if removedAppleCount == mission.quantities.change { phase = .equationSelection } else { errorTypes.insert(.representationMismatch) } }
    func selectEquation(id: String) {
        guard let choice = mission.equationChoices.first(where: { $0.id == id }) else { return }
        if session.firstEquationChoice == nil { session.firstEquationChoice = choice.expression } else if selectedEquationID != id { session.correctionCount += 1 }
        selectedEquationID = id; session.finalEquationChoice = choice.expression
        if let error = analyzer.analyzeEquationSelection(choice: choice) { errorTypes.insert(error) }
        if choice.isCorrect { phase = .calculation }; log("equation", choice.expression)
    }
    func submitAnswer(_ answer: Int) { enteredAnswer = answer; if let error = analyzer.analyzeCalculation(answer: answer, mission: mission) { errorTypes.insert(error) } else { phase = .explanation }; log("answer", "\(answer)") }
    func selectReasoning(id: String) {
        selectedReasoningID = id
        guard let option = mission.reasoningOptions.first(where: { $0.id == id }) else { return }
        if option.isCorrect { phase = .reflection } else { errorTypes.insert(.explanationIncomplete) }
        log("reasoning", id)
    }
    func requestHint() { currentHintLevel = min(currentHintLevel + 1, mission.hints.count); log("hint", "\(currentHintLevel)") }
    func completeMission(playerID: UUID) throws -> LearningRecord {
        guard phase == .reflection else { throw MissionSessionError.invalidTransition(from: phase, to: .completed) }
        phase = .completed; session.completedAt = Date()
        return LearningRecord(id: UUID(), playerID: playerID, missionID: mission.id, startedAt: session.startedAt, completedAt: session.completedAt ?? Date(), firstRelationshipSelection: session.firstRelationshipSelection, finalRelationshipSelection: session.finalRelationshipSelection, firstEquationChoice: session.firstEquationChoice, finalEquationChoice: session.finalEquationChoice, enteredAnswer: enteredAnswer, usedHintCount: currentHintLevel, correctionCount: session.correctionCount, removedAppleCount: removedAppleCount, selectedReasoningID: selectedReasoningID, errorTypes: errorTypes, completed: true)
    }
    func restartMission() { phase = .introduction; selectedInformationIDs = []; selectedRelationship = nil; selectedEquationID = nil; enteredAnswer = nil; selectedReasoningID = nil; currentHintLevel = 0; errorTypes = []; removedAppleCount = 0; session = MissionSession(id: UUID(), missionID: mission.id, startedAt: Date(), completedAt: nil, interactions: [], firstRelationshipSelection: nil, finalRelationshipSelection: nil, firstEquationChoice: nil, finalEquationChoice: nil, correctionCount: 0) }
    var currentHint: String? { guard currentHintLevel > 0 else { return nil }; return mission.hints.sorted { $0.level < $1.level }[currentHintLevel - 1].text }
    private func log(_ action: String, _ value: String? = nil) { session.interactions.append(.init(phase: phase, action: action, value: value, date: Date())) }
}

struct ParentReportGenerator {
    func summary(for record: LearningRecord) -> String {
        if record.errorTypes.isEmpty { return "她能够独立理解拿走后数量变少，并正确选择减法和说明理由。" }
        if record.errorTypes.contains(.relationshipReversed) { return "她最终理解了拿走后数量变少，但情境与运算关系仍需要巩固。能够自行修正，说明已经开始形成检查习惯。" }
        if record.errorTypes.contains(.calculationError) { return "她已经建立了正确算式，困难主要出现在计算环节。建议保留苹果或数轴辅助计算。" }
        return "她最终完成了调查。错误主要集中在建模或表达过程，建议通过实物操作后再说出理由。"
    }
}
