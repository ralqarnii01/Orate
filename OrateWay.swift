import SwiftUI
import SwiftData

// MARK: - Model
struct DayNode: Identifiable {
    let id = UUID()
    let dayNumber: Int
    var isCompleted: Bool
    var results: [StoredPracticeResult]
    var color: Color
    var iconName: String
}

// MARK: - Main View
struct OrateWay: View {
    @EnvironmentObject var router: AppRouter
    
    // استدعام النتائج المحفوظة من SwiftData
    @Query private var savedResults: [DailyResult]
    @State private var storedResults: [StoredPracticeResult] = []
    
    let colors: [Color] = [
        Color(hex:"CAEEEE"),
        Color(hex:"A4A8CF"),
        Color(hex:"FFF2BC"),
        Color(hex:"FFB8B8")
    ]
    
    // بناء الخريطة بناءً على البيانات المحفوظة
    private var days: [DayNode] {
        let allResults = mergedResults

        return (1...30).map { index in
            let dayResults = allResults.filter { $0.dayNumber == index }
            let isCompleted = !dayResults.isEmpty
            
            return DayNode(
                dayNumber: index,
                isCompleted: isCompleted,
                results: dayResults.sorted { $0.date < $1.date },
                color: colors[(index - 1) % colors.count],
                iconName: "hourglass"
            )
        }
    }

    private var mergedResults: [StoredPracticeResult] {
        let swiftDataResults = savedResults.map { StoredPracticeResult(from: $0) }
        let existingIDs = Set(storedResults.map(\.id))
        let missingSwiftDataResults = swiftDataResults.filter { !existingIDs.contains($0.id) }

        return (storedResults + missingSwiftDataResults).sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.orateBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text("Orate Way")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.oratePrimaryText)
                        .padding(.top, 18)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.orateBackground)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        RoadMapLayout(days: days)
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                            .padding(.bottom, 120)
                    }
                }
                
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    TypeViewTabBar(activeTab: 2)
                        .padding(.bottom, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.orateBackground)
                }
            }
        }
        .onAppear {
            storedResults = PracticeHistoryStore.merged(with: savedResults)
        }
        .onChange(of: savedResults.count) { _, _ in
            storedResults = PracticeHistoryStore.merged(with: savedResults)
        }
    }
}

// MARK: - Road Map Layout
struct RoadMapLayout: View {
    let days: [DayNode]
    
    private let itemHeight: CGFloat = 110
    private let circleSize: CGFloat = 85
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let leftX = circleSize / 2
            let rightX = width - (circleSize / 2)
            
            let points: [CGPoint] = days.indices.map { index in
                let isEven = index % 2 == 0
                let x = isEven ? leftX : rightX
                let y = (CGFloat(index) * itemHeight) + (circleSize / 2)
                return CGPoint(x: x, y: y)
            }
            
            ZStack {
                RoadPathShape(points: points)
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 44, lineCap: .round, lineJoin: .round))
                
                RoadPathShape(points: points)
                    .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 8]))
                
                ForEach(days.indices, id: \.self) { index in
                    NodeCircleView(node: days[index], circleSize: circleSize)
                        .position(points[index])
                }
            }
        }
        .frame(height: CGFloat(days.count) * itemHeight)
    }
}

// MARK: - Custom Path Shape
struct RoadPathShape: Shape {
    let points: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let firstPoint = points.first else { return path }
        
        path.move(to: firstPoint)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        return path
    }
}

// MARK: - Circle View Component
struct NodeCircleView: View {
    let node: DayNode
    let circleSize: CGFloat
    
    var body: some View {
        NavigationLink(destination: Group {
            if node.results.count > 1 {
                DayResultsListView(results: node.results, dayNumber: node.dayNumber)
            } else if let analysis = node.results.first?.analysisResponse {
                Result(analysis: analysis, returnsToPreviousScreen: true)
            } else if let result = node.results.first {
                Result(
                    result: AIAnalysisResult(overallScore: result.score, overallFeedback: result.feedback),
                    returnsToPreviousScreen: true
                )
            }
        }) {
            VStack(spacing: 2) {
                Image(systemName: node.isCompleted ? "flame.fill" : node.iconName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(node.isCompleted ? Color.oratePrimaryText.opacity(0.85) : Color.orateSecondaryText)
                
                Text("Day \(node.dayNumber)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(node.isCompleted ? Color.oratePrimaryText.opacity(0.85) : Color.orateSecondaryText)
            }
            .frame(width: circleSize, height: circleSize)
            .background(node.color)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .disabled(!node.isCompleted)
    }
}

// MARK: - Preview
#Preview {
    OrateWay()
        .environmentObject(AppRouter())
}
