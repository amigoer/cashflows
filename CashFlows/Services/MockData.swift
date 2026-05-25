import Foundation
import SwiftData

@MainActor
enum MockData {
    /// Wipes the store, then inserts a realistic 18-month worth of cash flow
    /// starting May 2026: 3 real installment debts + 4 recurring fixed expenses
    /// + monthly salary entries with seasonal bonuses.
    static func resetWithSamples(in context: ModelContext) throws {
        try wipeAll(in: context)
        try context.save() // ensure deletions are flushed before reseeding

        let cal = Calendar.current

        // ───── Salaries: 18 monthly entries starting May 2026, with realistic deductions ─────
        let salaryStart = cal.date(from: DateComponents(year: 2026, month: 5, day: 5))!
        for offset in 0..<18 {
            guard let date = cal.date(byAdding: .month, value: offset, to: salaryStart) else { continue }
            let month = cal.component(.month, from: date)

            // Deductions roughly tracking real-life China payroll for a ~15K gross.
            let baseGross: Int
            let baseSocial: Int
            let baseFund: Int
            let baseTax: Int
            let baseExtra: Int  // 专项附加（房租 + 赡养老人 等）
            let note: String?
            switch month {
            case 12:
                baseGross = 27_000_00; baseSocial = 2_700_00; baseFund = 3_240_00
                baseTax = 1_800_00; baseExtra = 1_200_00
                note = "月薪 + 年终奖"
            case 7:
                baseGross = 22_500_00; baseSocial = 2_250_00; baseFund = 2_700_00
                baseTax = 1_300_00; baseExtra = 1_200_00
                note = "月薪 + 半年奖"
            default:
                baseGross = 15_000_00; baseSocial = 1_500_00; baseFund = 1_800_00
                baseTax = 500_00; baseExtra = 1_200_00
                note = nil
            }
            let net = baseGross - baseSocial - baseFund - baseTax - baseExtra
            context.insert(Salary(
                amountCents: net,
                paidAt: date,
                period: .monthly,
                note: note,
                grossAmountCents: baseGross,
                socialInsuranceCents: baseSocial,
                housingFundCents: baseFund,
                incomeTaxCents: baseTax,
                additionalDeductionCents: baseExtra,
                otherDeductionCents: 0
            ))
        }

        // ───── Real installments (DebtPlan) ─────
        struct DebtSeed {
            let platform: String
            let principal: Int
            let periods: Int
            let monthly: Int
            let firstDueDay: Int
            let note: String?
        }

        let debts: [DebtSeed] = [
            .init(platform: "花呗",
                  principal: 9_600_00, periods: 12, monthly: 800_00,
                  firstDueDay: 10, note: "iPhone 16 Pro 分期"),
            .init(platform: "京东白条",
                  principal: 7_200_00, periods: 6, monthly: 1_200_00,
                  firstDueDay: 20, note: "MacBook 周边"),
            .init(platform: "招商银行信用卡",
                  principal: 36_000_00, periods: 24, monthly: 1_500_00,
                  firstDueDay: 15, note: "家装分期"),
        ]

        let baseMonth = cal.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let now = Date.now

        for seed in debts {
            var comps = cal.dateComponents([.year, .month], from: baseMonth)
            comps.day = seed.firstDueDay
            guard let firstDue = cal.date(from: comps) else { continue }

            let plan = DebtPlan(
                platform: seed.platform,
                principalCents: seed.principal,
                totalPeriods: seed.periods,
                monthlyPaymentCents: seed.monthly,
                firstDueDate: firstDue,
                aprBps: 0,
                note: seed.note
            )
            context.insert(plan)

            let repayments = RepaymentScheduler.generate(
                totalPeriods: seed.periods,
                monthlyPaymentCents: seed.monthly,
                firstDueDate: firstDue
            )
            for r in repayments {
                if r.dueDate < now {
                    r.status = .paid
                    r.paidAt = r.dueDate
                }
                r.debtPlan = plan
                context.insert(r)
            }
        }

        // ───── Recurring fixed expenses (RecurringExpense) ─────
        struct ExpenseSeed {
            let category: String
            let amount: Int
            let note: String?
        }

        let expenses: [ExpenseSeed] = [
            .init(category: "房租", amount: 3_500_00, note: "月租"),
            .init(category: "水电燃气", amount: 300_00, note: nil),
            .init(category: "餐饮", amount: 2_000_00, note: "餐饮预算"),
            .init(category: "话费 / 网费", amount: 100_00, note: "套餐"),
        ]

        for seed in expenses {
            context.insert(RecurringExpense(
                category: seed.category,
                amountCents: seed.amount,
                startMonth: baseMonth,
                endMonth: nil,
                note: seed.note
            ))
        }

        try context.save()
    }

    /// Wipes everything. Fetches + iterates to delete (rather than the batch
    /// `context.delete(model:)`) so SwiftData properly walks cascade /
    /// nullify-inverse rules between DebtPlan and Repayment.
    static func wipeAll(in context: ModelContext) throws {
        for r in try context.fetch(FetchDescriptor<Repayment>()) {
            context.delete(r)
        }
        for p in try context.fetch(FetchDescriptor<DebtPlan>()) {
            context.delete(p)
        }
        for s in try context.fetch(FetchDescriptor<Salary>()) {
            context.delete(s)
        }
        for e in try context.fetch(FetchDescriptor<RecurringExpense>()) {
            context.delete(e)
        }
        try context.save()
    }
}
