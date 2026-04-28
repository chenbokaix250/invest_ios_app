import Foundation
import SwiftUI

@MainActor
class WatchlistViewModel: ObservableObject {
    @Published var watchlist: [Stock] = []
    @Published var nasdaqStocks: [Stock] = []
    @Published var isLoading: Bool = false
    @Published var searchQuery: String = ""
    @Published var searchResults: [Stock] = []

    private let yahooService = YahooFinanceService()
    private let userDefaults = UserDefaults.standard

    init() {
        loadWatchlist()
        Task {
            await loadNasdaqStocks()
        }
    }

    var filteredNasdaqStocks: [Stock] {
        if searchQuery.isEmpty {
            return nasdaqStocks
        }
        return nasdaqStocks.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.id.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    func loadNasdaqStocks() async {
        isLoading = true
        let symbols = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "META", "TSLA", "AVGO", "ORCL", "ADBE"]
        var stocks: [Stock] = []

        await withTaskGroup(of: Stock?.self) { group in
            for symbol in symbols {
                group.addTask {
                    try? await self.fetchStock(symbol: symbol)
                }
            }

            for await stock in group {
                if let stock = stock {
                    stocks.append(stock)
                }
            }
        }

        nasdaqStocks = stocks.sorted { $0.name < $1.name }
        isLoading = false
    }

    func fetchStock(symbol: String) async throws -> Stock {
        let stock = try await yahooService.fetchQuote(symbol: symbol)
        let volatility = try await yahooService.fetchVolatility(symbol: symbol)
        var stockWithVolatility = stock
        stockWithVolatility.volatility = volatility
        return stockWithVolatility
    }

    func searchStocks(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        do {
            let results = try await yahooService.searchSymbols(query: query)
            // Sort by relevance (exact match first, then contains)
            searchResults = results.sorted { s1, s2 in
                let q = query.lowercased()
                let s1Exact = s1.id.lowercased() == q || s1.name.lowercased() == q
                let s2Exact = s2.id.lowercased() == q || s2.name.lowercased() == q
                if s1Exact && !s2Exact { return true }
                if !s1Exact && s2Exact { return false }

                let s1Starts = s1.id.lowercased().hasPrefix(q) || s1.name.lowercased().hasPrefix(q)
                let s2Starts = s2.id.lowercased().hasPrefix(q) || s2.name.lowercased().hasPrefix(q)
                if s1Starts && !s2Starts { return true }
                if !s1Starts && s2Starts { return false }

                return s1.id < s2.id
            }
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }

    func addToWatchlist(_ stock: Stock) {
        if !watchlist.contains(where: { $0.id == stock.id }) {
            var stockToAdd = stock
            stockToAdd.isInWatchlist = true
            watchlist.append(stockToAdd)
            saveWatchlist()
            Task {
                await refreshVolatility(for: stockToAdd)
            }
        }
    }

    func removeFromWatchlist(_ stock: Stock) {
        watchlist.removeAll { $0.id == stock.id }
        saveWatchlist()
    }

    func updateStockGroup(_ stock: Stock, to group: StockGroup) {
        if let index = watchlist.firstIndex(where: { $0.id == stock.id }) {
            watchlist[index].group = group
            saveWatchlist()
        }
    }

    func isInWatchlist(_ stock: Stock) -> Bool {
        watchlist.contains { $0.id == stock.id }
    }

    func refreshVolatility(for stock: Stock) async {
        do {
            let volatility = try await yahooService.fetchVolatility(symbol: stock.id)
            if let index = nasdaqStocks.firstIndex(where: { $0.id == stock.id }) {
                nasdaqStocks[index].volatility = volatility
            }
            if let index = watchlist.firstIndex(where: { $0.id == stock.id }) {
                watchlist[index].volatility = volatility
            }
        } catch {
            print("Failed to refresh volatility: \(error)")
        }
    }

    private func loadWatchlist() {
        if let data = userDefaults.data(forKey: Constants.Storage.watchlistKey),
           let decoded = try? JSONDecoder().decode([Stock].self, from: data) {
            watchlist = decoded
        }
    }

    private func saveWatchlist() {
        if let encoded = try? JSONEncoder().encode(watchlist) {
            userDefaults.set(encoded, forKey: Constants.Storage.watchlistKey)
        }
    }
}