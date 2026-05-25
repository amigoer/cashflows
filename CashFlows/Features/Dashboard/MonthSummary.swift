import Foundation
import SwiftData

/// Aggregated cash-flow data for a single month, ready to render.
struct MonthSummary: Identifiable, Hashable {
    /// First instant of the month (e.g. 2026-05-01 00:00 local).
    let month: Date
    let incomeCents: Int
    let repaymentCents: Int
    let expenseCents: Int
    let salaryIds: [PersistentIdentifierBox]
    let platforms: [PlatformBreakdown]
    let expenseLines: [ExpenseLine]
    let isCurrentMonth: Bool

    var id: Date { month }
    var netCents: Int { incomeCents - repaymentCents - expenseCents }
    var totalOutflowCents: Int { repaymentCents + expenseCents }
    /// Total number of distinct outflow line items (platforms + expense categories).
    var outflowItemCount: Int { platforms.count + expenseLines.count }
}

struct PlatformBreakdown: Identifiable, Hashable {
    let platform: String
    let cents: Int
    let repaymentIds: [PersistentIdentifierBox]

    var id: String { platform }
}

struct ExpenseLine: Identifiable, Hashable {
    let category: String
    let cents: Int
    let expenseId: PersistentIdentifierBox

    var id: PersistentIdentifierBox { expenseId }
}

/// Hashable wrapper around `PersistentIdentifier` so we can hold it in `Hashable` structs.
struct PersistentIdentifierBox: Hashable, Sendable {
    let hashValue: Int

    init(_ id: PersistentIdentifier) {
        self.hashValue = id.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(hashValue)
    }

    static func == (lhs: PersistentIdentifierBox, rhs: PersistentIdentifierBox) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

enum MonthlyTimelineBuilder {
    /// Builds month summaries covering every month that has at least one salary, repayment,
    /// or active recurring expense, plus the current month. Returns current month first,
    /// then future months ascending, then past months descending.
    static func build(
        salaries: [Salary],
        repayments: [Repayment],
        recurringExpenses: [RecurringExpense],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [MonthSummary] {
        var monthStarts: Set<Date> = []
        for s in salaries {
            if let start = calendar.dateInterval(of: .month, for: s.paidAt)?.start {
                monthStarts.insert(start)
            }
        }
        for r in repayments {
            if let start = calendar.dateInterval(of: .month, for: r.dueDate)?.start {
                monthStarts.insert(start)
            }
        }
        let nowStart = calendar.dateInterval(of: .month, for: now)?.start
        if let nowStart {
            monthStarts.insert(nowStart)
        }

        // Cap recurring expense expansion so a forever expense doesn't blow up the list.
        let latestKnown = monthStarts.max() ?? nowStart ?? now
        let cap = calendar.date(byAdding: .month, value: 12, to: latestKnown) ?? latestKnown

        let activeExpenses = recurringExpenses.filter { !$0.archived }
        for exp in activeExpenses {
            let endBoundary = min(exp.endMonth ?? cap, cap)
            var cursor = exp.startMonth
            while cursor <= endBoundary {
                monthStarts.insert(cursor)
                guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
                cursor = next
            }
        }

        // Sort: current first, future asc, past desc.
        let ordered = monthStarts.sorted { lhs, rhs in
            if lhs == nowStart { return true }
            if rhs == nowStart { return false }
            let lhsFuture = lhs > (nowStart ?? now)
            let rhsFuture = rhs > (nowStart ?? now)
            if lhsFuture && rhsFuture { return lhs < rhs }
            if !lhsFuture && !rhsFuture { return lhs > rhs }
            return lhsFuture
        }

        return ordered.map { start in
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
            let monthSalaries = salaries.filter { $0.paidAt >= start && $0.paidAt < end }
            let monthRepayments = repayments.filter { $0.dueDate >= start && $0.dueDate < end }

            let grouped = Dictionary(grouping: monthRepayments) {
                $0.debtPlan?.platform ?? "未关联平台"
            }
            let platforms = grouped
                .map { platform, items in
                    PlatformBreakdown(
                        platform: platform,
                        cents: items.reduce(0) { $0 + $1.amountCents },
                        repaymentIds: items.map { PersistentIdentifierBox($0.persistentModelID) }
                    )
                }
                .sorted { $0.cents > $1.cents }

            let monthExpenses = activeExpenses.filter { $0.isActive(in: start, calendar: calendar) }
            let expenseLines = monthExpenses
                .map { ExpenseLine(
                    category: $0.category,
                    cents: $0.amountCents,
                    expenseId: PersistentIdentifierBox($0.persistentModelID)
                ) }
                .sorted { $0.cents > $1.cents }

            return MonthSummary(
                month: start,
                incomeCents: monthSalaries.reduce(0) { $0 + $1.amountCents },
                repaymentCents: monthRepayments.reduce(0) { $0 + $1.amountCents },
                expenseCents: monthExpenses.reduce(0) { $0 + $1.amountCents },
                salaryIds: monthSalaries.map { PersistentIdentifierBox($0.persistentModelID) },
                platforms: platforms,
                expenseLines: expenseLines,
                isCurrentMonth: start == nowStart
            )
        }
    }
}
