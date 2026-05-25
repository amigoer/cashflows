import SwiftUI

struct SalaryRow: View {
    let salary: Salary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(DateFormat.long(salary.paidAt))
                    .font(.body)
                Text(metadataLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let note = salary.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            AmountText(cents: salary.amountCents, tone: .income, size: .large)
        }
        .padding(.vertical, 4)
    }

    private var metadataLine: String {
        var parts: [String] = [salary.period.displayName]
        if salary.hasBreakdown {
            parts.append("税前 \(Money.format(cents: salary.grossAmountCents))")
        }
        return parts.joined(separator: " · ")
    }
}
