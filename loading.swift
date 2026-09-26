//
//  loading.swift
//  Orate
//
//  Created by Areen on 21/02/1448 AH.
//
import SwiftUI
import SwiftData

// MARK: - Extension for Hex Color


struct loading: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var analysis: SpeechAnalysisViewModel
    @Environment(\.modelContext) private var modelContext
    @AppStorage("orateWayCurrentDay") private var orateWayCurrentDay = 1
    @AppStorage("orateWayLastUseDayStart") private var orateWayLastUseDayStart = 0.0
    @AppStorage("completedPracticeSessionCount") private var completedPracticeSessionCount = 0
    @AppStorage("completedPracticeTopics") private var completedPracticeTopics = ""
    @AppStorage("weeklyPracticeSeconds") private var weeklyPracticeSeconds = 0.0
    @AppStorage("weeklyPracticeWeekStart") private var weeklyPracticeWeekStart = 0.0
    // 1. إضافة متغير للتحكم بالحركة
    @State private var isLoading = false
    @State private var activeDot = 0
    @State private var hasSavedResult = false

    var body: some View {
        ZStack {
            // 1. لون الخلفية الأساسي
            Color.orateBackground
                .ignoresSafeArea()

            // 2. الدائرة الوردية (أعلى اليمين)
            Circle()
                .fill(Color(hex: "FFD9EE"))
                .frame(width: 300, height: 300)
                .position(x: UIScreen.main.bounds.width - 50, y: 50)

            // النجمة
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "star.fill") // أيقونة نجمة
                        .font(.system(size: 25))
                        .foregroundColor(Color(hex: "FFDE91"))
                        .offset(x: -75, y: 270)
                }
                Spacer()
                // الدائرة الصغيرة اللي تحت
                Circle()
                    .fill(Color(hex: "FFD9EE"))
                    .frame(width: 15, height: 300)
                    .position(x: UIScreen.main.bounds.width - 280, y: 420)
            }

            // 3. الدائرة السماوية (أسفل اليسار)
            Circle()
                .fill(Color(hex: "C3F5F1"))
                .frame(width: 350, height: 350)
                .position(x: 50, y: UIScreen.main.bounds.height - 50)

            // 4. محتوى الشاشة (المجسم والنصوص)
            VStack {
                Spacer()

                Image("9")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(2)

                VStack(spacing: 12) {
                    
                    // 🎯 تم تطبيق خصائص خط Figma بالكامل هنا
                    Text("Analyzing your practice")
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .kerning(-0.21) // Letter spacing -0.75% (28 * -0.0075)
                        .foregroundColor(.orateActiveText)

                    Text("Listening to your voice and analyzing your body language...")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.orateSecondaryText)
                }
                .offset(y: -80)
                .padding(.horizontal, 40)

                // 🔄 مؤشر التحميل المتحرك
                HStack(spacing: 12) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color(hex: "5E64AC"))
                            .frame(width: 12, height: 12)
                            .scaleEffect(dotScale(for: index))
                            .opacity(dotOpacity(for: index))
                            .animation(.easeInOut(duration: 0.28), value: activeDot)
                    }
                }
                .padding(.top, 10)
                .offset(y: -70)
                .onAppear {
                    isLoading = true
                    startLoadingDots()
                }

                Spacer()
            }

            // 5. حالة الخطأ — تظهر بدل شاشة التحميل عند فشل التحليل
            if let message = errorMessage {
                errorOverlay(message: message)
            }
        }
        .ignoresSafeArea()
        .onAppear { handle(analysis.state) }
        .onChange(of: analysis.state) { _, newState in handle(newState) }
    }

    /// Non-nil whenever the Loading screen has nothing left to wait for.
    private var errorMessage: String? {
        switch analysis.state {
        case .failure(let failure):
            return failure.message
        case .idle:
            return "There's no recording to analyze yet."
        case .analyzing, .success:
            return nil
        }
    }

    private func handle(_ state: SpeechAnalysisViewModel.State) {
        switch state {
        case .analyzing:
            hasSavedResult = false

        case .success(let response):
            guard !hasSavedResult else { return }
            hasSavedResult = true
            save(response)
            markCurrentTopicCompleted()
            router.latestAnalysis = response
            router.activePracticeTopicTitle = nil
            router.currentScreen = .result

        case .failure:
            router.activePracticeTopicTitle = nil

        case .idle:
            break
        }
    }

    private func save(_ response: AnalysisResponse) {
        let durationSeconds = response.speechMetrics.durationSeconds
        let resultID = UUID()
        let resultDate = Date()
        let dayNumber = practiceDayNumber(for: resultDate)
        let score = ResultsDisplay.computedOverallScore(for: response) ?? 0
        let result = DailyResult(
            id: resultID,
            dayNumber: dayNumber,
            date: resultDate,
            score: score,
            feedback: response.feedback.summary,
            durationSeconds: durationSeconds,
            analysis: response
        )
        modelContext.insert(result)
        try? modelContext.save()
        PracticeHistoryStore.append(
            StoredPracticeResult(
                id: resultID,
                dayNumber: dayNumber,
                date: resultDate,
                score: score,
                feedback: response.feedback.summary,
                durationSeconds: durationSeconds,
                analysis: response
            )
        )
        updateProgressCounters(durationSeconds: durationSeconds)
    }

    private func markCurrentTopicCompleted() {
        guard let topic = router.activePracticeTopicTitle,
              !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        var topics = Set(completedPracticeTopics.split(separator: "|").map(String.init))
        topics.insert(topic)
        completedPracticeTopics = topics.sorted().joined(separator: "|")
    }

    private func practiceDayNumber(for date: Date) -> Int {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: date).timeIntervalSince1970
        let hasSavedPractice = !PracticeHistoryStore.load().isEmpty

        if !hasSavedPractice {
            orateWayCurrentDay = 1
            orateWayLastUseDayStart = todayStart
            return 1
        }

        if orateWayLastUseDayStart != todayStart {
            orateWayCurrentDay = min(max(orateWayCurrentDay, 1) + 1, 30)
            orateWayLastUseDayStart = todayStart
        }

        return min(max(orateWayCurrentDay, 1), 30)
    }

    private func updateProgressCounters(durationSeconds: Double) {
        completedPracticeSessionCount += 1

        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start
            ?? calendar.startOfDay(for: Date())
        let weekStartValue = weekStart.timeIntervalSince1970

        if weeklyPracticeWeekStart != weekStartValue {
            weeklyPracticeWeekStart = weekStartValue
            weeklyPracticeSeconds = 0
        }

        weeklyPracticeSeconds += max(0, durationSeconds)
    }

    private func dotScale(for index: Int) -> CGFloat {
        if index == activeDot { return 1.55 }
        if index == (activeDot + 2) % 3 { return 1.15 }
        return 0.75
    }

    private func dotOpacity(for index: Int) -> Double {
        if index == activeDot { return 1.0 }
        if index == (activeDot + 2) % 3 { return 0.6 }
        return 0.25
    }

    private func startLoadingDots() {
        Task {
            while isLoading && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 320_000_000)
                await MainActor.run {
                    activeDot = (activeDot + 1) % 3
                }
            }
        }
    }

    private func errorOverlay(message: String) -> some View {
        ZStack {
            Color(hex: "FFFCF6")
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 42))
                    .foregroundColor(Color(hex: "FFDE91"))

                Text("We couldn't analyze your practice")
                    .font(.system(size: 24, weight: .semibold))
                    .kerning(-0.18)
                    .foregroundColor(Color(hex: "505050"))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button(action: { analysis.retry() }) {
                        Text("Try again")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "5E64AC"))
                            .cornerRadius(20)
                    }

                    // The next recording resets the analyzer, so leave the
                    // failure in place here rather than swapping the message
                    // out mid-transition.
                    Button(action: { router.currentScreen = .practice }) {
                        Text("Back to practice")
                            .font(.headline)
                            .foregroundColor(Color(hex: "505050"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 36)
        }
    }
}


#Preview {
    loading()
        .environmentObject(AppRouter())
        .environmentObject(SpeechAnalysisViewModel())
}
