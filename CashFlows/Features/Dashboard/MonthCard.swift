import SwiftUI

struct MonthCard: View {
    let summary: MonthSummary

    private var hasActivity: Bool {
        summary.incomeCents > 0
            || summary.repaymentCents > 0
            || summary.expenseCents > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if hasActivity {
                netRow
                breakdownRow
            } else {
                Text("暂无现金流活动")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(glassTint, in: .rect(cornerRadius: 20))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text(DateFormat.yearMonth(summary.month))
                .font(.headline.weight(.semibold))
                .monospacedDigit()
            badge
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var badge: some View {
        if summary.isCurrentMonth {
            Text("本月")
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.18), in: .capsule)
                .foregroundStyle(Color.accentColor)
        } else if summary.month > .now {
            Text("未来")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12), in: .capsule)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Net + breakdown

    private var netRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            AmountText(
                cents: summary.netCents,
                tone: summary.netCents >= 0 ? .income : .expense,
                size: .large,
                signed: true
            )
            Text(summary.netCents >= 0 ? "净流入" : "净流出")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var breakdownRow: some View {
        HStack(spacing: 16) {
            if summary.incomeCents > 0 {
                inlineStat(icon: "arrow.down", cents: summary.incomeCents, color: .green)
            }
            if summary.totalOutflowCents > 0 {
                inlineStat(icon: "arrow.up", cents: summary.totalOutflowCents, color: .pink)
            }
            Spacer()
            if summary.outflowItemCount > 0 {
                Text("\(summary.outflowItemCount) 项支出")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func inlineStat(icon: String, cents: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(Money.format(cents: cents))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(color)
    }

    private var glassTint: Glass {
        if summary.isCurrentMonth {
            return .regular.tint(Color.accentColor.opacity(0.08))
        }
        return .regular
    }
}
