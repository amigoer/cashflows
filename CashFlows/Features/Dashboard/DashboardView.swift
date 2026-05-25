import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \Salary.paidAt) private var salaries: [Salary]
    @Query(sort: \Repayment.dueDate) private var repayments: [Repayment]
    @Query private var debtPlans: [DebtPlan]
    @Query private var recurringExpenses: [RecurringExpense]

    @State private var showDebtsBreakdown = false

    private var months: [MonthSummary] {
        MonthlyTimelineBuilder.build(
            salaries: salaries,
            repayments: repayments,
            recurringExpenses: recurringExpenses
        )
    }

    private var overview: DebtOverview {
        DebtOverviewBuilder.build(
            salaries: salaries,
            repayments: repayments,
            debtPlans: debtPlans,
            recurringExpenses: recurringExpenses
        )
    }

    private var isEmpty: Bool {
        overview.isEmpty
            && months.allSatisfy { $0.incomeCents == 0 && $0.repaymentCents == 0 && $0.expenseCents == 0 }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEmpty {
                    EmptyState(
                        title: "还没有现金流数据",
                        description: "录入收入、债务分期或固定开销，时间线就会自动生成。",
                        systemImage: "chart.bar.xaxis"
                    )
                } else {
                    timelineScroll
                }
            }
            .navigationTitle("总览")
            .navigationDestination(isPresented: $showDebtsBreakdown) {
                DebtsBreakdownView()
            }
        }
    }

    private var timelineScroll: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                OverviewHeader(overview: overview) {
                    showDebtsBreakdown = true
                }
                .padding(.horizontal, 16)

                sectionHeader

                ForEach(months) { summary in
                    NavigationLink {
                        MonthDetailView(summary: summary)
                    } label: {
                        MonthCard(summary: summary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 32)
            }
            .padding(.top, 4)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var sectionHeader: some View {
        HStack {
            Text("月度时间线")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Salary.self, DebtPlan.self, Repayment.self, RecurringExpense.self], inMemory: true)
}
