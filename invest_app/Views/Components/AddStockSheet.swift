import SwiftUI

struct AddStockSheet: View {
    @ObservedObject var viewModel: WatchlistViewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isSearching {
                    Spacer()
                    ProgressView("搜索中...")
                    Spacer()
                } else if searchText.isEmpty {
                    List {
                        Section("热门NASDAQ股票") {
                            ForEach(viewModel.filteredNasdaqStocks) { stock in
                                AddStockRow(
                                    stock: stock,
                                    isInWatchlist: viewModel.isInWatchlist(stock),
                                    onAdd: {
                                        viewModel.addToWatchlist(stock)
                                    }
                                )
                            }
                        }
                    }
                } else {
                    List {
                        ForEach(viewModel.searchResults) { stock in
                            AddStockRow(
                                stock: stock,
                                isInWatchlist: viewModel.isInWatchlist(stock),
                                onAdd: {
                                    viewModel.addToWatchlist(stock)
                                }
                            )
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索股票代码或名称")
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    viewModel.searchResults = []
                } else {
                    Task {
                        isSearching = true
                        await viewModel.searchStocks(query: newValue)
                        isSearching = false
                    }
                }
            }
            .navigationTitle("添加股票")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct AddStockRow: View {
    let stock: Stock
    let isInWatchlist: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(stock.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if stock.price > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(String(format: "%.2f", stock.price))")
                        .font(.subheadline)
                    Text("\(stock.changePercent >= 0 ? "+" : "")\(String(format: "%.2f%%", stock.changePercent))")
                        .font(.caption)
                        .foregroundStyle(stock.changePercent >= 0 ? .green : .red)
                }
            }

            if isInWatchlist {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    AddStockSheet(viewModel: WatchlistViewModel())
}