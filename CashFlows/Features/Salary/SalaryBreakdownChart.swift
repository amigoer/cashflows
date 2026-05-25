import Charts
import SwiftUI

struct SalaryBreakdownChart: View {
    let salary: Salary

    struct Slice: Identifiable, Hashable {
        let id = UUID()
        let label: String
        let cents: Int
        let color: Color
    }

    private var slices: [Slice] {
        var result: [Slice] = []
        if salary.amountCents > 0 {
            result.append(.init(label: "实发", cents: salary.amountCents, color: .green))
        }
        if salary.socialInsuranceCents > 0 {
            result.append(.init(label: "社保", cents: salary.socialInsuranceCents, color: .blue))
        }
        if salary.housingFundCents > 0 {
            result.append(.init(label: "公积金", cents: salary.housingFundCents, color: .indigo))
        }
        if salary.incomeTaxCents > 0 {
            result.append(.init(label: "个税", cents: salary.incomeTaxCents, color: .orange))
        }
        if salary.additionalDeductionCents > 0 {
            result.append(.init(label: "专项附加", cents: salary.additionalDeductionCents, color: .teal))
        }
        if salary.otherDeductionCents > 0 {
            result.append(.init(label: "其他", cents: salary.otherDeductionCents, color: .gray))
        }
        return result
    }

    private var total: Int {
        slices.reduce(0) { $0 + $1.cents }
    }

    private func percent(of cents: Int) -> Double {
        total > 0 ? Double(cents) / Double(total) * 100 : 0
    }

    var body: some View {
        VStack(spacing: 18) {
            pieChart
            legend
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Pie

    private var pieChart: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("金额", slice.cents),
                angularInset: 0.8
            )
            .foregroundStyle(slice.color)
            .annotation(position: .overlay) {
                let pct = percent(of: slice.cents)
                if pct >= 6 {
                    Text("\(Int(pct.rounded()))%")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
                }
            }
        }
        .frame(width: 200, height: 200)
        .chartLegend(.hidden)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Legend (full-width rows)

    private var legend: some View {
        VStack(spacing: 12) {
            ForEach(slices) { slice in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(slice.color)
                        .frame(width: 10, height: 10)
                    Text(slice.label)
                        .font(.callout)
                    Spacer(minLength: 8)
                    Text(Money.format(cents: slice.cents))
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    Text(String(format: "%.1f%%", percent(of: slice.cents)))
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SalaryBreakdownChart(salary: Salary(
        amountCents: 10_000_00,
        paidAt: .now,
        grossAmountCents: 15_000_00,
        socialInsuranceCents: 1_500_00,
        housingFundCents: 1_800_00,
        incomeTaxCents: 500_00,
        additionalDeductionCents: 1_200_00,
        otherDeductionCents: 0
    ))
    .padding()
}
