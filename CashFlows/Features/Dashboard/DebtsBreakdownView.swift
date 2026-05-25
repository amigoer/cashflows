import SwiftData
import SwiftUI

/// Pushed when the user taps the hero card on Dashboard.
/// Shows every active debt plan sorted by remaining amount (worst first).
struct DebtsBreakdownView: View {
    @Query(
        filter: #Predicate<DebtPlan> { !$0.archived },
        sort: \DebtPlan.createdAt
    )
    private var plans: [DebtPlan]

    private var sortedPlans: [DebtPlan] {
        plans.sorted { remaining($0) > remaining($1) }
    }

    private var totalRemaining: Int {
        plans.flatMap { $0.repayments }.filter { $0.status != .paid }.reduce(0) { $0 + $1.amountCents }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("剩余总欠款")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        AmountText(cents: totalRemaining, tone: .neutral, size: .hero)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }

            Section("按平台") {
                ForEach(sortedPlans) { plan in
                    NavigationLink {
                        DebtDetailView(plan: plan)
                    } label: {
                        DebtRow(plan: plan)
                    }
                }
            }
        }
        .navigationTitle("欠款明细")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func remaining(_ plan: DebtPlan) -> Int {
        plan.repayments.filter { $0.status != .paid }.reduce(0) { $0 + $1.amountCents }
    }
}

#Preview {
    NavigationStack { DebtsBreakdownView() }
        .modelContainer(for: [DebtPlan.self, Repayment.self], inMemory: true)
}
