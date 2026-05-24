import SwiftUI

struct MonthSwitcher: View {
    @Binding var reference: Date

    var body: some View {
        HStack(spacing: 6) {
            Button {
                shift(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.callout.weight(.semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.mini)

            Text(DateFormat.yearMonth(reference))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(minWidth: 92)

            Button {
                shift(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.callout.weight(.semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.mini)
        }
    }

    private func shift(by months: Int) {
        let cal = Calendar.current
        if let next = cal.date(byAdding: .month, value: months, to: reference) {
            reference = next
        }
    }
}
