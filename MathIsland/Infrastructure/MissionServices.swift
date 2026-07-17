import Foundation
import SwiftData

protocol MissionContentLoading {
    func loadMission(id: String) throws -> Mission
    func loadAllMissions() throws -> [Mission]
}

enum MissionContentError: LocalizedError {
    case fileNotFound(String)
    case unreadable(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let id):
            L10n.format("content.fileNotFoundFormat", id)
        case .unreadable(let id):
            L10n.format("content.unreadableFormat", id)
        case .decodingFailed(let message):
            L10n.format("content.decodingFailedFormat", message)
        }
    }
}

final class MissionContentLoader: MissionContentLoading {
    private let bundle: Bundle
    init(bundle: Bundle = .main) { self.bundle = bundle }

    func loadMission(id: String) throws -> Mission {
        let url = bundle.url(forResource: id, withExtension: "json", subdirectory: "Missions")
            ?? bundle.url(forResource: id, withExtension: "json")
        guard let url else { throw MissionContentError.fileNotFound(id) }
        guard let data = try? Data(contentsOf: url) else { throw MissionContentError.unreadable(id) }
        do {
            return try JSONDecoder().decode(Mission.self, from: data)
        } catch {
            throw MissionContentError.decodingFailed(error.localizedDescription)
        }
    }

    func loadAllMissions() throws -> [Mission] {
        [try loadMission(id: "apple_decrease_result_001")]
    }
}

@Model final class PlayerProfileEntity {
    @Attribute(.unique) var id: UUID
    var nickname: String

    init(id: UUID = UUID(), nickname: String = L10n.text("player.defaultNickname")) {
        self.id = id
        self.nickname = nickname
    }
}

@Model final class LearningRecordEntity {
    @Attribute(.unique) var id: UUID
    var playerID: UUID
    var missionID: String
    var payload: Data
    var completedAt: Date

    init(record: LearningRecord) throws {
        id = record.id
        playerID = record.playerID
        missionID = record.missionID
        payload = try JSONEncoder().encode(record)
        completedAt = record.completedAt
    }

    func domainValue() throws -> LearningRecord {
        try JSONDecoder().decode(LearningRecord.self, from: payload)
    }
}

@Model final class SkillMasteryEntity {
    @Attribute(.unique) var id: UUID
    var skillID: String
    var payload: Data

    init(value: SkillMastery) throws {
        id = value.id
        skillID = value.skillID
        payload = try JSONEncoder().encode(value)
    }
}

protocol LearningRecordRepository {
    func save(_ record: LearningRecord) throws
    func records(for playerID: UUID) throws -> [LearningRecord]
    func latestRecord(for missionID: String) throws -> LearningRecord?
}

@MainActor final class SwiftDataLearningRecordRepository: LearningRecordRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func save(_ record: LearningRecord) throws {
        context.insert(try LearningRecordEntity(record: record))
        try context.save()
    }

    func records(for playerID: UUID) throws -> [LearningRecord] {
        let all = try context.fetch(FetchDescriptor<LearningRecordEntity>(sortBy: [SortDescriptor(\.completedAt, order: .reverse)]))
        return try all.filter { $0.playerID == playerID }.map { try $0.domainValue() }
    }

    func latestRecord(for missionID: String) throws -> LearningRecord? {
        let all = try context.fetch(FetchDescriptor<LearningRecordEntity>(sortBy: [SortDescriptor(\.completedAt, order: .reverse)]))
        return try all.first(where: { $0.missionID == missionID })?.domainValue()
    }
}

protocol AudioRecordingService {
    func start() throws
    func stop() throws -> URL?
}

final class LocalAudioRecordingService: AudioRecordingService {
    func start() throws {}
    func stop() throws -> URL? { nil }
}