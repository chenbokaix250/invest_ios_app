import SwiftUI

struct AnalysisProgressView: View {
    let progress: Double
    let currentAgent: String
    let agentResults: [AgentResult]

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                Text("\(Int(progress * 100))%")
                    .font(.title2.bold())
            }
            .frame(width: 100, height: 100)

            Text("正在分析: \(currentAgent)")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(agentResults) { result in
                    AgentStatusBadge(result: result)
                }
            }
            .padding()
        }
        .padding()
    }
}

struct AgentStatusBadge: View {
    let result: AgentResult

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: result.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(result.isCompleted ? .green : .gray)
            Text(result.dimension.title)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 80, height: 60)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}