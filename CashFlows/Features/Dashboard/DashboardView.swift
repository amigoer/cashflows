import SwiftData
import SwiftUI

struct DashboardView: View {
    @State private var reference: Date = .now

    @Query(sort: \Salary.paidAt) private var salaries: [Salary]
    @Query(sort: \Repayment.dueDate) private var repayments: [Repayment]
    @Query(
        filter: #Predicate<DebtPlan> { !$0.archived },
        sort: \DebtPlan.platform
    )
    private var debtPlans: [DebtPlan]

    private var monthInterval: DateInterval {
        Calendar.current.dateInterval(of: .month, for: reference) ?? DateInterval(start: reference, duration: 0)
    }

    private var monthSalaries: [Salary] {
        salaries.filter { monthInterval.contains($0.paidAt) }
    }

    private var monthRepayments: [Repayment] {
        repayments.filter { monthInterval.contains($0.dueDate) }
    }

    private var incomeCents: Int { monthSalaries.reduce(0) { $0 + $1.amountCents } }
    private var repaymentCents: Int { monthRepayments.reduce(0) { $0 + $1.amountCents } }
    private var netCents: Int { incomeCents - repaymentCents }

    private var hasAnyData: Bool {
        !monthSalaries.isEmpty || !monthRepayments.isEmpty || !debtPlans.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if hasAnyData {
                    ScrollView {
                        VStack(spacing: 16) {
                            heroCard
                            HStack(spacing: 12) {
                                miniCard(label: "收入", cents: incomeCents, tone: .income)
                                miniCard(label: "还款", cents: -repaymentCents, tone: .expense)
                            }
                            platformSection
                        }
                        .padding(16)
                        .padding(.bottom, 40)
                    }
                } else {
                    EmptyState(
                        title: "本月暂无数据",
                        description: "在「工资」或「债务」标签页加入你的第一条记录。",
                        systemImage: "chart.pie"
                    )
                }
            }
            .navigationTitle("总览")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    MonthSwitcher(reference: $reference)
                }
            }
        }
    }

    private var heroCard: some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(DateFormat.yearMonth(reference)) 净现金流")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                AmountText(
                    cents: netCents,
                    tone: netCents >= 0 ? .income : .expense,
                    size: .hero,
                    signed: true
                )
                Text("\(monthSalaries.count) 笔工资  ·  \(monthRepayments.count) 笔还款")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func miniCard(label: String, cents: Int, tone: AmountText.Tone) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                AmountText(cents: cents, tone: tone, size: .large)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var platformSection: some View {
        if !debtPlans.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("平台债务")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    AmountText(cents: totalRemainingCents, tone: .expense, size: .medium)
                }
                .padding(.horizontal, 4)

                GlassCard(padding: 0, cornerRadius: 18) {
                    VStack(spacing: 0) {
                        ForEach(Array(debtPlans.enumerated()), id: \.element.id) { idx, plan in
                            NavigationLink {
                                DebtDetailView(plan: plan)
                            } label: {
                                platformRow(plan: plan)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if idx < debtPlans.count - 1 {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
    }

    private func platformRow(plan: DebtPlan) -> some View {
        let paid = plan.repayments.lazy.filter { $0.status == .paid }.count
        let remaining = plan.repayments.lazy.filter { $0.status != .paid }.reduce(0) { $0 + $1.amountCents }
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.platform)
                Text("\(paid)/\(plan.totalPeriods) 期已还")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            AmountText(cents: remaining, tone: .neutral, size: .medium)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    private var totalRemainingCents: Int {
        debtPlans.flatMap { $0.repayments }
            .filter { $0.status != .paid }
            .reduce(0) { $0 + $1.amountCents }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Salary.self, DebtPlan.self, Repayment.self], inMemory: true)
}
