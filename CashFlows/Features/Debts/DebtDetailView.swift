import SwiftData
import SwiftUI

struct DebtDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var plan: DebtPlan

    @State private var showEdit = false

    private var sortedRepayments: [Repayment] {
        plan.repayments.sorted { $0.periodIndex < $1.periodIndex }
    }

    private var paidCount: Int { sortedRepayments.lazy.filter { $0.status == .paid }.count }

    private var remainingCents: Int {
        sortedRepayments.lazy.filter { $0.status != .paid }.reduce(0) { $0 + $1.amountCents }
    }

    private var progress: Double {
        guard plan.totalPeriods > 0 else { return 0 }
        return Double(paidCount) / Double(plan.totalPeriods)
    }

    private var nextDue: Repayment? {
        sortedRepayments.first { $0.status != .paid }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("还款进度")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(paidCount)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text(" / \(plan.totalPeriods) 期")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                        Spacer()
                        AmountText(cents: remainingCents, tone: .expense, size: .large)
                    }
                    ProgressView(value: progress).tint(.accentColor)
                    Text("剩余总金额")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }

            if let nextDue {
                Section("下次还款") {
                    HStack {
                        Text("第 \(nextDue.periodIndex) 期 · \(DateFormat.long(nextDue.dueDate))")
                        Spacer()
                        AmountText(cents: nextDue.amountCents, tone: .neutral, size: .medium)
                    }
                }
            }

            Section("还款计划") {
                ForEach(sortedRepayments) { r in
                    RepaymentRow(repayment: r, onToggle: { toggle(r) })
                }
            }
        }
        .navigationTitle(plan.platform)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Label("编辑", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            DebtFormView(plan: plan)
        }
    }

    private func toggle(_ r: Repayment) {
        if r.status == .paid {
            r.status = .pending
            r.paidAt = nil
        } else {
            r.status = .paid
            r.paidAt = .now
        }
    }
}

private struct RepaymentRow: View {
    let repayment: Repayment
    let onToggle: () -> Void

    private var isOverdue: Bool {
        repayment.status != .paid && repayment.dueDate < .now
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("第 \(repayment.periodIndex) 期 · \(DateFormat.long(repayment.dueDate))")
                    .font(.subheadline)
                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                AmountText(cents: repayment.amountCents, tone: .neutral, size: .medium)
                Button(action: onToggle) {
                    Text(repayment.status == .paid ? "撤销已还" : "标记已还")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.mini)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusLabel: String {
        if repayment.status == .paid, let paidAt = repayment.paidAt {
            return "已还于 \(DateFormat.long(paidAt))"
        }
        return isOverdue ? "已逾期" : "待还款"
    }

    private var statusColor: Color {
        if repayment.status == .paid { return .green }
        return isOverdue ? .pink : .secondary
    }
}
