import SwiftUI

struct StockRow: View {
    let stock: Stock
    let isInWatchlist: Bool
    let onToggleWatchlist: () -> Void

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

            // 1D Volatility only
            if let vol = stock.volatility {
                Volatility1D(value: vol.oneDay)
            } else {
                Text("--")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)
            }

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", stock.price))")
                    .font(.headline)
                Text("\(stock.change >= 0 ? "+" : "")\(String(format: "%.2f%%", stock.changePercent))")
                    .font(.caption)
                    .foregroundStyle(stock.change >= 0 ? .green : .red)
            }

            Button(action: onToggleWatchlist) {
                Image(systemName: isInWatchlist ? "star.fill" : "star")
                    .foregroundStyle(isInWatchlist ? .yellow : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}

struct Volatility1D: View {
    let value: Double

    var body: some View {
        HStack(spacing: 2) {
            Text("1D")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f%%", value))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }

    private var color: Color {
        if value > 0 { return .green }
        if value < 0 { return .red }
        return .secondary
    }
}

#Preview {
    List {
        StockRow(
            stock: Stock(id: "AAPL", name: "Apple Inc.", exchange: "NASDAQ", price: 178.50, change: 2.30, changePercent: 1.31, volatility: Volatility(oneDay: 1.31, oneWeek: -0.5, oneMonth: 3.2)),
            isInWatchlist: true,
            onToggleWatchlist: {}
        )
    }
}