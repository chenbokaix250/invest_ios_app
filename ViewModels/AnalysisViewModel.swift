import Foundation

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var currentReport: AnalysisReport?
    @Published var isAnalyzing: Bool = false
    @Published var progress: Double = 0
    @Published var currentAgent: String = ""

    private let analysisEngine = AnalysisEngine()

    init() {
        // Observe analysis engine
        Task {
            for await _ in Timer.publish(every: 0.5, on: .main, in: .common).autoconnect().values {
                self.progress = analysisEngine.progress
                self.currentAgent = analysisEngine.currentAgent
                self.isAnalyzing = analysisEngine.isAnalyzing
            }
        }
    }

    func analyzeStock(_ stock: Stock) async -> AnalysisReport? {
        isAnalyzing = true
        let report = await analysisEngine.analyzeStock(stock)
        currentReport = report
        isAnalyzing = false
        return report
    }

    var agentResults: [AgentResult] {
        analysisEngine.agentResults
    }
}
