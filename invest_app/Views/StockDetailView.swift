import SwiftUI

struct StockDetailView: View {
    let stock: Stock
    @ObservedObject var viewModel: WatchlistViewModel
    @StateObject private var analysisVM = AnalysisViewModel()
    @State private var showingAnalysisReport = false
    @State private var showingProgress = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(stock.name)
                        .font(.title.bold())
                    Text(stock.id)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding()

                VStack(spacing: 4) {
                    Text("$\(String(format: "%.2f", stock.price))")
                        .font(.system(size: 48, weight: .bold))
                    Text("\(stock.change >= 0 ? "+" : "")\(String(format: "%.2f", stock.change)) (\(String(format: "%.2f%%", stock.changePercent)))")
                        .font(.headline)
                        .foregroundStyle(stock.change >= 0 ? .green : .red)
                }

                if let volatility = stock.volatility {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("波动情况")
                            .font(.headline)
                        VolatilityCard(volatility: volatility)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }

                Button(action: {
                    showingProgress = true
                    Task {
                        _ = await analysisVM.analyzeStock(stock)
                        showingProgress = false
                        showingAnalysisReport = true
                    }
                }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("开始AI分析")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(analysisVM.isAnalyzing)

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    if viewModel.isInWatchlist(stock) {
                        viewModel.removeFromWatchlist(stock)
                    } else {
                        viewModel.addToWatchlist(stock)
                    }
                }) {
                    Image(systemName: viewModel.isInWatchlist(stock) ? "star.fill" : "star")
                        .foregroundStyle(viewModel.isInWatchlist(stock) ? .yellow : .gray)
                }
            }
        }
        .overlay {
            if showingProgress {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    AnalysisProgressView(
                        progress: analysisVM.progress,
                        currentAgent: analysisVM.currentAgent,
                        agentResults: analysisVM.agentResults
                    )
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingAnalysisReport) {
            if let report = analysisVM.currentReport {
                AnalysisReportView(report: report)
            }
        }
    }
}
