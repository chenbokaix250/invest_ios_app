import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchlistView()
                .tabItem {
                    Label("自选", systemImage: "star.fill")
                }
                .tag(0)

            NasdaqBrowseView()
                .tabItem {
                    Label("NASDAQ", systemImage: "chart.bar.fill")
                }
                .tag(1)
        }
    }
}

struct NasdaqBrowseView: View {
    @StateObject private var viewModel = WatchlistViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.nasdaqStocks) { stock in
                    NavigationLink(destination: StockDetailView(stock: stock, viewModel: viewModel)) {
                        StockRow(
                            stock: stock,
                            isInWatchlist: viewModel.isInWatchlist(stock),
                            onToggleWatchlist: {
                                if viewModel.isInWatchlist(stock) {
                                    viewModel.removeFromWatchlist(stock)
                                } else {
                                    viewModel.addToWatchlist(stock)
                                }
                            }
                        )
                    }
                }
            }
            .refreshable {
                await viewModel.loadNasdaqStocks()
            }
            .navigationTitle("NASDAQ")
        }
    }
}

#Preview {
    ContentView()
}
