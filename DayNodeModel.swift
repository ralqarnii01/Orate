//
//  DayNodeModel.swift
//  Orate
//
//  Created by Areen on 28/02/1448 AH.
//
import Foundation
import SwiftData

@Model
final class DailyResult {
    var id: UUID
    var dayNumber: Int
    var date: Date
    var score: Int
    var feedback: String
    var durationSeconds: Double
    var analysisData: Data?
    
    @MainActor
    init(
        id: UUID = UUID(),
        dayNumber: Int,
        date: Date = Date(),
        score: Int = 0,
        feedback: String = "",
        durationSeconds: Double = 0,
        analysis: AnalysisResponse? = nil
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.date = date
        self.score = score
        self.feedback = feedback
        self.durationSeconds = durationSeconds
        self.analysisData = analysis.flatMap { try? JSONEncoder().encode($0) }
    }

    @MainActor
    var analysisResponse: AnalysisResponse? {
        guard let analysisData else { return nil }
        return try? JSONDecoder().decode(AnalysisResponse.self, from: analysisData)
    }
}

struct StoredPracticeResult: Codable, Identifiable, Equatable {
    var id: UUID
    var dayNumber: Int
    var date: Date
    var score: Int
    var feedback: String
    var durationSeconds: Double
    var analysisData: Data?

    @MainActor
    init(from result: DailyResult) {
        self.id = result.id
        self.dayNumber = result.dayNumber
        self.date = result.date
        self.score = result.score
        self.feedback = result.feedback
        self.durationSeconds = result.durationSeconds
        self.analysisData = result.analysisData
    }

    init(
        id: UUID = UUID(),
        dayNumber: Int,
        date: Date = Date(),
        score: Int,
        feedback: String,
        durationSeconds: Double,
        analysis: AnalysisResponse?
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.date = date
        self.score = score
        self.feedback = feedback
        self.durationSeconds = durationSeconds
        self.analysisData = analysis.flatMap { try? JSONEncoder().encode($0) }
    }

    @MainActor
    var analysisResponse: AnalysisResponse? {
        guard let analysisData else { return nil }
        return try? JSONDecoder().decode(AnalysisResponse.self, from: analysisData)
    }
}

enum PracticeHistoryStore {
    private static let key = "orateSavedPracticeResults"

    @MainActor
    static func load() -> [StoredPracticeResult] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let results = try? JSONDecoder().decode([StoredPracticeResult].self, from: data) else {
            return []
        }

        return results
    }

    @MainActor
    static func save(_ results: [StoredPracticeResult]) {
        guard let data = try? JSONEncoder().encode(results) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    @MainActor
    static func append(_ result: StoredPracticeResult) {
        var results = load()
        guard !results.contains(where: { $0.id == result.id }) else { return }
        results.append(result)
        save(results)
    }

    @MainActor
    static func merged(with swiftDataResults: [DailyResult]) -> [StoredPracticeResult] {
        var merged = load()
        let existingIDs = Set(merged.map(\.id))

        for result in swiftDataResults where !existingIDs.contains(result.id) {
            merged.append(StoredPracticeResult(from: result))
        }

        return merged.sorted { $0.date < $1.date }
    }
}
