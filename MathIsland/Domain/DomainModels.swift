import Foundation

enum MissionPhase: String, Codable, CaseIterable { case introduction, storyObservation, informationSelection, relationshipDecision, modelExploration, equationSelection, calculation, explanation, reflection, completed }
enum RelationshipType: String, Codable, CaseIterable { case increase, decrease, combine, compare }
enum UnknownPosition: String, Codable { case initial, change, result, part, difference }
enum RepresentationType: String, Codable, Hashable { case objects, numberBlocks, numberLine, barModel, equation }
enum ExplanationMode: String, Codable { case sentenceChoice, sentenceBuilder, voiceRecording, skipped }
enum LearningErrorType: String, Codable, Hashable { case storyMisunderstanding, missedCondition, irrelevantInformationSelected, relationshipReversed, unknownPositionConfusion, operationSelectionError, equationOrderError, calculationError, representationMismatch, explanationIncomplete, guessingBehavior }

struct LearningObjective: Identifiable, Codable, Hashable { let id: String; let title: String; let description: String }
struct StoryCharacter: Identifiable, Codable, Hashable { let id: String; let name: String; let symbol: String }
struct StoryContent: Codable, Hashable { let scene: String; let text: String; let narration: String?; let characters: [StoryCharacter] }
struct QuantityModel: Codable, Hashable { let initial: Int?; let change: Int?; let result: Int?; let unknown: UnknownPosition }
struct RelationshipModel: Codable, Hashable { let type: RelationshipType; let equation: String; let answer: Int }
struct InformationItem: Identifiable, Codable, Hashable { enum Role: String, Codable { case known, question }; let id: String; let text: String; let role: Role }
struct EquationChoice: Identifiable, Codable, Hashable { let id: String; let expression: String; let isCorrect: Bool; let errorType: LearningErrorType? }
struct MissionHint: Identifiable, Codable, Hashable { let id: String; let level: Int; let text: String }
struct ReasoningOption: Identifiable, Codable, Hashable { let id: String; let text: String; let isCorrect: Bool }

struct Mission: Identifiable, Codable, Hashable {
    let id: String
    let schemaVersion: Int
    let title: String
    let chapterID: String
    let grade: Int
    let difficulty: Int
    let learningObjectives: [LearningObjective]
    let story: StoryContent
    let quantities: QuantityModel
    let relationship: RelationshipModel
    let informationItems: [InformationItem]
    let representations: [RepresentationType]
    let equationChoices: [EquationChoice]
    let reasoningOptions: [ReasoningOption]
    let hints: [MissionHint]
}

struct MissionInteraction: Codable, Hashable { let phase: MissionPhase; let action: String; let value: String?; let date: Date }

struct MissionSession: Codable, Hashable {
    let id: UUID
    let missionID: String
    let startedAt: Date
    var completedAt: Date?
    var interactions: [MissionInteraction]
    var firstRelationshipSelection: RelationshipType?
    var finalRelationshipSelection: RelationshipType?
    var firstEquationChoice: String?
    var finalEquationChoice: String?
    var correctionCount: Int
}

struct LearningRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let playerID: UUID
    let missionID: String
    let startedAt: Date
    let completedAt: Date
    let firstRelationshipSelection: RelationshipType?
    let finalRelationshipSelection: RelationshipType?
    let firstEquationChoice: String?
    let finalEquationChoice: String?
    let enteredAnswer: Int?
    let usedHintCount: Int
    let correctionCount: Int
    let removedAppleCount: Int
    let selectedReasoningID: String?
    let errorTypes: Set<LearningErrorType>
    let completed: Bool
}

struct PlayerProfile: Identifiable, Codable, Hashable { let id: UUID; var nickname: String }
struct SkillMastery: Identifiable, Codable, Hashable { let id: UUID; let skillID: String; var contextUnderstanding: Double; var relationshipRecognition: Double; var calculation: Double; var explanation: Double }

enum MissionSessionError: Error, Equatable { case invalidTransition(from: MissionPhase, to: MissionPhase); case incompleteInformationSelection; case relationshipNotSelected; case equationNotSelected; case answerNotSubmitted; case reasoningNotSelected }
