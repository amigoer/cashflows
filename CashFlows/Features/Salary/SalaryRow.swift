import SwiftUI

struct SalaryRow: View {
    let salary: Salary

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(DateFormat.long(salary.paidAt))
                    .font(.body)
                HStack(spacing: 8) {
                    Text(salary.period.displayName)
                    if let note = salary.note, !note.isEmpty {
                        Text("·").foregroundStyle(.tertiary)
                        Text(note).lineLimit(1)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            AmountText(cents: salary.amountCents, tone: .income, size: .large)
        }
        .padding(.vertical, 4)
    }
}
