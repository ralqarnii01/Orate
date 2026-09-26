import SwiftUI
import SwiftData

struct Progress: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.colorScheme) private var colorScheme
    @Query private var savedResults: [DailyResult]
    @AppStorage("userName") private var userName = "Maha"
    @AppStorage("completedPracticeSessionCount") private var completedPracticeSessionCount = 0
    @AppStorage("weeklyPracticeSeconds") private var weeklyPracticeSeconds = 0.0
    @AppStorage("weeklyPracticeWeekStart") private var weeklyPracticeWeekStart = 0.0

    // colors

    private let backgroundColor = Color.orateBackground
    private let purpleColor = Color(hex: "#5E64AC")
    private let pinkColor = Color(hex: "#FFAFB4")
    private let tealColor = Color(hex: "#91DAD8")
    private let yellowColor = Color(hex: "#FFDE91")

    private let activeColor = Color.orateActiveText
    private let inactiveColor = Color.orateSecondaryText
    
    private let improvementTips = [
        DailyTip(
            title: "Pause before key words",
            subtitle: "your ideas will land clearer"
        ),
        DailyTip(
            title: "Start with your main point",
            subtitle: "make your message easy to follow"
        ),
        DailyTip(
            title: "Slow down your first sentence",
            subtitle: "it helps you sound more confident"
        ),
        DailyTip(
            title: "Look at one spot while speaking",
            subtitle: "steady focus improves presence"
        ),
        DailyTip(
            title: "Use shorter sentences",
            subtitle: "simple phrasing keeps listeners with you"
        ),
        DailyTip(
            title: "Breathe before you begin",
            subtitle: "a calm start sets the tone"
        ),
        DailyTip(
            title: "End with one clear idea",
            subtitle: "your audience will remember it better"
        ),
        DailyTip(
            title: "Practice one strong opening",
            subtitle: "first impressions shape the talk"
        ),
        DailyTip(
            title: "Avoid rushing transitions",
            subtitle: "give each idea room to connect"
        ),
        DailyTip(
            title: "Use your hands with purpose",
            subtitle: "small gestures can support your words"
        ),
        DailyTip(
            title: "Record one short answer",
            subtitle: "reviewing yourself builds awareness"
        ),
        DailyTip(
            title: "Replace fillers with silence",
            subtitle: "pauses sound stronger than um or like"
        ),
        DailyTip(
            title: "Say numbers slowly",
            subtitle: "details need extra clarity"
        ),
        DailyTip(
            title: "Keep your shoulders relaxed",
            subtitle: "your body affects your voice"
        ),
        DailyTip(
            title: "Use one example",
            subtitle: "examples make ideas easier to trust"
        ),
        DailyTip(
            title: "Practice your closing line",
            subtitle: "finish with confidence and direction"
        ),
        DailyTip(
            title: "Speak to one listener",
            subtitle: "it makes your tone feel natural"
        ),
        DailyTip(
            title: "Lift your voice at the end",
            subtitle: "avoid fading out on key points"
        ),
        DailyTip(
            title: "Plan three simple points",
            subtitle: "structure reduces hesitation"
        ),
        DailyTip(
            title: "Smile before you speak",
            subtitle: "it can warm up your voice"
        ),
        DailyTip(
            title: "Check your pace",
            subtitle: "clear speech is better than fast speech"
        ),
        DailyTip(
            title: "Make one point at a time",
            subtitle: "focus keeps your message strong"
        ),
        DailyTip(
            title: "Use a quick recap",
            subtitle: "summaries help listeners stay oriented"
        ),
        DailyTip(
            title: "Practice eye contact",
            subtitle: "look up between thoughts"
        ),
        DailyTip(
            title: "Open with context",
            subtitle: "tell people why the topic matters"
        ),
        DailyTip(
            title: "Trim extra details",
            subtitle: "clear talks leave out distractions"
        ),
        DailyTip(
            title: "Emphasize action words",
            subtitle: "energy makes your message easier to feel"
        ),
        DailyTip(
            title: "Use a steady volume",
            subtitle: "consistency helps people follow"
        ),
        DailyTip(
            title: "Practice one hard sentence",
            subtitle: "smooth the part that makes you pause"
        ),
        DailyTip(
            title: "Reset after mistakes",
            subtitle: "pause, breathe, and keep going"
        )
    ]
    
    private var displayName: String {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Maha" : trimmedName
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good morning,"
        case 12..<18:
            return "Good afternoon,"
        default:
            return "Good evening,"
        }
    }
    
    private var dailyTip: DailyTip {
        let day = Calendar.current.component(.day, from: Date())
        let index = (day - 1) % improvementTips.count
        return improvementTips[index]
    }

    private var completedSessionsCount: Int {
        max(savedResults.count, completedPracticeSessionCount)
    }

    private var weeklyPracticeMinutes: Int {
        max(weeklyMinutesFromSavedResults, weeklyMinutesFromCounter)
    }

    private var weeklyMinutesFromSavedResults: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            ?? calendar.startOfDay(for: now)

        let totalSeconds = savedResults
            .filter { $0.date >= weekStart && $0.date <= now }
            .reduce(0.0) { $0 + $1.durationSeconds }

        guard totalSeconds > 0 else { return 0 }
        return max(1, Int((totalSeconds / 60.0).rounded()))
    }

    private var weeklyMinutesFromCounter: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            ?? calendar.startOfDay(for: now)

        guard weeklyPracticeWeekStart == weekStart.timeIntervalSince1970,
              weeklyPracticeSeconds > 0 else {
            return 0
        }

        return max(1, Int((weeklyPracticeSeconds / 60.0).rounded()))
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                // main content

                VStack(alignment: .leading, spacing: 15) {

                    // header section

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(.system(size: 16))
                                .foregroundStyle(inactiveColor)

                            Text(displayName)
                                .font(
                                    .system(
                                        size: 28,
                                        weight: .bold,
                                        design: .serif
                                    )
                                )
                                .foregroundStyle(activeColor)
                        }

                        Spacer()

                        Button {
                            router.currentScreen = .settings
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 23, weight: .regular))
                                .foregroundStyle(colorScheme == .dark ? Color.white : activeColor)
                                .frame(width: 46, height: 46)
                                .background(colorScheme == .dark ? Color.clear : Color.orateCardBackground)
                                .clipShape(Circle())
                        }
                        .modifier(ProgressCircleButtonStyle(colorScheme: colorScheme))
                    }
                    .padding(.top, 18)

                    // purple banner section

                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 38,
                            style: .continuous
                        )
                        .fill(primaryBannerStyle)
                        .frame(height: 266)

                        VStack(alignment: .leading, spacing: 0) {
                            // banner title
                            Text("You're doing\ngreat. Keep\ngoing!")
                                .font(
                                    .system(
                                        size: 35,
                                        weight: .bold,
                                        design: .serif
                                    )
                                )
                                .foregroundStyle(.white)
                                .lineSpacing(-2)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            // start practice button
                            Button {
                                router.currentScreen = .practice
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Start Practice")
                                        .font(
                                            .system(
                                                size: 16,
                                                weight: .semibold
                                            )
                                        )

                                    Image(systemName: "chevron.right")
                                        .font(
                                            .system(
                                                size: 13,
                                                weight: .semibold
                                            )
                                        )
                                }
                                .foregroundStyle(colorScheme == .dark ? Color.white : activeColor)
                                .padding(.horizontal, 20)
                                .frame(height: 47)
                                .background(colorScheme == .dark ? Color.white.opacity(0.18) : Color.orateCardBackground)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .modifier(ProgressCapsuleButtonStyle(colorScheme: colorScheme))
                            .zIndex(1)
                        }
                        .padding(.leading, 30)
                        .padding(.top, 34)
                        .padding(.bottom, 30)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .leading
                        )

                        // brain character image
                        Image("29")
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(3.2)
                            .frame(width: 130, height: 130)
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity,
                                alignment: .bottomTrailing
                            )
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                            .allowsHitTesting(false)
                    }
                    .frame(maxWidth: .infinity)

                    // your progress section-------------------------------

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your progress")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(activeColor)
                        // progress 2 box
                        HStack(spacing: 15) {

                            // completed sessions box
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Completed")
                                    .font(.system(size: 15))
                                    .foregroundStyle(activeColor)

                                Text("\(completedSessionsCount)")
                                    .font(
                                        .system(
                                            size: 36,
                                            weight: .regular
                                        )
                                    )
                                    .foregroundStyle(activeColor)

                                Text("sessions")
                                    .font(.system(size: 14))
                                    .foregroundStyle(activeColor)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 17)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 120,
                                alignment: .leading
                            )
                            .background(progressCardStyle(light: pinkColor, darkStart: "F68F8F", darkEnd: "D19999"))
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 34,
                                    style: .continuous
                                )
                            )

                            // weekly practice minutes box
                            VStack(alignment: .leading, spacing: 2) {
                                Text("This week")
                                    .font(.system(size: 15))
                                    .foregroundStyle(activeColor)

                                Text("\(weeklyPracticeMinutes)")
                                    .font(
                                        .system(
                                            size: 36,
                                            weight: .regular
                                        )
                                    )
                                    .foregroundStyle(activeColor)

                                Text("min practice")
                                    .font(.system(size: 14))
                                    .foregroundStyle(activeColor)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 17)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 120,
                                alignment: .leading
                            )
                            .background(progressCardStyle(light: tealColor, darkStart: "91DAD8", darkEnd: "6AB5B3"))
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 34,
                                    style: .continuous
                                )
                            )
                        }
                    }

                    // improvement tip section

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Improvement tip")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(activeColor)

                        HStack(spacing: 16) {
                            // improvement tip icon
                            ZStack {
                                Circle()
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.18) : Color.orateCardBackground)
                                    .frame(width: 58, height: 58)

                                Image(
                                    systemName: "chart.line.uptrend.xyaxis"
                                )
                                .font(
                                    .system(
                                        size: 21,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(colorScheme == .dark ? Color.white : activeColor)
                            }

                            // improvement tip text
                            VStack(alignment: .leading, spacing: 3) {
                                Text(dailyTip.title)
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(activeColor)
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )

                                Text(dailyTip.subtitle)
                                    .font(.system(size: 14))
                                    .foregroundStyle(activeColor)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 30)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 103,
                            alignment: .leading
                        )
                        .background(progressCardStyle(light: yellowColor, darkStart: "F2CA6C", darkEnd: "DCC898"))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 34,
                                style: .continuous
                            )
                        )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 105)
            }
            .safeAreaInset(edge: .bottom) {
                TypeViewTabBar(activeTab: 0)
                    .padding(.bottom, 12)
            }
        }
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

    private func progressCardStyle(light: Color, darkStart: String, darkEnd: String) -> AnyShapeStyle {
        guard colorScheme == .dark else {
            return AnyShapeStyle(light)
        }

        return AnyShapeStyle(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: darkStart),
                    Color(hex: darkEnd)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

private struct DailyTip {
    let title: String
    let subtitle: String
}

private struct ProgressCircleButtonStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.frostGlass(cornerRadius: 23, interactive: true)
        } else {
            content.shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

private struct ProgressCapsuleButtonStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.frostGlass(cornerRadius: 24, interactive: true)
        } else {
            content
        }
    }
}

#Preview {
    Progress()
        .environmentObject(AppRouter())
}
