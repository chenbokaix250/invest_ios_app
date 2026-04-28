import Foundation

struct RiskAssessmentAgent {
    static let dimension = AgentResult.AnalysisDimension.riskAssessment

    static let systemPrompt = PromptBuilder.expertSystemPrompt(for: dimension)

    static func buildUserPrompt(for stock: Stock, profile: FinnhubService.CompanyProfile?) -> String {
        """
        请分析 \(stock.name)（\(stock.id)）的风险评估。

        公司基本信息：
        - 名称：\(stock.name)
        - 代码：\(stock.id)
        - 交易所：\(stock.exchange)
        - 当前价：$\(String(format: "%.2f", stock.price))
        - 涨跌幅：\(String(format: "%.2f%%", stock.changePercent))

        公司详细信息：\(profile?.description ?? "暂无详细信息")
        行业：\(profile?.industry ?? "暂无")

        请提供专业的风险评估分析。
        """
    }
}
