
import SwiftUI
import SwiftData

@main
struct OrateApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .preferredColorScheme(preferredColorScheme)
        }
        .modelContainer(for: DailyResult.self)
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case 1:
            return .light
        case 2:
            return .dark
        default:
            return nil
        }
    }
}
