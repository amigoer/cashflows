import SwiftUI

struct OverviewHeader: View {
    let overview: DebtOverview
    var onTapDebt: () -> Void = {}

    var body: some View {
        VStack(spacing: 12) {
            cashflowHero
            debtCard
        }
    }

    // MARK: - 本月现金流 (hero)

    private var cashflowHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("本月现金流", systemImage: "arrow.left.arrow.right.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text(DateFormat.yearMonth(.now))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                AmountText(
                    cents: overview.thisMonthNetCents,
                    tone: overview.thisMonthNetCents >= 0 ? .income : .expense,
                    size: .hero,
                    signed: true
                )
                Text(overview.thisMonthNetCents >= 0 ? "净流入" : "净流出")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            Divider().padding(.vertical, 16)

            HStack(spacing: 0) {
                cashflowStat(
                    label: "收入",
                    cents: overview.thisMonthIncomeCents,
                    color: .green
                )
                Divider().frame(height: 34).padding(.horizontal, 4)
                cashflowStat(
                    label: "还款",
                    cents: overview.thisMonthRepaymentCents,
                    color: .pink
                )
                Divider().frame(height: 34).padding(.horizontal, 4)
                cashflowStat(
                    label: "开销",
                    cents: overview.thisMonthExpenseCents,
                    color: .orange
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(Color.accentColor.opacity(0.10)), in: .rect(cornerRadius: 22))
    }

    private func cashflowStat(label: String, cents: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(Money.format(cents: cents))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(cents == 0 ? .secondary : color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 剩余总欠款 (debt summary card)

    private var debtCard: some View {
        Button(action: onTapDebt) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("剩余总欠款", systemImage: "creditcard")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    AmountText(cents: overview.totalRemainingCents, tone: .neutral, size: .large)
                    HStack(spacing: 8) {
                        if overview.nextMonthDueCents > 0 {
                            metaLabel("下月待还 \(Money.format(cents: overview.nextMonthDueCents))")
                        }
                        if let date = overview.payoffDate {
                            metaLabel("预计 \(DateFormat.yearMonth(date)) 还清")
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(Color.pink.opacity(0.10)), in: .rect(cornerRadius: 20))
    }

    private func metaLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
}

#Preview {
    ScrollView {
        OverviewHeader(overview: DebtOverview(
            thisMonthIncomeCents: 10_000_00,
            thisMonthRepaymentCents: 3_500_00,
            thisMonthExpenseCents: 5_900_00,
            totalRemainingCents: 45_680_00,
            totalPaidCents: 12_000_00,
            nextMonthDueCents: 3_500_00,
            activePlatformCount: 6,
            pendingPeriodsCount: 56,
            paidPeriodsCount: 15,
            totalPeriodsCount: 71,
            payoffDate: Calendar.current.date(byAdding: .month, value: 28, to: .now),
            monthsToPayoff: 28,
            totalIncomeCents: 40_000_00,
            monthlyRecurringExpenseCents: 5_900_00
        ))
        .padding(16)
    }
    .background(Color(.systemGroupedBackground))
}
