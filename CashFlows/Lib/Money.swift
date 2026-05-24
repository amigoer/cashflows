import Foundation

enum Money {
    private static let yuanFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    static func format(cents: Int, showSymbol: Bool = true, signed: Bool = false) -> String {
        let yuan = Decimal(cents) / 100
        let absValue = yuan.magnitude
        let body = yuanFormatter.string(from: absValue as NSDecimalNumber) ?? "0.00"
        let prefix: String = {
            if signed { return cents >= 0 ? "+" : "-" }
            return cents < 0 ? "-" : ""
        }()
        let symbol = showSymbol ? "¥" : ""
        return "\(prefix)\(symbol)\(body)"
    }

    static func parse(_ input: String) -> Int? {
        let trimmed = input
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "元", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let value = Decimal(string: trimmed)
        else { return nil }
        let cents = (value * 100) as NSDecimalNumber
        return cents.intValue
    }
}
