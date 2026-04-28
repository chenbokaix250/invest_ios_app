import Foundation

struct AgentResult: Identifiable {
    let id = UUID()
    let agentName: String
    let dimension: AnalysisDimension
    let content: String
    let score: Int?         // 0-4 scale
    var isCompleted: Bool = false
    var error: String?

    enum AnalysisDimension: Int, CaseIterable {
        case companyIntro = 1
        case industryTrend = 2
        case financialHealth = 3
        case valuation = 4
        case trading = 5
        case developmentDirection = 6
        case riskAssessment = 7
        case macroEnvironment = 8
        case competitorAnalysis = 9

        var title: String {
            switch self {
            case .companyIntro: return "公司介绍"
            case .industryTrend: return "行业趋势"
            case .financialHealth: return "财务健康"
            case .valuation: return "估值分析"
            case .trading: return "交易情况"
            case .developmentDirection: return "发展方向"
            case .riskAssessment: return "风险评估"
            case .macroEnvironment: return "宏观环境"
            case .competitorAnalysis: return "竞争对手对比"
            }
        }

        var promptGuidance: String {
            switch self {
            case .companyIntro: return "提供公司基本信息、主营业务、市场地位"
            case .industryTrend: return "分析行业发展趋势、市场空间、增长率"
            case .financialHealth: return "分析营收、利润、现金流、负债情况"
            case .valuation: return "分析PE、PB、PS等估值指标是否合理"
            case .trading: return "分析成交量、机构持仓、股东变化"
            case .developmentDirection: return "分析公司战略、新产品、研发投入"
            case .riskAssessment: return "识别主要风险因素"
            case .macroEnvironment: return "分析宏观经济影响"
            case .competitorAnalysis: return "与竞争对手对比分析"
            }
        }
    }
}