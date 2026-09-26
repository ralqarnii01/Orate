//
//  AnalysisBackend.swift
//  Orate
//
//  Single place to point the app at the speech-analysis backend.
//

import Foundation

enum AnalysisBackend {

    /// Change this one line to move the app between backends.
    ///
    ///   Simulator:        http://localhost:8000
    ///   Physical device:  http://<your Mac's LAN IP>:8000   e.g. http://192.168.1.42:8000
    ///
    /// A physical device also needs the Mac and the phone on the same Wi-Fi,
    /// and iOS will ask once for Local Network permission.
    nonisolated static let baseURL = URL(string: "http://192.168.100.240:8000")!
    
    /// Analysis is CPU-bound on the server: allow a generous timeout.
    nonisolated static let requestTimeout: TimeInterval = 300

    /// How long to wait for AVFoundation to finish writing the recording to
    /// disk before giving up, so the Loading screen can never hang forever.
    nonisolated static let recordingFinalizeTimeout: TimeInterval = 20
}
