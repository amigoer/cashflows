import Foundation
import SwiftData

/// A fixed monthly outflow (rent, utilities, phone, food budget, etc.).
/// Recurs every month between `startMonth` and `endMonth` (inclusive).
/// `endMonth == nil` means "no end" — keeps recurring forever.
@Model
final class RecurringExpense {
    var category: String
    var amountCents: Int
    /// First day of the first active month (e.g. 2026-05-01 00:00 local).
    var startMonth: Date
    /// First day of the last active month (inclusive). Nil = open-ended.
    var endMonth: Date?
    var note: String?
    var archived: Bool
    var createdAt: Date

    init(
        category: String,
        amountCents: Int,
        startMonth: Date,
        endMonth: Date? = nil,
        note: String? = nil,
        archived: Bool = false,
        createdAt: Date = .now
    ) {
        self.category = category
        self.amountCents = amountCents
        self.startMonth = startMonth
        self.endMonth = endMonth
        self.note = note
        self.archived = archived
        self.createdAt = createdAt
    }

    /// True if this expense applies to the month containing `referenceDate`.
    func isActive(in referenceDate: Date, calendar: Calendar = .current) -> Bool {
        guard !archived else { return false }
        guard let monthStart = calendar.dateInterval(of: .month, for: referenceDate)?.start else {
            return false
        }
        if monthStart < startMonth { return false }
        if let endMonth, monthStart > endMonth { return false }
        return true
    }
}

/// Common categories — used to seed the picker. Users can also enter a custom one.
enum ExpenseCategory: String, CaseIterable, Identifiable {
    case rent = "房租"
    case utilities = "水电燃气"
    case phoneAndInternet = "话费 / 网费"
    case food = "餐饮"
    case transit = "交通"
    case subscriptions = "订阅 / 会员"
    case insurance = "保险"
    case other = "其他"

    var id: String { rawValue }
    var label: String { rawValue }

    var symbol: String {
        switch self {
        case .rent: "house.fill"
        case .utilities: "bolt.fill"
        case .phoneAndInternet: "antenna.radiowaves.left.and.right"
        case .food: "fork.knife"
        case .transit: "tram.fill"
        case .subscriptions: "star.fill"
        case .insurance: "shield.lefthalf.filled"
        case .other: "ellipsis.circle.fill"
        }
    }

    static func symbol(for category: String) -> String {
        ExpenseCategory(rawValue: category)?.symbol ?? Self.other.symbol
    }
}
