import SwiftData
import SwiftUI

/// List body only (no NavigationStack / toolbar). Designed to be embedded inside
/// the OutflowsTabView's segmented control.
struct RecurringExpenseListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<RecurringExpense> { !$0.archived },
        sort: [SortDescriptor(\RecurringExpense.startMonth, order: .reverse)]
    )
    private var expenses: [RecurringExpense]

    @Binding var presentedExpense: RecurringExpense?
    var onAddTap: () -> Void

    var body: some View {
        Group {
            if expenses.isEmpty {
                EmptyState(
                    title: "还没有固定开销",
                    description: "录入房租、水电、话费等每月固定支出，CashFlows 会把它们计入每月的现金流。",
                    systemImage: "house.fill",
                    action: onAddTap,
                    actionLabel: "添加固定开销"
                )
            } else {
                List {
                    Section {
                        ForEach(expenses) { expense in
                            Button {
                                presentedExpense = expense
                            } label: {
                                RecurringExpenseRow(expense: expense)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    modelContext.delete(expense)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    } footer: {
                        Text("总计每月 \(Money.format(cents: monthlyTotal)) · 共 \(expenses.count) 项")
                            .font(.footnote)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private var monthlyTotal: Int {
        expenses.reduce(0) { $0 + $1.amountCents }
    }
}
