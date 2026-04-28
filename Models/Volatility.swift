import Foundation

struct Volatility: Codable, Hashable {
    let oneDay: Double      // Percentage change 1D
    let oneWeek: Double     // Percentage change 1W
    let oneMonth: Double    // Percentage change 1M

    var oneDayFormatted: String { String(format: "%.2f%%", oneDay) }
    var oneWeekFormatted: String { String(format: "%.2f%%", oneWeek) }
    var oneMonthFormatted: String { String(format: "%.2f%%", oneMonth) }
}
