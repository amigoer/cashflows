import SwiftData
import SwiftUI

struct MonthDetailView: View {
    let summary: MonthSummary

    @Query private var allSalaries: [Salary]
    @Query private var allRepayments: [Repayment]
    @Query private var allExpenses: [RecurringExpense]

    private var salaries: [Salary] {
        let ids = Set(summary.salaryIds)
        return allSalaries
            .filter { ids.contains(PersistentIdentifierBox($0.persistentModelID)) }
            .sorted { $0.paidAt < $1.paidAt }
    }

    private func repayments(for platform: PlatformBreakdown) -> [Repayment] {
        let ids = Set(platform.repaymentIds)
        return allRepayments
            .filter { ids.contains(PersistentIdentifierBox($0.persistentModelID)) }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private func expense(for line: ExpenseLine) -> RecurringExpense? {
        allExpenses.first {
            PersistentIdentifierBox($0.persistentModelID) == line.expenseId
        }
    }

    var body: some View {
        List {
            Section {
                heroCard
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if !summary.platforms.isEmpty {
                Section("本月还款") {
                    ForEach(summary.platforms) { breakdown in
                        DisclosureGroup {
                            ForEach(repayments(for: breakdown)) { r in
                                repaymentRow(r)
                            }
                        } label: {
                            platformLabel(breakdown)
                        }
                    }
                }
            }

            if !summary.expenseLines.isEmpty {
                Section("本月固定开销") {
                    ForEach(summary.expenseLines) { line in
                        expenseRow(line)
                    }
                }
            }

            if !salaries.isEmpty {
                Section("本月收入") {
                    ForEach(salaries) { s in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(DateFormat.long(s.paidAt))
                                Text(s.period.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            AmountText(cents: s.amountCents, tone: .income, size: .medium)
                        }
                    }
                }
            }

            if summary.platforms.isEmpty && salaries.isEmpty && summary.expenseLines.isEmpty {
                Section {
                    Text("当月没有任何工资 / 还款 / 开销记录。")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle(DateFormat.yearMonth(summary.month))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("净流入")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    AmountText(
                        cents: summary.netCents,
                        tone: summary.netCents >= 0 ? .income : .expense,
                        size: .hero,
                        signed: true
                    )
                }
                Spacer()
            }
            HStack(spacing: 10) {
                summaryPill(label: "收入", cents: summary.incomeCents, color: .green)
                summaryPill(label: "还款", cents: -summary.repaymentCents, color: .pink)
                summaryPill(label: "开销", cents: -summary.expenseCents, color: .orange)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 18))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func summaryPill(label: String, cents: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(Money.format(cents: cents, signed: cents < 0))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(cents >= 0 ? Color.green : color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(color.opacity(0.12), in: .rect(cornerRadius: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func platformLabel(_ breakdown: PlatformBreakdown) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(breakdown.platform).font(.body)
                Text("\(breakdown.repaymentIds.count) 期").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            AmountText(cents: breakdown.cents, tone: .expense, size: .medium)
        }
    }

    private func expenseRow(_ line: ExpenseLine) -> some View {
        let model = expense(for: line)
        return HStack(spacing: 12) {
            Image(systemName: ExpenseCategory.symbol(for: line.category))
                .font(.callout)
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.15), in: .rect(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(line.category).font(.body)
                if let note = model?.note, !note.isEmpty {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            AmountText(cents: line.cents, tone: .expense, size: .medium)
        }
    }

    private func repaymentRow(_ r: Repayment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("第 \(r.periodIndex) 期")
                Text(DateFormat.long(r.dueDate)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            AmountText(cents: r.amountCents, tone: .neutral, size: .small)
            statusBadge(r)
        }
    }

    @ViewBuilder
    private func statusBadge(_ r: Repayment) -> some View {
        switch r.status {
        case .paid:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
        case .pending:
            if r.dueDate < .now {
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.pink).font(.caption)
            } else {
                Image(systemName: "circle").foregroundStyle(.tertiary).font(.caption)
            }
        case .overdue:
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.pink).font(.caption)
        }
    }
}
