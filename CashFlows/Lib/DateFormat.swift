import Foundation

enum DateFormat {
    private static let zhLocale = Locale(identifier: "zh_CN")

    static let longDate: Date.FormatStyle = {
        Date.FormatStyle()
            .year(.defaultDigits)
            .month(.defaultDigits)
            .day(.defaultDigits)
            .locale(zhLocale)
    }()

    static let yearMonth: Date.FormatStyle = {
        Date.FormatStyle()
            .year(.defaultDigits)
            .month(.defaultDigits)
            .locale(zhLocale)
    }()

    static let monthDay: Date.FormatStyle = {
        Date.FormatStyle()
            .month(.defaultDigits)
            .day(.defaultDigits)
            .locale(zhLocale)
    }()

    static func long(_ date: Date) -> String {
        date.formatted(longDate)
    }

    static func yearMonth(_ date: Date) -> String {
        date.formatted(yearMonth)
    }

    static func monthDay(_ date: Date) -> String {
        date.formatted(monthDay)
    }
}
