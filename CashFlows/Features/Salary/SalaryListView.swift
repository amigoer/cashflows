import SwiftData
import SwiftUI

struct SalaryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Salary.paidAt, order: .reverse) private var salaries: [Salary]

    @State private var showNew = false

    var body: some View {
        NavigationStack {
            Group {
                if salaries.isEmpty {
                    EmptyState(
                        title: "还没有工资记录",
                        description: "记录每笔工资的到账时间和金额，帮你算清本月可支配现金流。",
                        systemImage: "banknote",
                        action: { showNew = true },
                        actionLabel: "添加第一笔工资"
                    )
                } else {
                    List {
                        ForEach(salaries) { salary in
                            NavigationLink(value: salary) {
                                SalaryRow(salary: salary)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(salary)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("工资")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNew = true
                    } label: {
                        Label("新增", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Salary.self) { salary in
                SalaryDetailView(salary: salary)
            }
            .sheet(isPresented: $showNew) {
                NavigationStack {
                    SalaryFormView()
                }
            }
        }
    }
}

#Preview {
    SalaryListView()
        .modelContainer(for: [Salary.self], inMemory: true)
}
