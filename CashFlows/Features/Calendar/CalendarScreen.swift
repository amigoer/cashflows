import SwiftData
import SwiftUI

struct CalendarScreen: View {
    @State private var reference: Date = .now
    @State private var selected: Date = .now

    @Query(sort: \Salary.paidAt) private var salaries: [Salary]
    @Query(sort: \Repayment.dueDate) private var repayments: [Repayment]

    private var calendar: Calendar { .current }

    private var monthInterval: DateInterval {
        calendar.dateInterval(of: .month, for: reference)
            ?? DateInterval(start: reference, duration: 0)
    }

    private var monthSalaries: [Salary] {
        salaries.filter { monthInterval.contains($0.paidAt) }
    }

    private var monthRepayments: [Repayment] {
        repayments.filter { monthInterval.contains($0.dueDate) }
    }

    private var buckets: [String: CalendarGridView.DayBuckets] {
        var map: [String: CalendarGridView.DayBuckets] = [:]
        for s in monthSalaries {
            let key = CalendarGridView.key(for: s.paidAt, in: calendar)
            var b = map[key] ?? .init(incomeCents: 0, repaymentCents: 0)
            b.incomeCents += s.amountCents
            map[key] = b
        }
        for r in monthRepayments {
            let key = CalendarGridView.key(for: r.dueDate, in: calendar)
            var b = map[key] ?? .init(incomeCents: 0, repaymentCents: 0)
            b.repaymentCents += r.amountCents
            map[key] = b
        }
        return map
    }

    private var daySalaries: [Salary] {
        salaries.filter { calendar.isDate($0.paidAt, inSameDayAs: selected) }
    }

    private var dayRepayments: [Repayment] {
        repayments.filter { calendar.isDate($0.dueDate, inSameDayAs: selected) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GlassCard(cornerRadius: 20) {
                        VStack(spacing: 12) {
                            CalendarGridView(
                                monthReference: reference,
                                selectedDate: $selected,
                                buckets: buckets
                            )
                            HStack(spacing: 18) {
                                LegendDot(color: .green, label: "收入")
                                LegendDot(color: .pink, label: "还款")
                            }
                            .padding(.top, 4)
                        }
                    }

                    sectionHeader

                    dayEventsList
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .navigationTitle("日历")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    MonthSwitcher(reference: $reference)
                }
            }
            .onChange(of: reference) { _, _ in
                if !calendar.isDate(selected, equalTo: reference, toGranularity: .month) {
                    selected = monthInterval.start
                }
            }
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text(DateFormat.long(selected))
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var dayEventsList: some View {
        if daySalaries.isEmpty && dayRepayments.isEmpty {
            Text("当日暂无现金流活动")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 24)
        } else {
            VStack(spacing: 8) {
                ForEach(daySalaries) { s in
                    eventRow(
                        badge: "收入",
                        badgeColor: .green,
                        title: s.period.displayName,
                        subtitle: s.note,
                        cents: s.amountCents,
                        tone: .income
                    )
                }
                ForEach(dayRepayments) { r in
                    eventRow(
                        badge: "还款",
                        badgeColor: .pink,
                        title: r.debtPlan?.platform ?? "—",
                        subtitle: "第 \(r.periodIndex) 期 · \(r.status == .paid ? "已还" : "待还")",
                        cents: r.amountCents,
                        tone: .expense
                    )
                }
            }
        }
    }

    private func eventRow(
        badge: String,
        badgeColor: Color,
        title: String,
        subtitle: String?,
        cents: Int,
        tone: AmountText.Tone
    ) -> some View {
        HStack(spacing: 12) {
            Text(badge)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(badgeColor.opacity(0.18), in: .capsule)
                .foregroundStyle(badgeColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            AmountText(cents: cents, tone: tone, size: .medium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    CalendarScreen()
        .modelContainer(for: [Salary.self, DebtPlan.self, Repayment.self], inMemory: true)
}
