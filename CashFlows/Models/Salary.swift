import Foundation
import SwiftData

@Model
final class Salary {
    var amountCents: Int
    var paidAt: Date
    var period: SalaryPeriod
    var note: String?
    var createdAt: Date

    init(
        amountCents: Int,
        paidAt: Date,
        period: SalaryPeriod = .monthly,
        note: String? = nil,
        createdAt: Date = .now
    ) {
        self.amountCents = amountCents
        self.paidAt = paidAt
        self.period = period
        self.note = note
        self.createdAt = createdAt
    }
}
