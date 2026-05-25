import SwiftData
import SwiftUI

/// List body only (no NavigationStack / toolbar / sheets).
/// Designed to be embedded inside OutflowsTabView's segmented control.
/// Relies on the host providing a `navigationDestination(for: DebtPlan.self)`.
struct DebtListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<DebtPlan> { !$0.archived },
        sort: [SortDescriptor(\DebtPlan.platform), SortDescriptor(\DebtPlan.createdAt, order: .reverse)]
    )
    private var plans: [DebtPlan]

    var onImportTap: () -> Void
    var onManualAddTap: () -> Void

    var body: some View {
        Group {
            if plans.isEmpty {
                EmptyState(
                    title: "还没有债务记录",
                    description: "上传截图自动识别，或手动录入分期信息。",
                    systemImage: "creditcard",
                    action: onImportTap,
                    actionLabel: "从截图导入"
                )
            } else {
                List {
                    ForEach(plans) { plan in
                        NavigationLink(value: plan) {
                            DebtRow(plan: plan)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(plan)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}
