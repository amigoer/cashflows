import Foundation
import SwiftData

struct ExportPayload: Codable {
    static let currentVersion = 2

    var version: Int
    var exportedAt: Date
    var salaries: [SalaryDTO]
    var debtPlans: [DebtPlanDTO]
    var repayments: [RepaymentDTO]
    var recurringExpenses: [RecurringExpenseDTO]
}

struct SalaryDTO: Codable, Identifiable {
    var id: UUID
    var amountCents: Int
    var paidAt: Date
    var period: String
    var note: String?
    var createdAt: Date
    // v2+ optional breakdown
    var grossAmountCents: Int?
    var socialInsuranceCents: Int?
    var housingFundCents: Int?
    var incomeTaxCents: Int?
    var additionalDeductionCents: Int?
    var otherDeductionCents: Int?
}

struct DebtPlanDTO: Codable, Identifiable {
    var id: UUID
    var platform: String
    var principalCents: Int
    var totalPeriods: Int
    var monthlyPaymentCents: Int
    var firstDueDate: Date
    var aprBps: Int
    var note: String?
    var archived: Bool
    var createdAt: Date
}

struct RepaymentDTO: Codable, Identifiable {
    var id: UUID
    var debtPlanId: UUID
    var periodIndex: Int
    var dueDate: Date
    var amountCents: Int
    var status: String
    var paidAt: Date?
}

struct RecurringExpenseDTO: Codable, Identifiable {
    var id: UUID
    var category: String
    var amountCents: Int
    var startMonth: Date
    var endMonth: Date?
    var note: String?
    var archived: Bool
    var createdAt: Date
}

@MainActor
enum ExportService {
    static func collect(from context: ModelContext) throws -> ExportPayload {
        let salaries = try context.fetch(FetchDescriptor<Salary>())
        let debtPlans = try context.fetch(FetchDescriptor<DebtPlan>())
        let repayments = try context.fetch(FetchDescriptor<Repayment>())
        let expenses = try context.fetch(FetchDescriptor<RecurringExpense>())

        let salaryDtos = salaries.map {
            SalaryDTO(
                id: UUID(),
                amountCents: $0.amountCents,
                paidAt: $0.paidAt,
                period: $0.period.rawValue,
                note: $0.note,
                createdAt: $0.createdAt,
                grossAmountCents: $0.grossAmountCents > 0 ? $0.grossAmountCents : nil,
                socialInsuranceCents: $0.socialInsuranceCents > 0 ? $0.socialInsuranceCents : nil,
                housingFundCents: $0.housingFundCents > 0 ? $0.housingFundCents : nil,
                incomeTaxCents: $0.incomeTaxCents > 0 ? $0.incomeTaxCents : nil,
                additionalDeductionCents: $0.additionalDeductionCents > 0 ? $0.additionalDeductionCents : nil,
                otherDeductionCents: $0.otherDeductionCents > 0 ? $0.otherDeductionCents : nil
            )
        }

        var planIdMap: [PersistentIdentifier: UUID] = [:]
        let planDtos = debtPlans.map { p -> DebtPlanDTO in
            let id = UUID()
            planIdMap[p.persistentModelID] = id
            return DebtPlanDTO(
                id: id,
                platform: p.platform,
                principalCents: p.principalCents,
                totalPeriods: p.totalPeriods,
                monthlyPaymentCents: p.monthlyPaymentCents,
                firstDueDate: p.firstDueDate,
                aprBps: p.aprBps,
                note: p.note,
                archived: p.archived,
                createdAt: p.createdAt
            )
        }

        let repaymentDtos = repayments.compactMap { r -> RepaymentDTO? in
            guard let planId = r.debtPlan?.persistentModelID, let dtoId = planIdMap[planId] else {
                return nil
            }
            return RepaymentDTO(
                id: UUID(),
                debtPlanId: dtoId,
                periodIndex: r.periodIndex,
                dueDate: r.dueDate,
                amountCents: r.amountCents,
                status: r.status.rawValue,
                paidAt: r.paidAt
            )
        }

        let expenseDtos = expenses.map {
            RecurringExpenseDTO(
                id: UUID(),
                category: $0.category,
                amountCents: $0.amountCents,
                startMonth: $0.startMonth,
                endMonth: $0.endMonth,
                note: $0.note,
                archived: $0.archived,
                createdAt: $0.createdAt
            )
        }

        return ExportPayload(
            version: ExportPayload.currentVersion,
            exportedAt: .now,
            salaries: salaryDtos,
            debtPlans: planDtos,
            repayments: repaymentDtos,
            recurringExpenses: expenseDtos
        )
    }

    static func encodeJson(_ payload: ExportPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    static func decodeJson(_ data: Data) throws -> ExportPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportPayload.self, from: data)
    }

    static func encodeCsv(_ payload: ExportPayload) -> String {
        var lines: [String] = []
        let iso = ISO8601DateFormatter()

        lines.append("# salaries")
        lines.append("id,amount_cents,paid_at,period,note,created_at")
        for s in payload.salaries {
            lines.append([
                s.id.uuidString,
                String(s.amountCents),
                iso.string(from: s.paidAt),
                s.period,
                csvEscape(s.note ?? ""),
                iso.string(from: s.createdAt),
            ].joined(separator: ","))
        }
        lines.append("")
        lines.append("# debt_plans")
        lines.append("id,platform,principal_cents,total_periods,monthly_payment_cents,first_due_date,apr_bps,note,archived,created_at")
        for p in payload.debtPlans {
            lines.append([
                p.id.uuidString,
                csvEscape(p.platform),
                String(p.principalCents),
                String(p.totalPeriods),
                String(p.monthlyPaymentCents),
                iso.string(from: p.firstDueDate),
                String(p.aprBps),
                csvEscape(p.note ?? ""),
                p.archived ? "true" : "false",
                iso.string(from: p.createdAt),
            ].joined(separator: ","))
        }
        lines.append("")
        lines.append("# repayments")
        lines.append("id,debt_plan_id,period_index,due_date,amount_cents,status,paid_at")
        for r in payload.repayments {
            lines.append([
                r.id.uuidString,
                r.debtPlanId.uuidString,
                String(r.periodIndex),
                iso.string(from: r.dueDate),
                String(r.amountCents),
                r.status,
                r.paidAt.map { iso.string(from: $0) } ?? "",
            ].joined(separator: ","))
        }
        lines.append("")
        lines.append("# recurring_expenses")
        lines.append("id,category,amount_cents,start_month,end_month,note,archived,created_at")
        for e in payload.recurringExpenses {
            lines.append([
                e.id.uuidString,
                csvEscape(e.category),
                String(e.amountCents),
                iso.string(from: e.startMonth),
                e.endMonth.map { iso.string(from: $0) } ?? "",
                csvEscape(e.note ?? ""),
                e.archived ? "true" : "false",
                iso.string(from: e.createdAt),
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(where: { ",\"\n\r".contains($0) }) {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    static func restore(from payload: ExportPayload, into context: ModelContext) throws {
        // Fetch + iterate so SwiftData walks cascade / nullify-inverse rules.
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

        for s in payload.salaries {
            let period = SalaryPeriod(rawValue: s.period) ?? .monthly
            let model = Salary(
                amountCents: s.amountCents,
                paidAt: s.paidAt,
                period: period,
                note: s.note,
                createdAt: s.createdAt,
                grossAmountCents: s.grossAmountCents ?? 0,
                socialInsuranceCents: s.socialInsuranceCents ?? 0,
                housingFundCents: s.housingFundCents ?? 0,
                incomeTaxCents: s.incomeTaxCents ?? 0,
                additionalDeductionCents: s.additionalDeductionCents ?? 0,
                otherDeductionCents: s.otherDeductionCents ?? 0
            )
            context.insert(model)
        }

        var dtoToPlan: [UUID: DebtPlan] = [:]
        for p in payload.debtPlans {
            let model = DebtPlan(
                platform: p.platform,
                principalCents: p.principalCents,
                totalPeriods: p.totalPeriods,
                monthlyPaymentCents: p.monthlyPaymentCents,
                firstDueDate: p.firstDueDate,
                aprBps: p.aprBps,
                note: p.note,
                archived: p.archived,
                createdAt: p.createdAt
            )
            context.insert(model)
            dtoToPlan[p.id] = model
        }

        for r in payload.repayments {
            guard let plan = dtoToPlan[r.debtPlanId] else { continue }
            let status = RepaymentStatus(rawValue: r.status) ?? .pending
            let model = Repayment(
                periodIndex: r.periodIndex,
                dueDate: r.dueDate,
                amountCents: r.amountCents,
                status: status,
                paidAt: r.paidAt
            )
            model.debtPlan = plan
            context.insert(model)
        }

        for e in payload.recurringExpenses {
            context.insert(RecurringExpense(
                category: e.category,
                amountCents: e.amountCents,
                startMonth: e.startMonth,
                endMonth: e.endMonth,
                note: e.note,
                archived: e.archived,
                createdAt: e.createdAt
            ))
        }

        try context.save()
    }
}
