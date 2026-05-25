import SwiftUI

struct RecurringExpenseRow: View {
    let expense: RecurringExpense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: ExpenseCategory.symbol(for: expense.category))
                .font(.callout)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.15), in: .rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category).font(.body)
                Text(rangeLabel).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            AmountText(cents: expense.amountCents, tone: .expense, size: .medium)
            Text("/月").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var rangeLabel: String {
        let start = DateFormat.yearMonth(expense.startMonth)
        if let end = expense.endMonth {
            return "\(start) — \(DateFormat.yearMonth(end))"
        }
        return "\(start) 起 · 长期"
    }
}
