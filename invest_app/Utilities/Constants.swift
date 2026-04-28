import Foundation

enum Constants {
    enum API {
        static let yahooFinanceBaseURL = "https://query1.finance.yahoo.com/v8/finance"
        static let finnhubBaseURL = "https://finnhub.io/api/v1"
        static let miniMaxBaseURL = "https://api.minimaxi.com/v1"
        static let miniMaxModel = "MiniMax-M2.7"
    }

    enum Storage {
        static let watchlistKey = "user_watchlist"
    }

    enum Analysis {
        static let expertAgentCount = 9
        static let timeoutSeconds: TimeInterval = 120
    }

    enum NASDAQ {
        static let topStocks: [(symbol: String, name: String)] = [
            ("AAPL", "Apple Inc."),
            ("MSFT", "Microsoft Corporation"),
            ("GOOGL", "Alphabet Inc."),
            ("AMZN", "Amazon.com Inc."),
            ("NVDA", "NVIDIA Corporation"),
            ("META", "Meta Platforms Inc."),
            ("TSLA", "Tesla Inc."),
            ("AVGO", "Broadcom Inc."),
            ("ORCL", "Oracle Corporation"),
            ("ADBE", "Adobe Inc.")
        ]
    }
}