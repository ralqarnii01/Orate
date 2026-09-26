import SwiftUI

struct MainAppView: View {
    @StateObject private var router = AppRouter()
    // Owns the upload to POST /analyze; lives here so it outlives the camera screen.
    @StateObject private var analysis = SpeechAnalysisViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            switch router.currentScreen {
            case .onboarding1, .onboarding2, .profile:
                MainOnboardingView()
                
            case .progress:
                Progress()
                
            case .practice:
                PracticeView()
                
            case .orateWay:
                OrateWay()
                
            case .settings:
                AccountSettingsView()
                
            case .record:
                CameraTutorialView()
                
            case .loading:
                loading()
                
            case .result:
                if let response = router.latestAnalysis {
                    Result(analysis: response)
                } else {
                    Result(result: router.latestResult ?? AIAnalysisResult())
                }
            }
        }
        .onAppear {
            if hasCompletedOnboarding && router.currentScreen == .onboarding1 {
                router.currentScreen = .progress
            }
        }
        .animation(.easeInOut(duration: 0.25), value: router.currentScreen)
        .environmentObject(router)
        .environmentObject(analysis)
    }
}
