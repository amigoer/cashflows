import Foundation

/// Output schema asked from the LLM. Money values are in yuan so the model doesn't have to
/// reason about cent conversions; we multiply back to cents ourselves.
struct LLMExtraction: Decodable {
    var principalYuan: Double?
    var totalPeriods: Int?
    var monthlyPaymentYuan: Double?
    /// ISO 8601 yyyy-MM-dd
    var firstDueDate: String?
    var aprPercent: Double?
    var note: String?
}

enum LLMBillParser {
    /// Try the configured LLM first; on any failure, fall back to the regex `BillParser`.
    /// The platform string is treated as user-authoritative and overwrites whatever the LLM /
    /// regex parser would have guessed.
    @MainActor
    static func parse(
        observations: [OCRService.Observation],
        platform: String,
        config: LLMConfig
    ) async -> (draft: DebtPlanDraft, source: Source) {
        let rawText = OCRService.joinedText(observations)

        if config.isReady {
            do {
                let extraction = try await callLLM(
                    rawText: rawText,
                    platform: platform,
                    snapshot: config.snapshot()
                )
                let draft = makeDraft(from: extraction, platform: platform, rawText: rawText)
                return (draft, .llm)
            } catch {
                // Fall through to regex.
            }
        }

        var regexDraft = BillParser.parse(observations: observations)
        regexDraft.platform = platform
        return (regexDraft, .regex)
    }

    enum Source {
        case llm
        case regex
    }

    private static func callLLM(
        rawText: String,
        platform: String,
        snapshot: LLMConfig.Snapshot
    ) async throws -> LLMExtraction {
        let today = isoDateOnlyFormatter().string(from: .now)
        let systemPrompt = """
        你是中国的分期账单结构化抽取助手。
        输入是用户上传的「\(platform)」分期账单截图经过 OCR 后的纯文本。
        今天是 \(today)。

        规则：
        1. 只返回 JSON，不要任何额外文字或解释。
        2. 所有字段都是可选的；不能从文本中明确读到的就返回 null，**不要猜**。
        3. 金额单位是「元」（不是分），保留两位小数。
        4. 日期一律 ISO 格式 yyyy-MM-dd。
        5. 期数是整数（如 12, 24）。优先取「总期数」，如果只看到「当前 X/Y」格式，Y 是总期数。
        6. 年化利率是百分数（如 8.4 表示 8.4%）。

        JSON 字段说明：
        - principalYuan: 本金金额（元）
        - totalPeriods: 总期数
        - monthlyPaymentYuan: 每月应还金额（元）
        - firstDueDate: 首期还款日 yyyy-MM-dd
        - aprPercent: 年化利率百分比
        - note: 简短备注（≤30 字），如截图里有特殊信息，否则 null
        """

        let userPrompt = """
        以下是 OCR 文本：
        ---
        \(rawText)
        ---
        请返回 JSON。
        """

        let response = try await LLMService.chat(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            config: snapshot,
            expectsJson: true
        )

        let json = extractJSON(from: response)
        guard let data = json.data(using: .utf8) else {
            throw LLMError.decoding("响应不是有效 UTF-8")
        }
        do {
            return try JSONDecoder().decode(LLMExtraction.self, from: data)
        } catch {
            throw LLMError.decoding(error.localizedDescription)
        }
    }

    /// Some providers wrap JSON in ```json fences even when asked for json_object. Trim them.
    private static func extractJSON(from raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            let lines = text.split(whereSeparator: { $0.isNewline })
            text = lines.dropFirst().dropLast().joined(separator: "\n")
        }
        return text
    }

    private static func makeDraft(
        from extraction: LLMExtraction,
        platform: String,
        rawText: String
    ) -> DebtPlanDraft {
        var draft = DebtPlanDraft(platform: platform, rawText: rawText)
        if let yuan = extraction.principalYuan {
            draft.principalCents = Int((yuan * 100).rounded())
        }
        draft.totalPeriods = extraction.totalPeriods
        if let yuan = extraction.monthlyPaymentYuan {
            draft.monthlyPaymentCents = Int((yuan * 100).rounded())
        }
        if let dateStr = extraction.firstDueDate,
           let date = isoDateOnlyFormatter().date(from: dateStr) {
            draft.firstDueDate = date
        }
        if let apr = extraction.aprPercent {
            draft.aprBps = Int((apr * 100).rounded())
        }
        draft.note = extraction.note
        return draft
    }
}

private func isoDateOnlyFormatter() -> ISO8601DateFormatter {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withFullDate]
    return f
}
