import Foundation

/// Cross-month totals shown at the top of the Dashboard.
struct DebtOverview {
    // Cashflow this month
    let thisMonthIncomeCents: Int
    let thisMonthRepaymentCents: Int
    let thisMonthExpenseCents: Int

    // Debt status
    let totalRemainingCents: Int
    let totalPaidCents: Int
    let nextMonthDueCents: Int
    let activePlatformCount: Int
    let pendingPeriodsCount: Int
    let paidPeriodsCount: Int
    let totalPeriodsCount: Int
    let payoffDate: Date?
    let monthsToPayoff: Int?

    // Running totals
    let totalIncomeCents: Int
    let monthlyRecurringExpenseCents: Int

    var thisMonthOutflowCents: Int { thisMonthRepaymentCents + thisMonthExpenseCents }
    var thisMonthNetCents: Int { thisMonthIncomeCents - thisMonthOutflowCents }

    var totalNetCashflowCents: Int {
        totalIncomeCents - totalPaidCents
    }

    var progress: Double {
        guard totalPeriodsCount > 0 else { return 0 }
        return Double(paidPeriodsCount) / Double(totalPeriodsCount)
    }

    var isEmpty: Bool {
        totalRemainingCents == 0
            && totalPaidCents == 0
            && totalIncomeCents == 0
            && monthlyRecurringExpenseCents == 0
    }

    static let empty = DebtOverview(
        thisMonthIncomeCents: 0,
        thisMonthRepaymentCents: 0,
        thisMonthExpenseCents: 0,
        totalRemainingCents: 0,
        totalPaidCents: 0,
        nextMonthDueCents: 0,
        activePlatformCount: 0,
        pendingPeriodsCount: 0,
        paidPeriodsCount: 0,
        totalPeriodsCount: 0,
        payoffDate: nil,
        monthsToPayoff: nil,
        totalIncomeCents: 0,
        monthlyRecurringExpenseCents: 0
    )
}

enum DebtOverviewBuilder {
    static func build(
        salaries: [Salary],
        repayments: [Repayment],
        debtPlans: [DebtPlan],
        recurringExpenses: [RecurringExpense],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> DebtOverview {
        let pending = repayments.filter { $0.status != .paid }
        let paid = repayments.filter { $0.status == .paid }

        let thisMonthRange = calendar.dateInterval(of: .month, for: now)
        let nextMonthRange = calendar
            .date(byAdding: .month, value: 1, to: now)
            .flatMap { calendar.dateInterval(of: .month, for: $0) }

        let thisMonthRepayments = repayments.filter {
            guard let range = thisMonthRange else { return false }
            return range.contains($0.dueDate)
        }
        let thisMonthSalaries = salaries.filter {
            guard let range = thisMonthRange else { return false }
            return range.contains($0.paidAt)
        }
        let nextMonthDue = pending.filter {
            guard let range = nextMonthRange else { return false }
            return range.contains($0.dueDate)
        }

        let activeExpenses = recurringExpenses.filter { !$0.archived }
        let thisMonthExpenses = activeExpenses.filter { $0.isActive(in: now, calendar: calendar) }
        let monthlyRecurring = thisMonthExpenses.reduce(0) { $0 + $1.amountCents }

        let activePlatforms = Set(debtPlans.filter { !$0.archived }.map(\.platform))

        let payoffDate = pending.map(\.dueDate).max()
        let monthsToPayoff: Int? = payoffDate.flatMap { date in
            let comps = calendar.dateComponents([.month], from: now, to: date)
            return max(0, comps.month ?? 0)
        }

        return DebtOverview(
            thisMonthIncomeCents: thisMonthSalaries.reduce(0) { $0 + $1.amountCents },
            thisMonthRepaymentCents: thisMonthRepayments.reduce(0) { $0 + $1.amountCents },
            thisMonthExpenseCents: monthlyRecurring,
            totalRemainingCents: pending.reduce(0) { $0 + $1.amountCents },
            totalPaidCents: paid.reduce(0) { $0 + $1.amountCents },
            nextMonthDueCents: nextMonthDue.reduce(0) { $0 + $1.amountCents },
            activePlatformCount: activePlatforms.count,
            pendingPeriodsCount: pending.count,
            paidPeriodsCount: paid.count,
            totalPeriodsCount: repayments.count,
            payoffDate: payoffDate,
            monthsToPayoff: monthsToPayoff,
            totalIncomeCents: salaries.reduce(0) { $0 + $1.amountCents },
            monthlyRecurringExpenseCents: monthlyRecurring
        )
    }
}
