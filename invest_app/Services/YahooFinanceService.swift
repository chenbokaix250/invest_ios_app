import Foundation

actor YahooFinanceService {
    private let baseURL = "https://query1.finance.yahoo.com/v8/finance"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func fetchQuote(symbol: String) async throws -> Stock {
        let url = URL(string: "\(baseURL)/chart/\(symbol)?interval=1d&range=1d")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let chart = json["chart"] as? [String: Any],
           let result = chart["result"] as? [[String: Any]],
           let firstResult = result.first {

            let meta = firstResult["meta"] as? [String: Any] ?? [:]

            let symbolName = meta["shortName"] as? String ?? meta["symbol"] as? String ?? symbol
            let exchange = meta["exchangeName"] as? String ?? "NASDAQ"
            let price = meta["regularMarketPrice"] as? Double ?? 0
            let previousClose = meta["chartPreviousClose"] as? Double ?? (meta["previousClose"] as? Double) ?? price
            let change = price - previousClose
            let changePercent = previousClose > 0 ? (change / previousClose) * 100 : 0

            #if DEBUG
            print("📊 [\(symbol)] Price: \(price), Previous: \(previousClose), Change: \(changePercent)%")
            #endif

            return Stock(
                id: symbol,
                name: symbolName,
                exchange: exchange,
                price: price,
                change: change,
                changePercent: changePercent
            )
        }

        return Stock(
            id: symbol,
            name: symbol,
            exchange: "NASDAQ",
            price: 0,
            change: 0,
            changePercent: 0
        )
    }

    func fetchVolatility(symbol: String) async throws -> Volatility {
        // Fetch 1 month of daily data
        let url = URL(string: "\(baseURL)/chart/\(symbol)?interval=1d&range=1mo")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let chart = json["chart"] as? [String: Any],
           let result = chart["result"] as? [[String: Any]],
           let firstResult = result.first,
           let quotes = firstResult["indicators"] as? [String: Any],
           let quote = quotes["quote"] as? [[String: Any]],
           let firstQuote = quote.first,
           let closes = firstQuote["close"] as? [Double],
           !closes.isEmpty {

            // Filter out nil/zero values
            var validCloses: [Double] = []
            for close in closes {
                if close > 0 {
                    validCloses.append(close)
                }
            }

            let count = validCloses.count
            guard count >= 2 else {
                #if DEBUG
                print("📈 [\(symbol)] Not enough data points: \(count)")
                #endif
                return Volatility(oneDay: 0, oneWeek: 0, oneMonth: 0)
            }

            // Data is in chronological order: [oldest, ..., newest]
            // Index 0 = oldest (about 1 month ago)
            // Index count-1 = newest (today)

            // 1D: Change from yesterday (count-2) to today (count-1)
            let oneDayPercent: Double
            if count >= 2 {
                oneDayPercent = calculatePercentChange(from: validCloses[count - 2], to: validCloses[count - 1])
            } else {
                oneDayPercent = 0
            }

            // 1W: Change from 5 days ago (count-6) to today (count-1)
            let oneWeekPercent: Double
            if count >= 6 {
                oneWeekPercent = calculatePercentChange(from: validCloses[count - 6], to: validCloses[count - 1])
            } else if count >= 2 {
                oneWeekPercent = calculatePercentChange(from: validCloses[0], to: validCloses[count - 1])
            } else {
                oneWeekPercent = 0
            }

            // 1M: Change from 1 month ago (index 0) to today (count-1)
            let oneMonthPercent = calculatePercentChange(from: validCloses[0], to: validCloses[count - 1])

            #if DEBUG
            print("📈 [\(symbol)] 1D: \(String(format: "%.2f", oneDayPercent))%, 1W: \(String(format: "%.2f", oneWeekPercent))%, 1M: \(String(format: "%.2f", oneMonthPercent))% (data points: \(count))")
            #endif

            return Volatility(oneDay: oneDayPercent, oneWeek: oneWeekPercent, oneMonth: oneMonthPercent)
        }

        #if DEBUG
        print("📈 [\(symbol)] Failed to fetch volatility - no data")
        #endif

        return Volatility(oneDay: 0, oneWeek: 0, oneMonth: 0)
    }

    private func calculatePercentChange(from first: Double, to last: Double) -> Double {
        guard first > 0 else { return 0 }
        return ((last - first) / first) * 100
    }

    func searchSymbols(query: String) async throws -> [Stock] {
        let url = URL(string: "https://query1.finance.yahoo.com/v1/finance/search?q=\(query)&quotesCount=10&newsCount=0")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)

        var stocks: [Stock] = []

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let quotes = json["quotes"] as? [[String: Any]] {
            for quote in quotes {
                if let symbol = quote["symbol"] as? String {
                    let name = quote["shortname"] as? String ?? quote["symbol"] as? String ?? symbol
                    let exchange = quote["exchange"] as? String ?? "NASDAQ"
                    stocks.append(Stock(
                        id: symbol,
                        name: name,
                        exchange: exchange,
                        price: 0,
                        change: 0,
                        changePercent: 0
                    ))
                }
            }
        }

        return stocks
    }

    func fetchHistoricalPrices(symbol: String, range: TimeRange) async throws -> [Double] {
        let rangeString: String
        switch range {
        case .oneDay: rangeString = "1d"
        case .oneWeek: rangeString = "5d"
        case .oneMonth: rangeString = "1mo"
        case .threeMonths: rangeString = "3mo"
        case .oneYear: rangeString = "1y"
        }

        let url = URL(string: "\(baseURL)/chart/\(symbol)?interval=1d&range=\(rangeString)")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let chart = json["chart"] as? [String: Any],
           let result = chart["result"] as? [[String: Any]],
           let firstResult = result.first,
           let quotes = firstResult["indicators"] as? [String: Any],
           let quote = quotes["quote"] as? [[String: Any]],
           let firstQuote = quote.first,
           let closes = firstQuote["close"] as? [Double] {
            return closes
        }

        return []
    }

    enum TimeRange {
        case oneDay, oneWeek, oneMonth, threeMonths, oneYear
    }
}