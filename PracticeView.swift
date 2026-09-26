import SwiftUI

struct PracticeView: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("completedPracticeTopics") private var completedPracticeTopics = ""
    @AppStorage("hasSeenPrivacyNotice") private var hasSeenPrivacyNotice = false
    @State private var showPrivacyNotice = false
    @State private var pendingNavigationTopic: String? = nil
    
    // colors
    private let backgroundColor = Color.orateBackground
    private let purpleColor = Color(hex: "#5E64AC")
    private let yellowColor = Color(hex: "#FFDE91")
    private let completedColor = Color(hex: "#91DAD8")
    private let activeColor = Color.orateActiveText
    private let inactiveColor = Color.orateSecondaryText
    
    private let practiceTopics = [
        PracticeTopic(
            title: "Talk about your day",
            description: "Share what happened and how it felt"
        ),
        PracticeTopic(
            title: "Explain a simple idea",
            description: "Make it clear with one example"
        ),
        PracticeTopic(
            title: "Share a recent challenge",
            description: "Describe what happened and what helped"
        ),
        PracticeTopic(
            title: "Give your opinion",
            description: "Share your view and why it matters"
        ),
        PracticeTopic(
            title: "Tell a short story",
            description: "Use a clear beginning, middle, and end"
        ),
        PracticeTopic(
            title: "Teach a quick tip",
            description: "Break it into simple steps"
        ),
        PracticeTopic(
            title: "Describe something you like",
            description: "Say what it is and why you like it"
        ),
        PracticeTopic(
            title: "Reflect on a goal",
            description: "Share your goal and your next step"
        )
    ]
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                // fixed header section
                headerSection
                    .padding(.horizontal, 30)
                    .padding(.top, 18)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // purple banner section
                        ZStack {
                            RoundedRectangle(
                                cornerRadius: 38,
                                style: .continuous
                            )
                            .fill(primaryBannerStyle)
                            .frame(height: 212)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Practice your\nown topic")
                                    .font(
                                        .system(
                                            size: 34,
                                            weight: .bold,
                                            design: .serif
                                        )
                                    )
                                    .foregroundStyle(.white)
                                    .lineSpacing(0)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                                
                                Button {
                                    openRecord(topicTitle: nil)
                                } label: {
                                    HStack(spacing: 14) {
                                        Text("Start")
                                            .font(.system(size: 18, weight: .medium))
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundStyle(activeColor)
                                    .padding(.horizontal, 31)
                                    .frame(height: 51)
                                    .background(yellowColor)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.leading, 31)
                            .padding(.top, 28)
                            .padding(.bottom, 26)
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity,
                                alignment: .leading
                            )
                            
                            // mascot image
                            Image("12")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 142, height: 142)
                                .scaleEffect(3.4)
                                .clipped()
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: .infinity,
                                    alignment: .bottomTrailing
                                )
                                .padding(.trailing, 10)
                                .padding(.bottom, 10)
                                .allowsHitTesting(false)
                        }
                        
                        // today's practice section
                        VStack(alignment: .leading, spacing: 17) {
                            Text("Practice Plan")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(activeColor)
                            
                            VStack(spacing: 14) {
                                ForEach(practiceTopics) { topic in
                                    practiceTopicButton(
                                        topic: topic,
                                        isCompleted: completedTopicSet.contains(topic.title)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 170)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                TypeViewTabBar(activeTab: 1)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
            }
            
            if showPrivacyNotice {
                privacyNoticeOverlay
            }
        }
    }
    
    private var headerSection: some View {
        Text("Practice")
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(Color.oratePrimaryText)
            .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var privacyNoticeOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .transition(.opacity)
            
            VStack(spacing: 20) {
                Text("Privacy Notice")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.96) : Color.oratePrimaryText)
                
                Text("Your recordings are entirely private. All video and audio analysis is processed and stored locally on your device. Nothing is uploaded or saved on our servers.")
                    .font(.system(size: 14))
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.74) : Color.orateSecondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button {
                    hasSeenPrivacyNotice = true
                    showPrivacyNotice = false
                    router.activePracticeTopicTitle = pendingNavigationTopic
                    router.currentScreen = .record
                } label: {
                    Text("Continue")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.oratePrimaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(colorScheme == .dark ? Color.white.opacity(0.18) : Color.orateMutedButtonBackground)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .background(colorScheme == .dark ? Color.white.opacity(0.10) : Color.orateCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .modifier(PrivacyNoticeCardStyle(colorScheme: colorScheme))
            .padding(.horizontal, 44)
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.easeInOut(duration: 0.2), value: showPrivacyNotice)
    }
    
    private var completedTopicSet: Set<String> {
        Set(completedPracticeTopics.split(separator: "|").map(String.init))
    }

    private var primaryBannerStyle: AnyShapeStyle {
        guard colorScheme == .dark else {
            return AnyShapeStyle(purpleColor)
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

    private func openRecord(topicTitle: String?) {
        if hasSeenPrivacyNotice {
            router.activePracticeTopicTitle = topicTitle
            router.currentScreen = .record
        } else {
            pendingNavigationTopic = topicTitle
            showPrivacyNotice = true
        }
    }
    
    private func practiceTopicButton(topic: PracticeTopic, isCompleted: Bool) -> some View {
        Button {
            openRecord(topicTitle: topic.title)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.title)
                        .font(.system(size: 17))
                        .foregroundStyle(Color.oratePrimaryText)
                    
                    Text(topic.description)
                        .font(.system(size: 13))
                        .foregroundStyle(inactiveColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: isCompleted ? 20 : 16, weight: .semibold))
                    .foregroundStyle(isCompleted ? completedColor : activeColor)
            }
            .padding(.leading, 32)
            .padding(.trailing, 29)
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(
                Group {
                    if colorScheme == .dark {
                        Color.clear
                    } else {
                        Color.orateCardBackground
                    }
                }
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
            )
            .modifier(PracticeTopicCardStyle(colorScheme: colorScheme))
        }
        .buttonStyle(.plain)
    }
}

private struct PracticeTopicCardStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.frostGlass(cornerRadius: 30)
        } else {
            content.shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
        }
    }
}

private struct PrivacyNoticeCardStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.frostGlass(cornerRadius: 24)
        } else {
            content
        }
    }
}

private struct PracticeTopic: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}

#Preview {
    PracticeView()
        .environmentObject(AppRouter())
}
