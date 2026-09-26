//
//  DayResultsListView.swift
//  Orate
//
//  Created by Areen on 28/02/1448 AH.
//
// MARK: - List View for Multiple Results
import SwiftUI

struct DayResultsListView: View {
    @Environment(\.colorScheme) private var colorScheme

    let results: [StoredPracticeResult]
    let dayNumber: Int
    
    private let backgroundColor = Color.orateBackground
    private let activeColor = Color.orateActiveText
    private let inactiveColor = Color.orateSecondaryText
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            GeometryReader { proxy in
                Image("orate")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260)
                    .scaleEffect(2.3)
                    .offset(x: proxy.size.width - 110, y: proxy.size.height * 0.10)

                Image("cloud")
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(90))
                    .frame(width: 230)
                    .scaleEffect(2.7)
                    .offset(x: -100, y: proxy.size.height * 0.62)
            }
            .ignoresSafeArea()
            .zIndex(0)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Day \(dayNumber) Results")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.oratePrimaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 6)
                    
                    ForEach(Array(results.enumerated()), id: \.offset) { index, item in
                        NavigationLink(destination: resultDestination(for: item)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Attempt \(index + 1)")
                                        .font(.system(size: 17))
                                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.92) : .oratePrimaryText)
                                    
                                    Text(item.date.formatted(date: .omitted, time: .shortened))
                                        .font(.system(size: 13))
                                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.62) : inactiveColor)
                                        .lineLimit(1)
                                }
                                
                                Spacer()

                                Text("\(item.score)%")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.9) : activeColor)
                                    .frame(width: 44, alignment: .trailing)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.78) : activeColor)
                            }
                            .padding(.leading, 32)
                            .padding(.trailing, 29)
                            .frame(maxWidth: .infinity)
                            .frame(height: 88)
                            .background(colorScheme == .dark ? Color.white.opacity(0.10) : Color.orateCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                            .modifier(DayResultRowStyle(colorScheme: colorScheme))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
            .zIndex(1)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func resultDestination(for item: StoredPracticeResult) -> some View {
        if let analysis = item.analysisResponse {
            Result(analysis: analysis, returnsToPreviousScreen: true)
        } else {
            Result(
                result: AIAnalysisResult(overallScore: item.score, overallFeedback: item.feedback),
                returnsToPreviousScreen: true
            )
        }
    }
}

private struct DayResultRowStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.frostGlass(cornerRadius: 30)
        } else {
            content.shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
        }
    }
}

#Preview {
    NavigationStack {
        DayResultsListView(
            results: [
                StoredPracticeResult(dayNumber: 5, score: 82, feedback: "Good pacing and clear delivery.", durationSeconds: 60, analysis: nil),
                StoredPracticeResult(dayNumber: 5, score: 64, feedback: "Try adding more pauses.", durationSeconds: 45, analysis: nil),
                StoredPracticeResult(dayNumber: 5, score: 91, feedback: "Strong confidence and steady voice.", durationSeconds: 90, analysis: nil)
            ],
            dayNumber: 5
        )
    }
}
