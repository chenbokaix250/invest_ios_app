import SwiftUI

struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var showingAddSheet = false
    @State private var selectedStockForGroup: Stock?

    private var groupedStocks: [StockGroup: [Stock]] {
        Dictionary(grouping: viewModel.watchlist) { $0.group }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.watchlist.isEmpty {
                    ContentUnavailableView {
                        Label("暂无自选股票", systemImage: "star.slash")
                    } description: {
                        Text("点击右上角添加按钮来添加股票到自选列表")
                    }
                } else {
                    List {
                        ForEach(StockGroup.allCases, id: \.self) { group in
                            let stocksInGroup = groupedStocks[group] ?? []
                            if !stocksInGroup.isEmpty || group == .none {
                                Section(group.rawValue) {
                                    ForEach(stocksInGroup) { stock in
                                        StockRow(
                                            stock: stock,
                                            isInWatchlist: true,
                                            onToggleWatchlist: {}
                                        )
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                viewModel.removeFromWatchlist(stock)
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                            Button {
                                                selectedStockForGroup = stock
                                            } label: {
                                                Label("分组", systemImage: "folder")
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .refreshable {
                        for stock in viewModel.watchlist {
                            await viewModel.refreshVolatility(for: stock)
                        }
                    }
                }
            }
            .navigationTitle("自选")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddStockSheet(viewModel: viewModel)
            }
            .confirmationDialog("选择分组", isPresented: .init(
                get: { selectedStockForGroup != nil },
                set: { if !$0 { selectedStockForGroup = nil } }
            )) {
                Button("买入") {
                    if let stock = selectedStockForGroup {
                        viewModel.updateStockGroup(stock, to: .buy)
                    }
                }
                Button("观望") {
                    if let stock = selectedStockForGroup {
                        viewModel.updateStockGroup(stock, to: .watch)
                    }
                }
                Button("取消", role: .cancel) {
                    selectedStockForGroup = nil
                }
            }
        }
    }
}
