//
//  SpeechAnalysisModels.swift
//
//  Codable models matching the backend's POST /analyze response exactly.
//  Drop this file into your SwiftUI project.
//
//  Nullability contract:
//    - Every property declared non-optional here is always present.
//    - Optional properties are the only ones the backend may send as null:
//      overallScore, detectedLanguage, pitchVariationSemitones,
//      loudnessPeakCount, pitchPeakCount, handMovementScore, gestureRating,
//      headStabilityScore, engagementRating, selfTouchRatio,
//      speechAlignedGestureRatio, gestureQualityRating, and
//      TimestampFeedback.quote.
//

import Foundation
import Combine
// MARK: - Top level

struct AnalysisResponse: Codable, Equatable {
    let transcript: String
    let speechMetrics: SpeechMetrics
    let bodyLanguageMetrics: BodyLanguageMetrics
    let feedback: Feedback
    let dataQuality: DataQuality
    /// 0...100 headline score. nil when no modality was reliable enough.
    let overallScore: Int?
    /// Modalities used for scoring, e.g. ["speech", "gesture"].
    let overallScoreBasis: [String]

    enum CodingKeys: String, CodingKey {
        case transcript
        case speechMetrics = "speech_metrics"
        case bodyLanguageMetrics = "body_language_metrics"
        case feedback
        case dataQuality = "data_quality"
        case overallScore = "overall_score"
        case overallScoreBasis = "overall_score_basis"
    }
}

// MARK: - Speech metrics

struct SpeechMetrics: Codable, Equatable {
    let durationSeconds: Double
    let wordsPerMinute: Double
    /// "too_slow" | "good" | "too_fast"
    let paceRating: String
    /// Relative digital loudness in dBFS. NOT calibrated dB SPL.
    let avgVolumeDbfs: Double
    let volumeTimeline: [VolumeWindow]
    let pauseCount: Int
    let longPauses: [PauseSpan]
    let wordCount: Int
    let speechSpanSeconds: Double
    let detectedLanguage: String?
    let loudnessVariationMeasurable: Bool
    let pitchMeasurable: Bool
    let pitchVariationSemitones: Double?
    let loudnessPeakCount: Int?
    let pitchPeakCount: Int?
    let prePhrasePauseCount: Int
    let emphasisEvents: [EmphasisEvent]

    enum CodingKeys: String, CodingKey {
        case durationSeconds = "duration_seconds"
        case wordsPerMinute = "words_per_minute"
        case paceRating = "pace_rating"
        case avgVolumeDbfs = "avg_volume_dbfs"
        case volumeTimeline = "volume_timeline"
        case pauseCount = "pause_count"
        case longPauses = "long_pauses"
        case wordCount = "word_count"
        case speechSpanSeconds = "speech_span_seconds"
        case detectedLanguage = "detected_language"
        case loudnessVariationMeasurable = "loudness_variation_measurable"
        case pitchMeasurable = "pitch_measurable"
        case pitchVariationSemitones = "pitch_variation_semitones"
        case loudnessPeakCount = "loudness_peak_count"
        case pitchPeakCount = "pitch_peak_count"
        case prePhrasePauseCount = "pre_phrase_pause_count"
        case emphasisEvents = "emphasis_events"
    }

    var pace: PaceRating { PaceRating(rawValue: paceRating) ?? .unknown }
}

struct VolumeWindow: Codable, Equatable, Identifiable {
    let start: Double
    let end: Double
    /// "low" | "normal" | "high"
    let level: String

    var id: Double { start }
    var loudness: LoudnessLevel { LoudnessLevel(rawValue: level) ?? .unknown }
}

struct PauseSpan: Codable, Equatable, Identifiable {
    let start: Double
    let end: Double

    var id: Double { start }
    var duration: Double { end - start }
}

struct EmphasisEvent: Codable, Equatable, Identifiable {
    let time: Double
    let kind: String

    var id: String { "\(time)-\(kind)" }
}

// MARK: - Body language metrics

struct BodyLanguageMetrics: Codable, Equatable {
    /// Mean normalised wrist speed in body widths per second. nil when unmeasurable.
    let handMovementScore: Double?
    /// "minimal" | "appropriate" | "excessive", or nil.
    let gestureRating: String?
    /// 0...1, higher means less head movement. A bounded proxy, not a physical unit.
    let headStabilityScore: Double?
    /// "low" | "moderate" | "high", or nil.
    let engagementRating: String?
    let sampledFrames: Int
    let handMovementPeakCount: Int
    let handVisibilityRatio: Double
    let faceVisibilityRatio: Double
    let selfTouchRatio: Double?
    let speechAlignedGestureRatio: Double?
    /// "mostly_purposeful" | "mixed" | "mostly_adaptive", or nil.
    /// A behavioural proxy, not a psychological measurement.
    let gestureQualityRating: String?
    let gestureQualityReliable: Bool

    enum CodingKeys: String, CodingKey {
        case handMovementScore = "hand_movement_score"
        case gestureRating = "gesture_rating"
        case headStabilityScore = "head_stability_score"
        case engagementRating = "engagement_rating"
        case sampledFrames = "sampled_frames"
        case handMovementPeakCount = "hand_movement_peak_count"
        case handVisibilityRatio = "hand_visibility_ratio"
        case faceVisibilityRatio = "face_visibility_ratio"
        case selfTouchRatio = "self_touch_ratio"
        case speechAlignedGestureRatio = "speech_aligned_gesture_ratio"
        case gestureQualityRating = "gesture_quality_rating"
        case gestureQualityReliable = "gesture_quality_reliable"
    }

    var gesture: GestureRating? { gestureRating.flatMap(GestureRating.init(rawValue:)) }
    var engagement: EngagementRating? { engagementRating.flatMap(EngagementRating.init(rawValue:)) }
    var gestureQuality: GestureQualityRating? {
        gestureQualityRating.flatMap(GestureQualityRating.init(rawValue:))
    }
}

// MARK: - Feedback

struct Feedback: Codable, Equatable {
    let summary: String
    let strengths: [String]
    let improvements: [String]
    let specificTimestamps: [TimestampFeedback]

    enum CodingKeys: String, CodingKey {
        case summary, strengths, improvements
        case specificTimestamps = "specific_timestamps"
    }
}

struct TimestampFeedback: Codable, Equatable, Identifiable {
    let time: Double
    /// Verbatim transcript text, or nil when the note is not tied to a quote.
    let quote: String?
    let note: String

    var id: String { "\(time)-\(note.hashValue)" }

    /// "01:23" style label for display next to the note.
    var formattedTime: String {
        let total = Int(time.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

// MARK: - Data quality

struct DataQuality: Codable, Equatable {
    let overallReliable: Bool
    let speechReliable: Bool
    let gestureReliable: Bool
    let headReliable: Bool
    let notes: [String]

    enum CodingKeys: String, CodingKey {
        case overallReliable = "overall_reliable"
        case speechReliable = "speech_reliable"
        case gestureReliable = "gesture_reliable"
        case headReliable = "head_reliable"
        case notes
    }
}

// MARK: - Enum helpers
//
// The backend sends plain strings so that adding a value later cannot break
// decoding. These wrappers give you exhaustive switches in the UI layer.

enum PaceRating: String {
    case tooSlow = "too_slow"
    case good
    case tooFast = "too_fast"
    case unknown
}

enum LoudnessLevel: String {
    case low, normal, high, unknown
}

enum GestureRating: String {
    case minimal, appropriate, excessive
}

enum EngagementRating: String {
    case low, moderate, high
}

enum GestureQualityRating: String {
    case mostlyPurposeful = "mostly_purposeful"
    case mixed
    case mostlyAdaptive = "mostly_adaptive"

    /// Behavioural wording only — never describe this as an emotional state.
    var displayName: String {
        switch self {
        case .mostlyPurposeful: return "Mostly speech-linked gestures"
        case .mixed: return "Mixed gestures"
        case .mostlyAdaptive: return "Frequent self-touching gestures"
        }
    }
}

// MARK: - Errors

/// Matches the backend's error envelope: {"error": {"code", "message", "detail"}}
struct APIErrorEnvelope: Codable, Equatable {
    struct Body: Codable, Equatable {
        let code: String
        let message: String
        let detail: String?
    }

    let error: Body
}

enum AnalysisRequestError: LocalizedError {
    /// The backend rejected the recording with a structured reason.
    case server(statusCode: Int, code: String, message: String)
    /// Non-2xx with an unreadable body.
    case unexpectedStatus(Int)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case let .server(_, _, message):
            return message
        case let .unexpectedStatus(status):
            return "The server returned an unexpected response (\(status))."
        case .decoding:
            return "The analysis result could not be read."
        case let .transport(error):
            return error.localizedDescription
        }
    }

    /// Stable machine-readable code, e.g. "no_speech_detected", "file_too_large".
    var code: String? {
        if case let .server(_, code, _) = self { return code }
        return nil
    }
}
