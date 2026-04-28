import SwiftUI

struct VolatilityCard: View {
    let volatility: Volatility?

    var body: some View {
        HStack(spacing: 6) {
            VolatilityChip(label: "1D", value: volatility?.oneDayFormatted ?? "--")
            VolatilityChip(label: "1W", value: volatility?.oneWeekFormatted ?? "--")
            VolatilityChip(label: "1M", value: volatility?.oneMonthFormatted ?? "--")
        }
    }
}

struct VolatilityChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .frame(minWidth: 48)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }

    private var color: Color {
        guard let percent = parsePercent(value) else { return .secondary }
        if percent > 0 { return .green }
        if percent < 0 { return .red }
        return .secondary
    }

    private func parsePercent(_ value: String) -> Double? {
        let cleaned = value.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("With Data")
        HStack {
            VolatilityCard(volatility: Volatility(oneDay: 1.5, oneWeek: -2.3, oneMonth: 5.7))
            Spacer()
        }

        Text("Loading/Nil")
        HStack {
            VolatilityCard(volatility: nil)
            Spacer()
        }
    }
    .padding()
}