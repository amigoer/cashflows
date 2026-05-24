import Foundation
import SwiftData

@Model
final class Repayment {
    var periodIndex: Int
    var dueDate: Date
    var amountCents: Int
    var status: RepaymentStatus
    var paidAt: Date?

    var debtPlan: DebtPlan?

    init(
        periodIndex: Int,
        dueDate: Date,
        amountCents: Int,
        status: RepaymentStatus = .pending,
        paidAt: Date? = nil
    ) {
        self.periodIndex = periodIndex
        self.dueDate = dueDate
        self.amountCents = amountCents
        self.status = status
        self.paidAt = paidAt
    }
}
