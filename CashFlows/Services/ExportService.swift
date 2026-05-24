import Foundation
import SwiftData

struct ExportPayload: Codable {
    static let currentVersion = 1

    var version: Int
    var exportedAt: Date
    var salaries: [SalaryDTO]
    var debtPlans: [DebtPlanDTO]
    var repayments: [RepaymentDTO]
}

struct SalaryDTO: Codable, Identifiable {
    var id: UUID
    var amountCents: Int
    var paidAt: Date
    var period: String
    var note: String?
    var createdAt: Date
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

@MainActor
enum ExportService {
    static func collect(from context: ModelContext) throws -> ExportPayload {
        let salaries = try context.fetch(FetchDescriptor<Salary>())
        let debtPlans = try context.fetch(FetchDescriptor<DebtPlan>())
        let repayments = try context.fetch(FetchDescriptor<Repayment>())

        let salaryDtos = salaries.map {
            SalaryDTO(
                id: UUID(),
                amountCents: $0.amountCents,
                paidAt: $0.paidAt,
                period: $0.period.rawValue,
                note: $0.note,
                createdAt: $0.createdAt
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

        return ExportPayload(
            version: ExportPayload.currentVersion,
            exportedAt: .now,
            salaries: salaryDtos,
            debtPlans: planDtos,
            repayments: repaymentDtos
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
        lines.append("# salaries")
        lines.append("id,amount_cents,paid_at,period,note,created_at")
        for s in payload.salaries {
            lines.append([
                s.id.uuidString,
                String(s.amountCents),
                ISO8601DateFormatter().string(from: s.paidAt),
                s.period,
                csvEscape(s.note ?? ""),
                ISO8601DateFormatter().string(from: s.createdAt),
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
                ISO8601DateFormatter().string(from: p.firstDueDate),
                String(p.aprBps),
                csvEscape(p.note ?? ""),
                p.archived ? "true" : "false",
                ISO8601DateFormatter().string(from: p.createdAt),
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
                ISO8601DateFormatter().string(from: r.dueDate),
                String(r.amountCents),
                r.status,
                r.paidAt.map { ISO8601DateFormatter().string(from: $0) } ?? "",
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
        // Replace existing data with imported payload (full overwrite).
        try context.delete(model: Repayment.self)
        try context.delete(model: DebtPlan.self)
        try context.delete(model: Salary.self)

        for s in payload.salaries {
            let period = SalaryPeriod(rawValue: s.period) ?? .monthly
            let model = Salary(
                amountCents: s.amountCents,
                paidAt: s.paidAt,
                period: period,
                note: s.note,
                createdAt: s.createdAt
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

        try context.save()
    }
}
