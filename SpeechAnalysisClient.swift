//
//  SpeechAnalysisClient.swift
//
//  Minimal URLSession multipart upload for POST /analyze, plus a small
//  ObservableObject you can drive a SwiftUI view from.
//

import Foundation
import Combine
// MARK: - Client

struct SpeechAnalysisClient {

    /// Point this at your machine's LAN IP when testing on a physical device.
    /// Change it in one place: `AnalysisBackend.baseURL`.
    let baseURL: URL

    /// Analysis is CPU-bound on the server: allow a generous timeout.
    var requestTimeout: TimeInterval = AnalysisBackend.requestTimeout

    nonisolated init(baseURL: URL = AnalysisBackend.baseURL) {
        self.baseURL = baseURL
    }

    /// Uploads a recorded video and returns the parsed analysis.
    ///
    /// - Parameter fileURL: a local .mp4 or .mov file (200 MB / 5 minutes max).
    func analyze(fileURL: URL) async throws -> AnalysisResponse {
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: baseURL.appendingPathComponent("analyze"))
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        // Copying the video into the multipart body is synchronous file I/O,
        // so keep it off the main actor while the Loading screen animates.
        let bodyFileURL = try await Task.detached(priority: .userInitiated) {
            try Self.makeMultipartBodyFile(
                fileURL: fileURL,
                fieldName: "recording",
                boundary: boundary
            )
        }.value
        defer { try? FileManager.default.removeItem(at: bodyFileURL) }

        let session = URLSession(configuration: .default)
        let data: Data
        let response: URLResponse
        do {
            // Streaming from a file keeps a 200 MB upload off the heap.
            (data, response) = try await session.upload(for: request, fromFile: bodyFileURL)
        } catch {
            throw AnalysisRequestError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AnalysisRequestError.unexpectedStatus(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            if let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) {
                throw AnalysisRequestError.server(
                    statusCode: http.statusCode,
                    code: envelope.error.code,
                    message: envelope.error.message
                )
            }
            throw AnalysisRequestError.unexpectedStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(AnalysisResponse.self, from: data)
        } catch {
            throw AnalysisRequestError.decoding(error)
        }
    }

    /// Writes the multipart body to a temporary file so the whole video is
    /// never held in memory at once.
    private nonisolated static func makeMultipartBodyFile(
        fileURL: URL,
        fieldName: String,
        boundary: String
    ) throws -> URL {
        let filename = fileURL.lastPathComponent
        let mimeType = fileURL.pathExtension.lowercased() == "mov"
            ? "video/quicktime"
            : "video/mp4"

        let bodyURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("upload-\(UUID().uuidString).multipart")
        FileManager.default.createFile(atPath: bodyURL.path, contents: nil, attributes: nil)

        let handle = try FileHandle(forWritingTo: bodyURL)
        defer { try? handle.close() }

        var header = ""
        header += "--\(boundary)\r\n"
        header += "Content-Disposition: form-data; name=\"\(fieldName)\";"
        header += " filename=\"\(filename)\"\r\n"
        header += "Content-Type: \(mimeType)\r\n\r\n"
        try handle.write(contentsOf: Data(header.utf8))

        let input = try FileHandle(forReadingFrom: fileURL)
        defer { try? input.close() }
        while let chunk = try input.read(upToCount: 1 << 20), !chunk.isEmpty {
            try handle.write(contentsOf: chunk)
        }

        try handle.write(contentsOf: Data("\r\n--\(boundary)--\r\n".utf8))
        return bodyURL
    }
}

// MARK: - View model

/// Owns the Recording -> Loading -> Results handoff: it is created once in
/// `MainAppView` and injected as an environment object, so it outlives the
/// camera screen and keeps running while the Loading screen is on screen.
@MainActor
final class SpeechAnalysisViewModel: ObservableObject {

    struct AnalysisFailure: Equatable {
        let message: String
        /// Backend code when there was one, e.g. "no_speech_detected".
        let code: String?
    }

    enum State: Equatable {
        case idle
        case analyzing
        case success(AnalysisResponse)
        case failure(AnalysisFailure)
    }

    @Published private(set) var state: State = .idle

    private let client: SpeechAnalysisClient
    private var uploadTask: Task<Void, Never>?
    private var finalizeWatchdog: Task<Void, Never>?
    /// Kept so "Try again" can re-upload the same file.
    private var recordingURL: URL?
    /// Held only until the recording file lands on disk, because the camera
    /// screen is torn down the moment we navigate to Loading.
    private var recorder: CameraManager?

    init(client: SpeechAnalysisClient = SpeechAnalysisClient()) {
        self.client = client
    }

    /// Enters `.analyzing` immediately and uploads as soon as the recorder
    /// hands over the finished file. Call this *before* stopping the recorder.
    func awaitRecording(from recorder: CameraManager) {
        cancelWork()
        recordingURL = nil
        state = .analyzing

        self.recorder = recorder
        recorder.onRecordingFinished = { [weak self] url in
            Task { @MainActor in self?.recordingFinished(url) }
        }

        finalizeWatchdog = Task { [weak self] in
            let nanoseconds = UInt64(AnalysisBackend.recordingFinalizeTimeout * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.fail("Your recording took too long to save. Please try recording again.")
        }
    }

    /// Uploads a file directly (used by "Try again", and available for tests).
    func analyze(fileURL: URL) {
        recordingURL = fileURL
        startUpload(fileURL: fileURL)
    }

    func retry() {
        guard let url = recordingURL, FileManager.default.fileExists(atPath: url.path) else {
            fail("That recording is no longer available. Please record again.")
            return
        }
        startUpload(fileURL: url)
    }

    /// Clears everything so the next practice session starts from scratch.
    func reset() {
        cancelWork()
        recordingURL = nil
        state = .idle
    }

    // MARK: - Private

    private func recordingFinished(_ url: URL?) {
        // Ignore anything arriving after the watchdog already failed the run.
        guard state == .analyzing, recordingURL == nil else { return }

        finalizeWatchdog?.cancel()
        finalizeWatchdog = nil
        recorder?.onRecordingFinished = nil
        recorder?.stopSession()
        recorder = nil

        guard let url = url else {
            fail("Your practice could not be recorded. Please try again.")
            return
        }

        recordingURL = url
        startUpload(fileURL: url)
    }

    private func startUpload(fileURL: URL) {
        uploadTask?.cancel()
        state = .analyzing

        uploadTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let response = try await self.client.analyze(fileURL: fileURL)
                guard !Task.isCancelled else { return }
                self.state = .success(response)
            } catch let error as AnalysisRequestError {
                guard !Task.isCancelled else { return }
                self.state = .failure(
                    AnalysisFailure(
                        message: error.errorDescription ?? "The analysis could not be completed.",
                        code: error.code
                    )
                )
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .failure(
                    AnalysisFailure(message: error.localizedDescription, code: nil)
                )
            }
        }
    }

    private func fail(_ message: String) {
        cancelWork()
        state = .failure(AnalysisFailure(message: message, code: nil))
    }

    private func cancelWork() {
        uploadTask?.cancel()
        uploadTask = nil
        finalizeWatchdog?.cancel()
        finalizeWatchdog = nil
        recorder?.onRecordingFinished = nil
        recorder = nil
    }
}

// MARK: - Example SwiftUI usage
//
//  struct ResultsView: View {
//      let result: AnalysisResponse
//
//      var body: some View {
//          List {
//              Section("Delivery") {
//                  LabeledContent("Pace",
//                      value: "\(Int(result.speechMetrics.wordsPerMinute)) WPM"
//                             + " (\(result.speechMetrics.paceRating))")
//                  LabeledContent("Pauses", value: "\(result.speechMetrics.pauseCount)")
//              }
//
//              Section("Body language") {
//                  if let rating = result.bodyLanguageMetrics.gestureRating {
//                      LabeledContent("Gestures", value: rating)
//                  } else {
//                      Text("Gestures could not be measured in this recording.")
//                          .foregroundStyle(.secondary)
//                  }
//                  if let quality = result.bodyLanguageMetrics.gestureQuality {
//                      LabeledContent("Gesture quality", value: quality.displayName)
//                  }
//              }
//
//              Section("Summary") { Text(result.feedback.summary) }
//
//              Section("Strengths") {
//                  ForEach(result.feedback.strengths, id: \.self) { Text($0) }
//              }
//
//              Section("Improvements") {
//                  ForEach(result.feedback.improvements, id: \.self) { Text($0) }
//              }
//
//              Section("Moments") {
//                  ForEach(result.feedback.specificTimestamps) { item in
//                      VStack(alignment: .leading, spacing: 4) {
//                          Text(item.formattedTime).font(.caption.monospacedDigit())
//                          if let quote = item.quote {
//                              Text("\u{201C}\(quote)\u{201D}").italic()
//                          }
//                          Text(item.note)
//                      }
//                  }
//              }
//
//              if !result.dataQuality.overallReliable {
//                  Section("About these results") {
//                      ForEach(result.dataQuality.notes, id: \.self) {
//                          Text($0).font(.footnote).foregroundStyle(.secondary)
//                      }
//                  }
//              }
//          }
//      }
//  }
