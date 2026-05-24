import SwiftUI

struct CalendarGridView: View {
    let monthReference: Date
    @Binding var selectedDate: Date
    /// Keys are "yyyy-M-d" derived from `Calendar.current`. Values are per-day buckets.
    let buckets: [String: DayBuckets]

    struct DayBuckets: Equatable {
        var incomeCents: Int
        var repaymentCents: Int
    }

    private static let weekdayLabels = ["一", "二", "三", "四", "五", "六", "日"]

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        return cal
    }

    private var gridDays: [Date] {
        guard let monthStart = calendar.dateInterval(of: .month, for: monthReference)?.start,
              let monthEnd = calendar.dateInterval(of: .month, for: monthReference)?.end
        else { return [] }
        let weekStart = calendar.dateInterval(of: .weekOfMonth, for: monthStart)?.start ?? monthStart
        let lastDay = calendar.date(byAdding: .day, value: -1, to: monthEnd) ?? monthEnd
        let weekEnd = calendar.dateInterval(of: .weekOfMonth, for: lastDay)?.end ?? monthEnd
        var days: [Date] = []
        var cursor = weekStart
        while cursor < weekEnd {
            days.append(cursor)
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? weekEnd
        }
        return days
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                ForEach(Self.weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(gridDays, id: \.self) { day in
                    DayCell(
                        date: day,
                        inMonth: calendar.isDate(day, equalTo: monthReference, toGranularity: .month),
                        isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(day),
                        bucket: buckets[Self.key(for: day, in: calendar)]
                    ) {
                        selectedDate = day
                    }
                }
            }
        }
    }

    static func key(for date: Date, in calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}

private struct DayCell: View {
    let date: Date
    let inMonth: Bool
    let isSelected: Bool
    let isToday: Bool
    let bucket: CalendarGridView.DayBuckets?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                        .frame(width: 32, height: 32)
                    Circle()
                        .strokeBorder(isToday && !isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 15, weight: isToday || isSelected ? .bold : .regular, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(textColor)
                }
                HStack(spacing: 3) {
                    if let bucket, bucket.incomeCents > 0 {
                        Circle().fill(Color.green).frame(width: 4, height: 4)
                    }
                    if let bucket, bucket.repaymentCents > 0 {
                        Circle().fill(Color.pink).frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    private var textColor: Color {
        if isSelected { return .white }
        if isToday { return .accentColor }
        return inMonth ? .primary : Color(.tertiaryLabel)
    }
}
