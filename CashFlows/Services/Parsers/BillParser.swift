import Foundation

/// Heuristic parser that turns OCR text observations into a `DebtPlanDraft`.
/// Strategy: detect the platform via keywords, then run a set of regex extractors.
/// Anything we can't extract is left nil and the user fills it in manually.
enum BillParser {
    static func parse(observations: [OCRService.Observation]) -> DebtPlanDraft {
        let rawText = OCRService.joinedText(observations)
        let normalized = normalize(rawText)

        var draft = DebtPlanDraft(platform: detectPlatform(in: normalized), rawText: rawText)
        draft.totalPeriods = extractTotalPeriods(in: normalized)
        draft.monthlyPaymentCents = extractAmount(in: normalized, near: monthlyPaymentKeywords)
            ?? extractAmount(in: normalized, near: ["月供", "每期", "每月还款"])
        draft.principalCents = extractAmount(in: normalized, near: principalKeywords)
        draft.firstDueDate = extractFirstDueDate(in: normalized)
        draft.aprBps = extractAprBps(in: normalized)
        return draft
    }

    // MARK: - Normalization

    /// Collapse common spacing variations / full-width punctuation that hurt regex matching.
    private static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "￥", with: "¥")
            .replacingOccurrences(of: "：", with: ":")
            .replacingOccurrences(of: " ", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
    }

    // MARK: - Platform detection

    private static let platformRules: [(keywords: [String], name: String)] = [
        (["花呗", "蚂蚁花呗"], "花呗"),
        (["借呗", "蚂蚁借呗"], "借呗"),
        (["京东白条", "白条"], "京东白条"),
        (["京东金条", "金条"], "京东金条"),
        (["分期乐"], "分期乐"),
        (["微粒贷"], "微粒贷"),
        (["招商银行", "招行"], "招商银行信用卡"),
        (["中国建设银行", "建行"], "建设银行信用卡"),
        (["中国银行"], "中国银行信用卡"),
        (["中国工商银行", "工行"], "工商银行信用卡"),
        (["农业银行", "农行"], "农业银行信用卡"),
        (["交通银行", "交行"], "交通银行信用卡"),
        (["中信银行"], "中信银行信用卡"),
        (["浦发银行", "浦发"], "浦发银行信用卡"),
        (["民生银行"], "民生银行信用卡"),
        (["信用卡分期", "账单分期", "现金分期"], "信用卡分期"),
    ]

    private static func detectPlatform(in text: String) -> String {
        for rule in platformRules {
            if rule.keywords.contains(where: { text.contains($0) }) {
                return rule.name
            }
        }
        return ""
    }

    // MARK: - Field extraction

    private static let principalKeywords = [
        "分期金额", "分期本金", "本金", "申请金额", "贷款金额", "分期总额", "本期账单",
    ]
    private static let monthlyPaymentKeywords = [
        "每期应还", "每月应还", "每期还款", "每月还款", "月供", "每期金额", "每期", "本期应还",
    ]

    /// Look for an amount appearing on the same line as one of the given keywords.
    /// Falls back to scanning the next line.
    private static func extractAmount(in text: String, near keywords: [String]) -> Int? {
        let lines = text.split(whereSeparator: { $0.isNewline }).map(String.init)
        for (idx, line) in lines.enumerated() {
            guard keywords.contains(where: { line.contains($0) }) else { continue }
            if let cents = firstAmount(in: line) { return cents }
            // Try the next line — labels are sometimes on their own line.
            if idx + 1 < lines.count, let cents = firstAmount(in: lines[idx + 1]) {
                return cents
            }
        }
        return nil
    }

    /// First standalone money-looking number found in a string.
    /// Matches `¥1,234.56` / `1234.56元` / `1234.56` etc.
    private static func firstAmount(in line: String) -> Int? {
        let pattern = /[¥]?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)\s*元?/
        for match in line.matches(of: pattern) {
            let raw = String(match.1)
            if let cents = Money.parse(raw) {
                // Skip obvious non-money numbers (e.g. "12期" which would parse as 12).
                // Heuristic: require either a decimal point, comma, or ¥/元 marker.
                let full = String(match.0)
                let looksLikeMoney =
                    full.contains("¥") || full.contains("元") || raw.contains(".") || raw.contains(",")
                if looksLikeMoney { return cents }
            }
        }
        return nil
    }

    private static func extractTotalPeriods(in text: String) -> Int? {
        // Match patterns like "12期" / "分12期" / "共12期" / "12/24期"
        let single = /(\d{1,3})\s*期/
        let fraction = /(\d{1,3})\s*\/\s*(\d{1,3})\s*期/

        // Prefer fraction form (current/total) — take the larger number as total.
        if let m = text.firstMatch(of: fraction) {
            return Int(m.2)
        }
        if let m = text.firstMatch(of: single) {
            return Int(m.1)
        }
        return nil
    }

    private static func extractFirstDueDate(in text: String) -> Date? {
        // Look for keywords followed by a date.
        let keywords = ["首期还款日", "下期还款日", "下次还款", "本期到期日", "到期日", "还款日"]
        let lines = text.split(whereSeparator: { $0.isNewline }).map(String.init)
        for (idx, line) in lines.enumerated() {
            guard keywords.contains(where: { line.contains($0) }) else { continue }
            if let d = firstDate(in: line) { return d }
            if idx + 1 < lines.count, let d = firstDate(in: lines[idx + 1]) { return d }
        }
        // Fallback: just find the first date anywhere.
        return firstDate(in: text)
    }

    private static func firstDate(in text: String) -> Date? {
        // Matches YYYY-MM-DD / YYYY/MM/DD / YYYY年M月D日 / MM-DD (no year)
        let withYear = /(\d{4})[\-\/年\.](\d{1,2})[\-\/月\.](\d{1,2})日?/
        if let m = text.firstMatch(of: withYear),
           let year = Int(m.1), let month = Int(m.2), let day = Int(m.3) {
            return Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
        }
        let monthDay = /(\d{1,2})[\-\/月\.](\d{1,2})日?/
        if let m = text.firstMatch(of: monthDay),
           let month = Int(m.1), let day = Int(m.2) {
            let year = Calendar.current.component(.year, from: .now)
            return Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
        }
        return nil
    }

    private static func extractAprBps(in text: String) -> Int? {
        // Patterns: "年化利率 8.4%" / "费率0.06%" / "APR 12.6%"
        let percent = /(\d{1,2}(?:\.\d{1,2})?)\s*%/
        // Bias: pick a number close to APR keywords if possible.
        let keywords = ["年化利率", "年利率", "APR", "费率", "利率"]
        let lines = text.split(whereSeparator: { $0.isNewline }).map(String.init)
        for (idx, line) in lines.enumerated() {
            guard keywords.contains(where: { line.contains($0) }) else { continue }
            if let m = line.firstMatch(of: percent), let v = Double(m.1) {
                return Int((v * 100).rounded())
            }
            if idx + 1 < lines.count,
               let m = lines[idx + 1].firstMatch(of: percent),
               let v = Double(m.1) {
                return Int((v * 100).rounded())
            }
        }
        return nil
    }
}
