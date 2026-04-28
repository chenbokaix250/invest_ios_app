import SwiftUI

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

            if isTableRow(trimmed) {
                if !currentBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    blocks.append((offset: currentOffset, content: currentBlock))
                    currentOffset = index
                    currentBlock = ""
                }
                currentBlock += line + "\n"
            } else if trimmed.isEmpty && !currentBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
        let rows = tableContent.components(separatedBy: "\n").filter { row in
            let t = row.trimmingCharacters(in: .whitespaces)
            return !t.isEmpty && t.hasPrefix("|")
        }
        guard rows.count >= 2 else { return AnyView(EmptyView()) }

        let hasSeparator = rows.contains { row in
            let t = row.trimmingCharacters(in: .whitespaces)
            let cells = t.components(separatedBy: "|").filter { !$0.isEmpty }
            return cells.allSatisfy { cell in
                let trimmed = cell.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty || trimmed.allSatisfy { $0 == "-" || $0 == ":" }
            }
        }

        let headerRow = hasSeparator ? rows[0] : rows[0]
        let dataRows = hasSeparator ? Array(rows.dropFirst().dropFirst()) : Array(rows.dropFirst())

        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    let columns = parseTableColumns(headerRow)
                    ForEach(Array(columns.enumerated()), id: \.offset) { colIndex, col in
                        Text(attributedText(String(col.trimmingCharacters(in: .whitespaces)), bold: true, size: 14))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 6)
                            .background(Color.gray.opacity(0.2))
                            .overlay(
                                Rectangle()
                                    .frame(width: colIndex < columns.count - 1 ? 1 : 0)
                                    .foregroundStyle(Color.gray.opacity(0.4)),
                                alignment: .trailing
                            )
                    }
                }

                ForEach(Array(dataRows.enumerated()), id: \.offset) { rowIndex, row in
                    let cols = parseTableColumns(row)
                    HStack(spacing: 0) {
                        ForEach(Array(cols.enumerated()), id: \.offset) { colIndex, col in
                            Text(attributedText(String(col.trimmingCharacters(in: .whitespaces)), bold: false, size: 13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 6)
                                .overlay(
                                    Rectangle()
                                        .frame(width: colIndex < cols.count - 1 ? 1 : 0)
                                        .foregroundStyle(Color.gray.opacity(0.3)),
                                    alignment: .trailing
                                )
                        }
                    }
                    .background(rowIndex % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
        )
    }

    private func parseTableColumns(_ row: String) -> [String] {
        row.components(separatedBy: "|").filter { !$0.isEmpty }
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
            Spacer().frame(height: 6)
        } else if trimmed.hasPrefix("## ") {
            Text(attributedText(String(trimmed.dropFirst(3)), bold: true, size: 17))
                .foregroundStyle(.primary)
                .padding(.top, 10)
        } else if trimmed.hasPrefix("# ") {
            Text(attributedText(String(trimmed.dropFirst(2)), bold: true, size: 20))
                .foregroundStyle(.primary)
                .padding(.top, 14)
        } else if trimmed == "---" || trimmed == "***" || trimmed == "___" {
            Divider()
                .padding(.vertical, 10)
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 10) {
                Text("•")
                    .font(.system(size: 14))
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
                .padding(.vertical, 4)
        } else if trimmed.hasPrefix("```") {
            EmptyView()
        } else {
            Text(attributedText(trimmed, bold: false, size: 14))
                .foregroundStyle(.secondary)
        }
    }

    private func attributedText(_ text: String, bold: Bool, size: CGFloat) -> AttributedString {
        var result = AttributedString()
        var currentText = text

        while !currentText.isEmpty {
            if currentText.hasPrefix("**") {
                let afterBold = String(currentText.dropFirst(2))
                if let closingRange = afterBold.range(of: "**") {
                    let boldContent = String(afterBold[..<closingRange.lowerBound])
                    var boldAttr = AttributedString(boldContent)
                    boldAttr.font = .system(size: size, weight: .bold)
                    result += boldAttr
                    currentText = String(afterBold[closingRange.upperBound...])
                    continue
                }
            }

            if currentText.hasPrefix("*") && !currentText.hasPrefix("**") {
                let afterAsterisk = String(currentText.dropFirst())
                if let closingRange = afterAsterisk.range(of: "*"), !afterAsterisk.hasPrefix("*") {
                    let italicContent = String(afterAsterisk[..<closingRange.lowerBound])
                    var italicAttr = AttributedString(italicContent)
                    italicAttr.font = .system(size: size).italic()
                    result += italicAttr
                    currentText = String(afterAsterisk[closingRange.upperBound...])
                    continue
                }
            }

            if currentText.hasPrefix("`") {
                let afterCode = String(currentText.dropFirst())
                if let closingRange = afterCode.range(of: "`") {
                    let codeContent = String(afterCode[..<closingRange.lowerBound])
                    var codeAttr = AttributedString(codeContent)
                    codeAttr.font = .system(size: size, design: .monospaced)
                    codeAttr.foregroundColor = .blue
                    result += codeAttr
                    currentText = String(afterCode[closingRange.upperBound...])
                    continue
                }
            }

            var normalAttr = AttributedString(currentText)
            normalAttr.font = .system(size: size, weight: bold ? .bold : .regular)
            result += normalAttr
            break
        }

        return result
    }
}

// MARK: - Test Preview

#Preview("Markdown Renderer Test") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Text("Markdown Renderer Test Suite")
                .font(.title.bold())
                .padding(.bottom)

            Group {
                Text("1. Headers")
                    .font(.headline)
                MarkdownText(content: """
                # 一级标题
                ## 二级标题
                ### 三级标题
                """)

                Text("2. Bold & Italic")
                    .font(.headline)
                MarkdownText(content: """
                这是**粗体文本**和*斜体文本*
                ***粗体加斜体***
                正常文本**突出部分**正常
                """)

                Text("3. Lists")
                    .font(.headline)
                MarkdownText(content: """
                - 无序列表项 1
                - 无序列表项 2
                - 无序列表项 3

                1. 有序列表项 1
                2. 有序列表项 2
                3. 有序列表项 3
                """)

                Text("4. Table")
                    .font(.headline)
                MarkdownText(content: """
                | 指标 | 数值 | 评级 |
                |------|------|------|
                | 营收增长 | 15% | 良好 |
                | 利润率 | 22% | 优秀 |
                | 负债率 | 45% | 中等 |
                """)

                Text("5. Separator")
                    .font(.headline)
                MarkdownText(content: """
                上面内容
                ---
                下面内容
                """)

                Text("6. Quote")
                    .font(.headline)
                MarkdownText(content: """
                > 这是一段引用文本
                > 可以有多行
                """)

                Text("7. Code")
                    .font(.headline)
                MarkdownText(content: """
                使用 `print("Hello")` 输出内容
                """)

                Text("8. Complex Mixed")
                    .font(.headline)
                MarkdownText(content: """
                ## 财务分析

                - **营收**: ¥100亿，同比增长 **20%**
                - 毛利率: *25%*，行业领先

                | 项目 | 数值 | 备注 |
                |------|------|------|
                | 市盈率 | 25 | 合理 |
                | 市净率 | 3.5 | 偏高 |

                ### 结论

                > 综合评分：**8/10**，推荐**买入**
                """)
            }
        }
        .padding()
    }
}