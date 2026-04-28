import Foundation

struct Stock: Identifiable, Codable, Hashable {
    let id: String          // Symbol, e.g., "AAPL"
    let name: String
    let exchange: String    // "NASDAQ", "NYSE", etc.
    var price: Double
    var change: Double
    var changePercent: Double
    var volatility: Volatility?

    var isInWatchlist: Bool = false
    var group: StockGroup = .none

    static let placeholder = Stock(
        id: "AAPL",
        name: "Apple Inc.",
        exchange: "NASDAQ",
        price: 0,
        change: 0,
        changePercent: 0
    )
}

enum StockGroup: String, Codable, CaseIterable {
    case none = "未分组"
    case buy = "买入"
    case watch = "观望"
}
