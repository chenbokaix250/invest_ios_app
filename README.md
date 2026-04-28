# InvestAI - 智能选股分析 App

> iOS 原生应用，结合 Yahoo Finance 实时数据与 MiniMax 多智能体 AI 分析，为投资决策提供全方位参考。

---

## 功能特性

### 1. 自选股票管理
- **添加股票**：支持 Yahoo Finance 模糊搜索，输入股票代码或名称即可快速查找并添加
- **分组管理**：左滑选择分组（买入/观望），右滑删除
- **波动率追踪**：显示 1D（当日）/1W（一周）/1M（本月）三个维度的价格波动百分比
- **数据刷新**：下拉刷新更新所有股票的实时价格与波动率

### 2. NASDAQ Browsing
- 预置 10 只热门 NASDAQ 股票（AAPL、MSFT、GOOGL、AMZN、NVDA、META、TSLA、AVGO、ORCL、ADBE）
- 实时获取价格与波动率数据
- 一键添加/移除自选

### 3. AI 智能分析
- **多智能体并行**：Master Agent + 9 个专业 Agent 同时工作
- **九维分析覆盖**：
  - 公司简介（CompanyIntroAgent）
  - 行业趋势（IndustryTrendAgent）
  - 财务健康（FinancialHealthAgent）
  - 估值分析（ValuationAgent）
  - 交易信号（TradingAgent）
  - 发展方向（DevelopmentDirectionAgent）
  - 风险评估（RiskAssessmentAgent）
  - 宏观环境（MacroEnvironmentAgent）
  - 竞品分析（CompetitorAnalysisAgent）
- **实时进度展示**：分析过程中显示当前 Agent 进度与已完成结果
- **中文投资报告**：输出结构化中文分析，含综合评分（0-36）与买卖建议

---

## 项目结构

```
invest_ios_app/
├── invest_app.xcodeproj/          # Xcode 项目文件
├── invest_appApp.swift            # SwiftUI App 入口
├── Models/
│   ├── Stock.swift                # 股票数据模型（含分组）
│   ├── Volatility.swift           # 波动率数据模型
│   ├── AgentResult.swift          # Agent 分析结果
│   └── AnalysisReport.swift       # 分析报告模型
├── ViewModels/
│   ├── WatchlistViewModel.swift   # 自选列表状态管理
│   └── AnalysisViewModel.swift    # AI 分析状态管理
├── Views/
│   ├── ContentView.swift           # TabView 主页（自选 + NASDAQ）
│   ├── WatchlistView.swift        # 自选列表页面
│   ├── StockDetailView.swift      # 股票详情页面
│   ├── AnalysisReportView.swift   # AI 分析报告页面
│   └── Components/
│       ├── StockRow.swift         # 股票行组件（1D 波动率）
│       ├── AddStockSheet.swift    # 添加股票搜索页
│       ├── VolatilityCard.swift   # 波动率展示卡片
│       └── AnalysisProgressView.swift # 分析进度弹窗
├── Services/
│   ├── YahooFinanceService.swift  # Yahoo Finance API（价格/波动率/搜索）
│   ├── FinnhubService.swift       # Finnhub API（公司信息）
│   ├── MiniMaxService.swift       # MiniMax M2.7 AI 接口
│   └── APIKeys.swift              # API Key 配置（不提交到 git）
├── MultiAgent/
│   ├── AnalysisEngine.swift       # Master Agent 分析引擎
│   ├── PromptBuilder.swift        # Prompt 构造器
│   └── ExpertAgents/              # 9 个专业 Agent 实现
└── Utilities/
    ├── Constants.swift            # 常量定义
    └── Extensions.swift           # 扩展工具
```

---

## 数据来源

| 数据类型 | 来源 | 说明 |
|---------|------|------|
| 实时价格 | Yahoo Finance Chart API | `/v8/finance/chart/{symbol}` |
| 波动率 | Yahoo Finance 历史数据 | 计算 1D/1W/1M 涨跌幅 |
| 股票搜索 | Yahoo Finance Search API | `/v1/finance/search` |
| 公司信息 | Finnhub API | 需要 `FINNHUB_API_KEY` |
| AI 分析 | MiniMax M2.7 | `api.minimaxi.com/v1/chat/completions` |

---

## 配置说明

### API Key 配置

1. 复制模板文件：
   ```bash
   cp Services/APIKeys.swift.template Services/APIKeys.swift
   ```

2. 编辑 `Services/APIKeys.swift`，填入真实 API Key：
   ```swift
   enum APIKeys {
       static let finnhubAPIKey = "YOUR_FINNHUB_API_KEY"
       static let miniMaxAPIKey = "YOUR_MINIMAX_API_KEY"
   }
   ```

**注意**：`APIKeys.swift` 不会提交到 git（已在 .gitignore 中）

---

## AI 分析评分系统

| 评分范围 | 建议 |
|---------|------|
| 0-12 分 | 谨慎/卖出 |
| 13-24 分 | 持有/观望 |
| 25-36 分 | 买入 |

九个维度各占 0-4 分，满分 36 分。

---

## 开始使用

1. **克隆项目**
   ```bash
   git clone https://github.com/chenbokaix250/invest_ios_app.git
   cd invest_ios_app
   ```

2. **配置 API Key**
   ```bash
   cp Services/APIKeys.swift.template Services/APIKeys.swift
   # 编辑 APIKeys.swift 填入真实 Key
   ```

3. **打开 Xcode**
   ```bash
   open invest_app.xcodeproj
   ```

4. **运行**
   - 选择目标模拟器或真机
   - Cmd + R 构建运行

---

## 版本历史

| 版本 | 更新内容 |
|-----|---------|
| 1.0 | 初始功能：自选列表、NASDAQ 浏览、模糊搜索 |
| 1.1 | 添加分组管理（买入/观望）、滑动操作 |
| 1.2 | 新增 AI 多智能体分析系统（9 Agent 并行） |
| 1.3 | 完善中文报告渲染、Markdown 支持 |
| 1.4 | 自动获取新添加股票的波动率数据 |