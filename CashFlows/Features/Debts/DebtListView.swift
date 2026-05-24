import SwiftData
import SwiftUI

struct DebtListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<DebtPlan> { !$0.archived },
        sort: [SortDescriptor(\DebtPlan.platform), SortDescriptor(\DebtPlan.createdAt, order: .reverse)]
    )
    private var plans: [DebtPlan]

    @State private var showNew = false
    @State private var showImport = false

    var body: some View {
        NavigationStack {
            Group {
                if plans.isEmpty {
                    EmptyState(
                        title: "还没有债务记录",
                        description: "上传截图自动识别，或手动录入分期信息。",
                        systemImage: "creditcard",
                        action: { showImport = true },
                        actionLabel: "从截图导入"
                    )
                } else {
                    List {
                        ForEach(plans) { plan in
                            NavigationLink {
                                DebtDetailView(plan: plan)
                            } label: {
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
            .navigationTitle("债务")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showImport = true } label: {
                            Label("从截图识别", systemImage: "doc.text.viewfinder")
                        }
                        Button { showNew = true } label: {
                            Label("手动录入", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Label("新增", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNew) {
                NavigationStack { DebtFormView() }
            }
            .sheet(isPresented: $showImport) {
                ImportScreenshotFlow()
            }
        }
    }
}

#Preview {
    DebtListView()
        .modelContainer(for: [DebtPlan.self, Repayment.self], inMemory: true)
}
