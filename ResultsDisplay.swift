//
//  ResultsDisplay.swift
//  Orate
//
//  Adapter between what the backend actually returns and what the existing
//  Results screen draws. Every category -> bar-fill conversion lives in
//  `MetricScale` below so it is easy to find and adjust.
//

import SwiftUI

// MARK: - Category -> bar fill mappings
//
// These are fixed lookup tables, not formulas. The backend reports categories
// ("good", "too_fast", "high", ...); the Results pills draw a bar, so each
// category is pinned to one bar value. Nothing is weighted or averaged.

enum MetricScale {

    /// speech_metrics.pace_rating -> bar fill.
    ///   good      -> 100
    ///   too_slow  ->  40
    ///   too_fast  ->  40
    ///   unknown   -> no bar ("not enough data")
    nonisolated static func fill(forPace pace: PaceRating) -> Int? {
        switch pace {
        case .good: return 100
        case .tooSlow, .tooFast: return 40
        case .unknown: return nil
        }
    }

    nonisolated static func label(forPace pace: PaceRating) -> String? {
        switch pace {
        case .good: return "Good"
        case .tooSlow: return "Too slow"
        case .tooFast: return "Too fast"
        case .unknown: return nil
        }
    }

    /// body_language_metrics.engagement_rating -> bar fill.
    ///   high      -> 100
    ///   moderate  ->  65
    ///   low       ->  30
    nonisolated static func fill(forEngagement engagement: EngagementRating) -> Int {
        switch engagement {
        case .high: return 100
        case .moderate: return 65
        case .low: return 30
        }
    }

    nonisolated static func label(forEngagement engagement: EngagementRating) -> String {
        switch engagement {
        case .high: return "High"
        case .moderate: return "Moderate"
        case .low: return "Low"
        }
    }

    /// Share of speech_metrics.volume_timeline windows the backend rated
    /// "normal". A straight count, not a score.
    /// (Main-actor bound, unlike the pure lookups above, because it reads the
    /// decoded model's `loudness` accessor.)
    static func volumeConsistency(_ timeline: [VolumeWindow]) -> Int? {
        guard !timeline.isEmpty else { return nil }
        let normal = timeline.filter { $0.loudness == .normal }.count
        return Int((Double(normal) / Double(timeline.count) * 100).rounded())
    }
}

// MARK: - Display model

/// Everything the Results screen draws, in the shape the screen draws it.
/// Built either from a backend `AnalysisResponse` or from the existing
/// on-device `AIAnalysisResult` so both callers keep working.
struct ResultsDisplay {

    /// One row of the "Analysis" pill list.
    /// `fill` is nil when the backend could not measure the metric — the row
    /// then renders "Not enough data" instead of a bar and a percentage.
    struct Metric: Identifiable {
        let id = UUID()
        let title: String
        let valueText: String?
        let fill: Int?
        let backgroundColor: Color
        let characterImageName: String
    }

    struct Moment: Identifiable {
        let id: String
        let time: String
        let quote: String?
        let note: String
    }

    var overallScore: Int
    var overallCaption: String
    var metrics: [Metric]
    var summary: String
    var strengthPoints: [String]
    var improvementPoints: [String]
    /// data_quality.notes, shown only when the run was not fully reliable.
    var qualityNotes: [String] = []

    // Section that only the backend can fill.
    var moments: [Moment] = []
    var showsMomentsSection = false
}

// MARK: - Backend response

extension ResultsDisplay {

    private enum MetricLevel {
        case unavailable
        case weak
        case medium
        case excellent
    }

    private nonisolated static func metricLevel(for fill: Int?) -> MetricLevel {
        guard let fill else { return .unavailable }

        switch fill {
        case ..<50:
            return .weak
        case 50..<80:
            return .medium
        default:
            return .excellent
        }
    }

    private nonisolated static func volumeMascot(for fill: Int?) -> String {
        switch metricLevel(for: fill) {
        case .unavailable: return "16"
        case .weak: return "17"
        case .medium: return "14"
        case .excellent: return "18"
        }
    }

    private nonisolated static func paceMascot(for fill: Int?) -> String {
        switch metricLevel(for: fill) {
        case .unavailable: return "34"
        case .weak: return "33"
        case .medium: return "30"
        case .excellent: return "31"
        }
    }

    private nonisolated static func focusMascot(for fill: Int?) -> String {
        switch metricLevel(for: fill) {
        case .unavailable: return "25"
        case .weak: return "24"
        case .medium: return "20"
        case .excellent: return "22"
        }
    }

    init(analysis: AnalysisResponse) {
        let speech = analysis.speechMetrics
        let body = analysis.bodyLanguageMetrics
        let quality = analysis.dataQuality

        // Slot 1 — was "Voice clarity", which the backend has no equivalent for.
        // Relabelled to the share of the recording at a normal loudness.
        let volumeFill = quality.speechReliable
            ? MetricScale.volumeConsistency(speech.volumeTimeline)
            : nil

        // Slot 2 — pace, from pace_rating, with the measured WPM in the title.
        let pace = quality.speechReliable ? speech.pace : .unknown
        let paceFill = MetricScale.fill(forPace: pace)
        let paceTitle = quality.speechReliable && speech.wordsPerMinute > 0
            ? "Speaking pace · \(Int(speech.wordsPerMinute.rounded())) WPM"
            : "Speaking pace"

        // Slot 3 — was "Eye contact". engagement_rating is a head-stability
        // proxy, not verified eye contact, so the label says what it measures.
        let engagement = quality.headReliable ? body.engagement : nil
        let engagementFill = engagement.map(MetricScale.fill(forEngagement:))

        let modelScore = Self.modelOverallScore(from: analysis)
        overallScore = modelScore ?? 0
        overallCaption = Self.scoreCaption(for: modelScore)

        metrics = [
            Metric(
                title: "Volume consistency",
                valueText: volumeFill.map { "\($0)%" },
                fill: volumeFill,
                backgroundColor: AppColors.paleMint,
                characterImageName: Self.volumeMascot(for: volumeFill)
            ),
            Metric(
                title: paceTitle,
                valueText: MetricScale.label(forPace: pace),
                fill: paceFill,
                backgroundColor: AppColors.paleLavender,
                characterImageName: Self.paceMascot(for: paceFill)
            ),
            Metric(
                title: "Focus & steadiness",
                valueText: engagement.map(MetricScale.label(forEngagement:)),
                fill: engagementFill,
                backgroundColor: AppColors.paleYellow,
                characterImageName: Self.focusMascot(for: engagementFill)
            )
        ]

        summary = Self.shortParagraph(from: analysis.feedback.summary)
        strengthPoints = Self.cleanedPoints(from: analysis.feedback.strengths)
        improvementPoints = Self.cleanedPoints(from: analysis.feedback.improvements)
        qualityNotes = quality.overallReliable ? [] : quality.notes

        moments = analysis.feedback.specificTimestamps.map {
            Moment(id: $0.id, time: $0.formattedTime, quote: $0.quote, note: $0.note)
        }
        showsMomentsSection = !moments.isEmpty
    }

    static func computedOverallScore(for analysis: AnalysisResponse) -> Int? {
        modelOverallScore(from: analysis)
    }

    private static func modelOverallScore(from analysis: AnalysisResponse) -> Int? {
        analysis.overallScore.map { min(100, max(0, $0)) }
    }

    private nonisolated static func points(from text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let separators = CharacterSet(charactersIn: ".!?")
        let sentences = trimmed
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return sentences.isEmpty ? [trimmed] : sentences
    }

    private nonisolated static func cleanedPoints(from lines: [String]) -> [String] {
        let points = lines.flatMap(points(from:))
        return points.isEmpty ? ["Not enough data for this session."] : points
    }

    private nonisolated static func shortParagraph(from text: String) -> String {
        let points = points(from: text)
        guard !points.isEmpty else { return "Not enough data for this session." }
        return points.joined(separator: ". ") + "."
    }

    private nonisolated static func scoreCaption(for score: Int?) -> String {
        guard let score else { return "Not enough data" }

        switch score {
        case ..<40:
            return "Give it another try!"
        case 40..<70:
            return "You're getting there!"
        case 70..<85:
            return "Nice progress!"
        default:
            return "Excellent work!"
        }
    }
}

// MARK: - On-device result (existing practice history and previews)

extension ResultsDisplay {

    init(legacy result: AIAnalysisResult) {
        // Unchanged from the values the Results screen computed itself before
        // the backend wiring, so saved on-device results still look the same.
        let totalFillers = result.fillerWords.reduce(0) { $0 + $1.count }
        let clarity = max(0, 100 - (totalFillers * 8))
        let pace = result.speakingPaceWPM > 0
            ? min(100, Int((Double(result.speakingPaceWPM) / 150.0) * 100))
            : 0

        overallScore = result.overallScore
        overallCaption = "Keep it up!"
        metrics = [
            Metric(
                title: "Voice clarity",
                valueText: "\(clarity)%",
                fill: clarity,
                backgroundColor: AppColors.paleMint,
                characterImageName: Self.volumeMascot(for: clarity)
            ),
            Metric(
                title: "Speaking pace",
                valueText: "\(pace)%",
                fill: pace,
                backgroundColor: AppColors.paleLavender,
                characterImageName: Self.paceMascot(for: pace)
            ),
            Metric(
                title: "Eye contact",
                valueText: "\(result.eyeContactScore)%",
                fill: result.eyeContactScore,
                backgroundColor: AppColors.paleYellow,
                characterImageName: Self.focusMascot(for: result.eyeContactScore)
            )
        ]

        summary = Self.shortParagraph(from: result.overallFeedback)
        strengthPoints = Self.points(from: result.strengthsFeedback)
        improvementPoints = Self.points(from: result.growthFeedback)
    }
}
