import Foundation
import SwiftData

@Model
final class Salary {
    /// 实发金额 (net take-home). This is what hits your bank account and what
    /// the cashflow timeline treats as "income".
    var amountCents: Int
    var paidAt: Date
    var period: SalaryPeriod
    var note: String?
    var createdAt: Date

    // ── Optional gross + deductions breakdown ──
    // When `grossAmountCents == 0`, the user only entered the net amount and the
    // deduction fields are unused. When > 0, the breakdown is meaningful and
    // `amountCents == grossAmountCents - sum(deductions)`.
    var grossAmountCents: Int
    /// 社保（养老 + 医疗 + 失业 合并）
    var socialInsuranceCents: Int
    /// 公积金
    var housingFundCents: Int
    /// 个税
    var incomeTaxCents: Int
    /// 专项附加扣除（子女教育 / 房贷 / 房租 / 赡养老人 等加总）
    var additionalDeductionCents: Int
    /// 其他扣除
    var otherDeductionCents: Int

    init(
        amountCents: Int,
        paidAt: Date,
        period: SalaryPeriod = .monthly,
        note: String? = nil,
        createdAt: Date = .now,
        grossAmountCents: Int = 0,
        socialInsuranceCents: Int = 0,
        housingFundCents: Int = 0,
        incomeTaxCents: Int = 0,
        additionalDeductionCents: Int = 0,
        otherDeductionCents: Int = 0
    ) {
        self.amountCents = amountCents
        self.paidAt = paidAt
        self.period = period
        self.note = note
        self.createdAt = createdAt
        self.grossAmountCents = grossAmountCents
        self.socialInsuranceCents = socialInsuranceCents
        self.housingFundCents = housingFundCents
        self.incomeTaxCents = incomeTaxCents
        self.additionalDeductionCents = additionalDeductionCents
        self.otherDeductionCents = otherDeductionCents
    }

    var hasBreakdown: Bool { grossAmountCents > 0 }

    var totalDeductionCents: Int {
        socialInsuranceCents
            + housingFundCents
            + incomeTaxCents
            + additionalDeductionCents
            + otherDeductionCents
    }
}
