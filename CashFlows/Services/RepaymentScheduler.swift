import Foundation

enum RepaymentScheduler {
    /// Generates an even-split monthly schedule starting from `firstDueDate`.
    static func generate(
        totalPeriods: Int,
        monthlyPaymentCents: Int,
        firstDueDate: Date,
        calendar: Calendar = .current
    ) -> [Repayment] {
        (0..<totalPeriods).map { offset in
            let due = calendar.date(byAdding: .month, value: offset, to: firstDueDate) ?? firstDueDate
            return Repayment(
                periodIndex: offset + 1,
                dueDate: due,
                amountCents: monthlyPaymentCents,
                status: .pending
            )
        }
    }
}
