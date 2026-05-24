import SwiftUI

struct DebtRow: View {
    let plan: DebtPlan

    private var paidCount: Int {
        plan.repayments.lazy.filter { $0.status == .paid }.count
    }

    private var remainingCents: Int {
        plan.repayments.lazy.filter { $0.status != .paid }.reduce(0) { $0 + $1.amountCents }
    }

    private var progress: Double {
        guard plan.totalPeriods > 0 else { return 0 }
        return Double(paidCount) / Double(plan.totalPeriods)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.platform)
                    .font(.headline)
                Spacer()
                AmountText(cents: remainingCents, tone: .neutral, size: .medium)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.accentColor)

            HStack {
                Text("已还 \(paidCount) / \(plan.totalPeriods) 期")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("剩余")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
