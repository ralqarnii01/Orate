import SwiftUI
import SwiftData

// MARK: - Brand Color Palette
struct AppColors {
    static let background = Color.orateBackground
    static let primaryPurple = Color(hex: "#5E64AC")
    static let mintGreen = Color(hex: "#91DAD8")
    static let softBlue = Color(hex: "#A4A8CF")
    static let warmYellow = Color(hex: "#FFDE91")
    static let softRed = Color(hex: "#FFAFB4")
    static let paleMint = Color(hex: "#C9F1EF")
    static let paleLavender = Color(hex: "#D8DAF0")
    static let paleYellow = Color(hex: "#FFE8AE")
    static let activeText = Color.orateActiveText
    static let inactiveText = Color.orateSecondaryText
    static let primaryText = Color.oratePrimaryText
    static let cardBackground = Color.orateCardBackground
}

// MARK: - Data Models
struct FillerWord: Identifiable {
    let id = UUID()
    let word: String
    let count: Int
}

struct WordReplacement: Identifiable {
    let id = UUID()
    let original: String
    let replacement: String
}

struct AIAnalysisResult {
    var overallScore: Int = 0
    var transcript: String = ""
    var speakingPaceWPM: Int = 0
    var paceFeedback: String = "Pending analysis..."
    var eyeContactScore: Int = 0
    var eyeContactFeedback: String = "Pending analysis..."
    var handMovementScore: Int = 0
    var handMovementFeedback: String = "Pending analysis..."
    var fillerWords: [FillerWord] = []
    var wordReplacements: [WordReplacement] = []
    var overallFeedback: String = "Record a session to receive your personalized coaching feedback."
    
    // Detailed feedback attributes
    var strengthsFeedback: String = "Good volume and foundational delivery."
    var growthFeedback: String = "Focus on reducing filler pauses and maintaining camera engagement."
    var actionableTip: String = "Try pausing for 2 seconds instead of using filler words when transitioning thoughts."
    
    static let mock = AIAnalysisResult(
        overallScore: 88,
        transcript: "Welcome everyone. Today I want to talk about how we can improve our communication skills effectively.",
        speakingPaceWPM: 135,
        paceFeedback: "Optimal pace",
        eyeContactScore: 82,
        eyeContactFeedback: "Maintained high engagement",
        handMovementScore: 75,
        handMovementFeedback: "Natural gestures used",
        fillerWords: [FillerWord(word: "like", count: 3), FillerWord(word: "um", count: 2)],
        wordReplacements: [WordReplacement(original: "good", replacement: "exceptional")],
        overallFeedback: "Your delivery was confident, clear, and easy to follow.",
        strengthsFeedback: "Strong vocal clarity with steady projection. Your speaking rate kept the content engaging without feeling rushed.",
        growthFeedback: "You tend to drop eye contact when organizing your thoughts, reliance on 'like' slightly reduces authority.",
        actionableTip: "Practice intentional 2-second silent pauses between major points instead of vocalizing transition words."
    )
}

// MARK: - Result View
struct Result: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let display: ResultsDisplay
    private let returnsToPreviousScreen: Bool

    /// On-device result (practice history, previews).
    init(result: AIAnalysisResult, returnsToPreviousScreen: Bool = false) {
        self.display = ResultsDisplay(legacy: result)
        self.returnsToPreviousScreen = returnsToPreviousScreen
    }

    /// Decoded backend response from POST /analyze.
    init(analysis: AnalysisResponse, returnsToPreviousScreen: Bool = false) {
        self.display = ResultsDisplay(analysis: analysis)
        self.returnsToPreviousScreen = returnsToPreviousScreen
    }

    // MARK: - Character Positioning & Scaling
    @State private var characterX: CGFloat = 0
    @State private var characterY: CGFloat = 5
    @State private var characterScale: CGFloat = 1.75
    
    var body: some View {
        ZStack {
            // Background Cream Color
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                ZStack {
                    HStack {
                        Button(action: exitResults) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.activeText)
                                .frame(width: 46, height: 46)
                                .background(colorScheme == .dark ? Color.clear : AppColors.cardBackground)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .modifier(ResultCircleButtonStyle(colorScheme: colorScheme))
                        
                        Spacer()
                    }
                    
                    Text("Results")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                }
                .padding(.horizontal, 30)
                .padding(.top, 18)
                .padding(.bottom, 20)
                .background(AppColors.background)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                    
                    // MARK: - Overall Score Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(overallCardStyle)
                        
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Overall")
                                    .font(.system(size: 28, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                
                                Text("\(display.overallScore)")
                                    .font(.system(size: 58, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                if !display.overallCaption.isEmpty {
                                    Text(display.overallCaption)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.top, 24)
                            .padding(.bottom, 24)
                            
                            Spacer()
                            
                            // Top Mascot Asset
                            Image(overallMascotName(for: display.overallScore))
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(1.6)
                                .padding(.bottom, -25 )

                                .scaleEffect(characterScale, anchor: .bottom)
                                .frame(height: 135)
                                .offset(x: characterX, y: characterY)
                        }
                        .padding(.horizontal, 28)

                    }
                    .frame(height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                    
                    // MARK: - Core Metric Pills Header
                    HStack {
                        Text("Analysis")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppColors.activeText)
                        Spacer()
                    }
                    .padding(.top, 4)
                    
                    VStack(spacing: 12) {
                        ForEach(display.metrics) { metric in
                            MetricPillRow(
                                title: metric.title,
                                percentage: metric.fill,
                                valueText: metric.valueText,
                                backgroundColor: metric.backgroundColor,
                                characterImageName: metric.characterImageName
                            )
                        }
                    }
                    
                    // MARK: - Feedback Cards
                    FeedbackCard(
                        title: "Your feedback",
                        icon: "quote.bubble",
                        accentColor: AppColors.primaryPurple
                    ) {
                        Text(display.summary)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.86) : AppColors.inactiveText)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    FeedbackCard(
                        title: "Key strengths",
                        icon: "hand.thumbsup",
                        accentColor: AppColors.mintGreen
                    ) {
                        BulletList(points: display.strengthPoints, bulletColor: AppColors.mintGreen)
                    }

                    FeedbackCard(
                        title: "Areas for growth",
                        icon: "arrow.up.right",
                        accentColor: Color(hex: "#E88134")
                    ) {
                        BulletList(points: display.improvementPoints, bulletColor: Color(hex: "#E88134"))
                    }

                    if !display.qualityNotes.isEmpty {
                        FeedbackCard(
                            title: "Analysis limitations",
                            icon: "info.circle",
                            accentColor: AppColors.softBlue
                        ) {
                            BulletList(points: display.qualityNotes, bulletColor: AppColors.softBlue)
                        }
                    }
                    
                    // MARK: - Moments Section
                    // Takes the "Stronger Words" slot for backend results:
                    // feedback.specific_timestamps.
                    if display.showsMomentsSection {
                        FeedbackCard(
                            title: "Moments",
                            icon: "clock",
                            accentColor: AppColors.mintGreen
                        ) {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(display.moments) { moment in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(moment.time)
                                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                            .foregroundColor(AppColors.mintGreen)

                                        if let quote = moment.quote, !quote.isEmpty {
                                            Text("\"\(quote)\"")
                                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.72) : AppColors.inactiveText)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }

                                        Text(moment.note)
                                            .font(.system(size: 15, weight: .regular, design: .rounded))
                                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.86) : AppColors.primaryText.opacity(0.72))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }


                    // MARK: - Exit Button
                    Button(action: exitResults) {
                        Text("Done")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.primaryPurple)
                            .cornerRadius(20)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    
    
    private func exitResults() {
        if !returnsToPreviousScreen {
            router.currentScreen = .practice
        }
        dismiss()
    }
    
    // Both metric calculations moved into ResultsDisplay so the on-device and
    // backend paths build their pills in the same place.

    private func overallMascotName(for score: Int) -> String {
        switch score {
        case ..<40:
            return "6"
        case 40...70:
            return "9"
        default:
            return "7"
        }
    }

    private var overallCardStyle: AnyShapeStyle {
        guard colorScheme == .dark else {
            return AnyShapeStyle(AppColors.primaryPurple)
        }

        return AnyShapeStyle(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "43487B"),
                    Color(hex: "7C83E1")
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Custom Metric Pill View
struct MetricPillRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    /// nil when the backend could not measure this metric: the row then shows
    /// "Not enough data" instead of a bar, never a 0% bar.
    let percentage: Int?
    let valueText: String?
    let backgroundColor: Color
    let characterImageName: String

    init(
        title: String,
        percentage: Int?,
        valueText: String? = nil,
        backgroundColor: Color,
        characterImageName: String
    ) {
        self.title = title
        self.percentage = percentage
        self.valueText = valueText ?? percentage.map { "\($0)%" }
        self.backgroundColor = backgroundColor
        self.characterImageName = characterImageName
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.6))
                    .frame(width: 48, height: 48)
                
                Image(characterImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .scaleEffect(2.5)
            }
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.92) : AppColors.activeText)
                
                if let percentage = percentage {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill((colorScheme == .dark ? Color.white : AppColors.activeText).opacity(0.16))
                                .frame(height: 7)

                            Capsule()
                                .fill((colorScheme == .dark ? Color.white : AppColors.activeText).opacity(0.58))
                                .frame(width: geo.size.width * CGFloat(min(100, max(0, percentage))) / 100.0, height: 7)
                        }
                    }
                    .frame(height: 7)
                } else {
                    Text("Not enough data")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor((colorScheme == .dark ? Color.white : AppColors.activeText).opacity(0.7))
                }
            }

            Spacer()

            if let valueText = valueText {
                Text(valueText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.92) : AppColors.activeText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(colorScheme == .dark ? AppColors.cardBackground.opacity(0.4) : backgroundColor)
        )
        .modifier(ResultMetricRowStyle(colorScheme: colorScheme))
    }
}

private struct ResultCircleButtonStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.frostGlass(cornerRadius: 23, interactive: true)
        } else {
            content
        }
    }
}

private struct ResultMetricRowStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.frostGlass(cornerRadius: 26)
        } else {
            content
        }
    }
}

// MARK: - Compact Bullet List
struct BulletList: View {
    @Environment(\.colorScheme) private var colorScheme

    let points: [String]
    var bulletColor = AppColors.activeText
    var isEmphasized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(points, id: \.self) { point in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(bulletColor)
                        .frame(width: 5, height: 5)
                        .padding(.top, 7)

                    Text(point)
                        .font(.system(size: 15, weight: isEmphasized ? .medium : .regular, design: .rounded))
                        .foregroundColor(
                            colorScheme == .dark
                            ? Color.white.opacity(isEmphasized ? 0.94 : 0.86)
                            : AppColors.primaryText.opacity(isEmphasized ? 0.82 : 0.7)
                        )
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Feedback Card
struct FeedbackCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let icon: String
    let accentColor: Color
    let content: Content

    init(
        title: String,
        icon: String,
        accentColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 22)

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.96) : AppColors.primaryText.opacity(0.88))

                Spacer()
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(colorScheme == .dark ? Color.white.opacity(0.10) : AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.16) : AppColors.primaryText.opacity(0.06),
                            lineWidth: 1
                        )
                )
        )
        .modifier(ResultFeedbackCardStyle(colorScheme: colorScheme))
    }
}

private struct ResultFeedbackCardStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.frostGlass(cornerRadius: 26)
        } else {
            content
        }
    }
}

// MARK: - Preview
struct Result_Previews: PreviewProvider {
    static var previews: some View {
        Result(result: AIAnalysisResult.mock)
            .environmentObject(AppRouter())
    }
}
