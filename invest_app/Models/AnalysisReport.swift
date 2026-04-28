import Foundation

struct AnalysisReport: Identifiable {
    let id = UUID()
    let stock: Stock
    let timestamp: Date
    let agentResults: [AgentResult]
    let totalScore: Int          // 0-36 scale (9 agents × 4 max)
    let recommendation: Recommendation
    let summary: String

    enum Recommendation: String {
        case strongBuy = "强烈买入"
        case buy = "买入"
        case hold = "持有"
        case sell = "卖出"
        case strongSell = "强烈卖出"

        var color: String {
            switch self {
            case .strongBuy: return "green"
            case .buy: return "lightgreen"
            case .hold: return "yellow"
            case .sell: return "orange"
            case .strongSell: return "red"
            }
        }
    }

    var scoreBreakdown: String {
        let maxScore = AgentResult.AnalysisDimension.allCases.count * 4
        return "\(totalScore)/\(maxScore)"
    }
}