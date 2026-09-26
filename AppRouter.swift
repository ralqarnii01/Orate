//
//  AppRouter.swift
//  Orate
//
//  Created by Niroz on 22/02/1448 AH.
//

import SwiftUI
import Combine

class AppRouter: ObservableObject {
    @Published var currentScreen: AppScreen
    
    // This new variable will hold the real speech data once a recording finishes
    @Published var latestResult: AIAnalysisResult?

    // The decoded POST /analyze response for the session just recorded.
    @Published var latestAnalysis: AnalysisResponse?

    // Practice Plan topic selected for the current recording. It is marked
    // complete only after a successful backend analysis.
    @Published var activePracticeTopicTitle: String?

    init() {
        currentScreen = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            ? .progress
            : .onboarding1
    }
}

enum AppScreen {
    case onboarding1
    case onboarding2
    case profile
    case progress
    case practice
    case orateWay
    case settings
    case record
    case loading
    case result
}
