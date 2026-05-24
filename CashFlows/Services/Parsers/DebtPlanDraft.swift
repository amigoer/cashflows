import Foundation

struct DebtPlanDraft: Sendable {
    var platform: String
    var principalCents: Int?
    var totalPeriods: Int?
    var monthlyPaymentCents: Int?
    var firstDueDate: Date?
    var aprBps: Int?
    var note: String?
    /// Raw recognized text for user reference.
    var rawText: String

    static let empty = DebtPlanDraft(platform: "", rawText: "")
}
