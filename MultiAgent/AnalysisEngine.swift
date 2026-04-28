import Foundation

@MainActor
class AnalysisEngine: ObservableObject {
    @Published var agentResults: [AgentResult] = []
    @Published var isAnalyzing: Bool = false
    @Published var progress: Double = 0
    @Published var currentAgent: String = ""

    private let miniMaxService: MiniMaxService
    private let finnhubService: FinnhubService

    init(miniMaxService: MiniMaxService = MiniMaxService(),
         finnhubService: FinnhubService = FinnhubService()) {
        self.miniMaxService = miniMaxService
        self.finnhubService = finnhubService
    }

    func analyzeStock(_ stock: Stock) async -> AnalysisReport {
        isAnalyzing = true
        agentResults = []
        progress = 0

        let dimensions = AgentResult.AnalysisDimension.allCases
        for dimension in dimensions {
            agentResults.append(AgentResult(
                agentName: dimension.title,
                dimension: dimension,
                content: "",
                score: nil,
                isCompleted: false
            ))
        }

        async let companyProfile = fetchCompanyData(for: stock.id)

        await withTaskGroup(of: AgentResult.self) { group in
            for dimension in dimensions {
                group.addTask {
                    await self.runExpertAgent(stock: stock, dimension: dimension)
                }
            }

            var completed = 0
            for await result in group {
                if let index = self.agentResults.firstIndex(where: { $0.dimension == result.dimension }) {
                    self.agentResults[index] = result
                }
                completed += 1
                self.progress = Double(completed) / Double(dimensions.count)
            }
        }

        currentAgent = "综合分析中..."
        let synthesis = await runMasterSynthesis(stock: stock)

        isAnalyzing = false
        progress = 1.0

        return synthesis
    }

    private func runExpertAgent(stock: Stock, dimension: AgentResult.AnalysisDimension) async -> AgentResult {
        currentAgent = dimension.title

        let systemPrompt = PromptBuilder.expertSystemPrompt(for: dimension)
        let userPrompt = """
        请分析 \(stock.name)（\(stock.id)）的【\(dimension.title)】。

        公司基本信息：
        - 名称：\(stock.name)
        - 代码：\(stock.id)
        - 交易所：\(stock.exchange)

        当前价格信息：
        - 当前价：$\(String(format: "%.2f", stock.price))
        - 涨跌幅：\(String(format: "%.2f%%", stock.changePercent))

        请提供专业的\(dimension.title)分析。
        """

        do {
            let content = try await miniMaxService.chat(systemPrompt: systemPrompt, userPrompt: userPrompt)
            let score = extractScore(from: content)
            return AgentResult(
                agentName: dimension.title,
                dimension: dimension,
                content: content,
                score: score,
                isCompleted: true
            )
        } catch {
            return AgentResult(
                agentName: dimension.title,
                dimension: dimension,
                content: "分析失败: \(error.localizedDescription)",
                score: 0,
                isCompleted: true,
                error: error.localizedDescription
            )
        }
    }

    private func runMasterSynthesis(stock: Stock) async -> AnalysisReport {
        let systemPrompt = PromptBuilder.masterSystemPrompt
        let userPrompt = PromptBuilder.masterSynthesisPrompt(stock: stock, agentResults: agentResults)

        do {
            let summary = try await miniMaxService.chat(systemPrompt: systemPrompt, userPrompt: userPrompt)
            let totalScore = agentResults.compactMap { $0.score }.reduce(0, +)
            let recommendation = calculateRecommendation(score: totalScore)

            return AnalysisReport(
                stock: stock,
                timestamp: Date(),
                agentResults: agentResults,
                totalScore: totalScore,
                recommendation: recommendation,
                summary: summary
            )
        } catch {
            let totalScore = agentResults.compactMap { $0.score }.reduce(0, +)
            return AnalysisReport(
                stock: stock,
                timestamp: Date(),
                agentResults: agentResults,
                totalScore: totalScore,
                recommendation: calculateRecommendation(score: totalScore),
                summary: "综合分析生成失败"
            )
        }
    }

    private func fetchCompanyData(for symbol: String) async -> FinnhubService.CompanyProfile? {
        do {
            return try await finnhubService.fetchCompanyProfile(symbol: symbol)
        } catch {
            return nil
        }
    }

    private func extractScore(from content: String) -> Int {
        let patterns = ["评分\n", "评分：", "评分:", "\\d分"]
        for pattern in patterns {
            if let range = content.range(of: pattern, options: .regularExpression) {
                let afterMatch = content[range.upperBound...]
                if let digit = afterMatch.first, digit.isNumber {
                    return Int(String(digit)) ?? 0
                }
            }
        }
        return 2
    }

    private func calculateRecommendation(score: Int) -> AnalysisReport.Recommendation {
        switch score {
        case 30...36: return .strongBuy
        case 24...29: return .buy
        case 18...23: return .hold
        case 12...17: return .sell
        default: return .strongSell
        }
    }
}
