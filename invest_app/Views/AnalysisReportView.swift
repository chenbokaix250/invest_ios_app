import SwiftUI

struct AnalysisReportView: View {
    let report: AnalysisReport
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(report.stock.name)
                            .font(.title.bold())
                        Text(report.stock.id)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ZStack {
                            Circle()
                                .stroke(scoreColor.opacity(0.2), lineWidth: 12)
                            Circle()
                                .trim(from: 0, to: CGFloat(report.totalScore) / 36.0)
                                .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            VStack {
                                Text("\(report.totalScore)")
                                    .font(.system(size: 48, weight: .bold))
                                Text("/36")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 150, height: 150)

                        Text(report.recommendation.rawValue)
                            .font(.title2.bold())
                            .foregroundStyle(scoreColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(scoreColor.opacity(0.1))
                            .cornerRadius(20)
                    }
                    .padding()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("投资摘要")
                            .font(.headline)
                        MarkdownText(content: report.summary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    ForEach(report.agentResults) { result in
                        AgentResultCard(result: result)
                    }
                }
                .padding()
            }
            .navigationTitle("分析报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var scoreColor: Color {
        switch report.recommendation {
        case .strongBuy: return .green
        case .buy: return .green.opacity(0.7)
        case .hold: return .yellow
        case .sell: return .orange
        case .strongSell: return .red
        }
    }
}

struct AgentResultCard: View {
    let result: AgentResult
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: result.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(result.isCompleted ? .green : .gray)

                    Text(result.dimension.title)
                        .font(.headline)

                    Spacer()

                    if let score = result.score {
                        ScoreBadge(score: score)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                MarkdownText(content: result.content)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ScoreBadge: View {
    let score: Int

    var body: some View {
        Text("\(score)/4")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(scoreColor)
            .cornerRadius(8)
    }

    private var scoreColor: Color {
        switch score {
        case 3...4: return .green
        case 2: return .yellow
        default: return .red
        }
    }
}

// MARK: - Markdown Renderer

struct MarkdownText: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(parseBlocks()), id: \.offset) { block in
                renderBlock(block)
            }
        }
    }

    private func parseBlocks() -> [(offset: Int, content: String)] {
        var blocks: [(offset: Int, content: String)] = []
        let lines = content.components(separatedBy: "\n")
        var currentBlock = ""
        var currentOffset = 0

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check if this line starts a table
            if isTableRow(trimmed) {
                if !currentBlock.isEmpty {
                    blocks.append((offset: currentOffset, content: currentBlock))
                    currentOffset = index
                    currentBlock = ""
                }
                currentBlock += line + "\n"
            } else if trimmed.isEmpty && !currentBlock.isEmpty {
                blocks.append((offset: currentOffset, content: currentBlock))
                currentOffset = index + 1
                currentBlock = ""
            } else {
                currentBlock += line + "\n"
            }
        }

        if !currentBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            blocks.append((offset: currentOffset, content: currentBlock))
        }

        return blocks
    }

    private func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("|") && trimmed.hasSuffix("|") && trimmed.filter { $0 == "|" }.count >= 2
    }

    @ViewBuilder
    private func renderBlock(_ block: (offset: Int, content: String)) -> some View {
        let content = block.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = content.components(separatedBy: "\n").first ?? ""

        if isTableRow(firstLine) {
            renderTable(content)
        } else {
            renderLines(content.components(separatedBy: "\n"))
        }
    }

    private func renderTable(_ tableContent: String) -> some View {
        let rows = tableContent.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard rows.count >= 2 else { return AnyView(EmptyView()) }

        let headerRow = rows[0]
        let columns = parseTableColumns(headerRow)

        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                // Header row
                HStack(spacing: 0) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { colIndex, col in
                        Text(col.trimmingCharacters(in: .whitespaces))
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color.gray.opacity(0.15))
                            .overlay(
                                Rectangle()
                                    .frame(width: 1)
                                    .foregroundStyle(Color.gray.opacity(0.3)),
                                alignment: .trailing
                            )
                    }
                }

                // Data rows
                ForEach(Array(rows.dropFirst().enumerated()), id: \.offset) { rowIndex, row in
                    if row.trimmingCharacters(in: .whitespaces).hasPrefix("|") &&
                       row.trimmingCharacters(in: .whitespaces).hasSuffix("|") &&
                       !row.contains("---") {
                        let cols = parseTableColumns(row)
                        HStack(spacing: 0) {
                            ForEach(Array(cols.enumerated()), id: \.offset) { colIndex, col in
                                Text(col.trimmingCharacters(in: .whitespaces))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .overlay(
                                        Rectangle()
                                            .frame(width: 1)
                                            .foregroundStyle(Color.gray.opacity(0.2)),
                                        alignment: .trailing
                                    )
                            }
                        }
                        .background(rowIndex % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.vertical, 8)
        )
    }

    private func parseTableColumns(_ row: String) -> [String] {
        row.components(separatedBy: "|")
            .filter { !$0.isEmpty }
    }

    @ViewBuilder
    private func renderLines(_ lines: [String]) -> some View {
        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
            renderLine(line)
        }
    }

    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            Spacer().frame(height: 4)
        } else if trimmed.hasPrefix("## ") {
            Text(attributedText(String(trimmed.dropFirst(3)), bold: true, size: 16))
                .foregroundStyle(.primary)
                .padding(.top, 8)
        } else if trimmed.hasPrefix("# ") {
            Text(attributedText(String(trimmed.dropFirst(2)), bold: true, size: 18))
                .foregroundStyle(.primary)
                .padding(.top, 12)
        } else if trimmed == "---" || trimmed == "***" || trimmed == "___" {
            Divider()
                .padding(.vertical, 8)
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .foregroundStyle(.secondary)
                Text(attributedText(String(trimmed.dropFirst(2)), bold: false, size: 14))
                    .foregroundStyle(.secondary)
            }
        } else if trimmed.hasPrefix("1. ") || trimmed.hasPrefix("2. ") || trimmed.hasPrefix("3. ") ||
                  trimmed.hasPrefix("4. ") || trimmed.hasPrefix("5. ") {
            Text(attributedText(trimmed, bold: false, size: 14))
                .foregroundStyle(.secondary)
                .padding(.leading, 16)
        } else if trimmed.hasPrefix("> ") {
            Text(attributedText(String(trimmed.dropFirst(2)), bold: false, size: 14))
                .italic()
                .foregroundStyle(.secondary)
                .padding(.leading, 16)
        } else if trimmed.hasPrefix("```") {
            EmptyView()
        } else if isTableRow(trimmed) {
            EmptyView() // Tables are handled separately
        } else {
            Text(attributedText(trimmed, bold: false, size: 14))
                .foregroundStyle(.secondary)
        }
    }

    private func attributedText(_ text: String, bold: Bool, size: CGFloat) -> AttributedString {
        var result = AttributedString()

        var currentText = text
        while !currentText.isEmpty {
            // Check for **bold** pattern
            if let boldRange = currentText.range(of: "**") {
                let beforeBold = String(currentText[..<boldRange.lowerBound])
                if !beforeBold.isEmpty {
                    result += AttributedString(beforeBold)
                }

                let afterFirstBold = String(currentText[boldRange.upperBound...])
                if let closingBold = afterFirstBold.range(of: "**") {
                    let boldContent = String(afterFirstBold[..<closingBold.lowerBound])
                    var boldAttr = AttributedString(boldContent)
                    boldAttr.font = .system(size: size, weight: .bold)
                    result += boldAttr

                    currentText = String(afterFirstBold[closingBold.upperBound...])
                } else {
                    result += AttributedString("**")
                    currentText = afterFirstBold
                }
            }
            // Check for *italic* pattern
            else if let italicRange = currentText.range(of: "*") {
                let beforeItalic = String(currentText[..<italicRange.lowerBound])
                if !beforeItalic.isEmpty {
                    result += AttributedString(beforeItalic)
                }

                let afterFirstItalic = String(currentText[italicRange.upperBound...])
                if let closingItalic = afterFirstItalic.range(of: "*") {
                    let italicContent = String(afterFirstItalic[..<closingItalic.lowerBound])
                    var italicAttr = AttributedString(italicContent)
                    italicAttr.font = .system(size: size).italic()
                    result += italicAttr

                    currentText = String(afterFirstItalic[closingItalic.upperBound...])
                } else {
                    result += AttributedString("*")
                    currentText = afterFirstItalic
                }
            }
            // Check for `code` pattern
            else if let codeRange = currentText.range(of: "`") {
                let beforeCode = String(currentText[..<codeRange.lowerBound])
                if !beforeCode.isEmpty {
                    result += AttributedString(beforeCode)
                }

                let afterFirstCode = String(currentText[codeRange.upperBound...])
                if let closingCode = afterFirstCode.range(of: "`") {
                    let codeContent = String(afterFirstCode[..<closingCode.lowerBound])
                    var codeAttr = AttributedString(codeContent)
                    codeAttr.font = .system(size: size, design: .monospaced)
                    codeAttr.foregroundColor = .blue
                    result += codeAttr

                    currentText = String(afterFirstCode[closingCode.upperBound...])
                } else {
                    result += AttributedString("`")
                    currentText = afterFirstCode
                }
            } else {
                var normalAttr = AttributedString(currentText)
                normalAttr.font = .system(size: size, weight: bold ? .bold : .regular)
                result += normalAttr
                break
            }
        }

        return result
    }
}