import Foundation
import SwiftData

@Model
final class DebtPlan {
    var platform: String
    var principalCents: Int
    var totalPeriods: Int
    var monthlyPaymentCents: Int
    var firstDueDate: Date
    /// Annual percentage rate in basis points (e.g. 840 = 8.40%).
    var aprBps: Int
    var note: String?
    var archived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Repayment.debtPlan)
    var repayments: [Repayment] = []

    init(
        platform: String,
        principalCents: Int,
        totalPeriods: Int,
        monthlyPaymentCents: Int,
        firstDueDate: Date,
        aprBps: Int = 0,
        note: String? = nil,
        archived: Bool = false,
        createdAt: Date = .now
    ) {
        self.platform = platform
        self.principalCents = principalCents
        self.totalPeriods = totalPeriods
        self.monthlyPaymentCents = monthlyPaymentCents
        self.firstDueDate = firstDueDate
        self.aprBps = aprBps
        self.note = note
        self.archived = archived
        self.createdAt = createdAt
    }
}
