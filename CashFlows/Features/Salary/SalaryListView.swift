import SwiftData
import SwiftUI

struct SalaryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Salary.paidAt, order: .reverse) private var salaries: [Salary]

    @State private var presentedForm: PresentedForm?

    private enum PresentedForm: Identifiable {
        case new
        case edit(Salary)

        var id: String {
            switch self {
            case .new: "new"
            case .edit(let s): "edit-\(s.persistentModelID.hashValue)"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if salaries.isEmpty {
                    EmptyState(
                        title: "还没有工资记录",
                        description: "记录每笔工资的到账时间和金额，帮你算清本月可支配现金流。",
                        systemImage: "banknote",
                        action: { presentedForm = .new },
                        actionLabel: "添加第一笔工资"
                    )
                } else {
                    List {
                        ForEach(salaries) { salary in
                            Button {
                                presentedForm = .edit(salary)
                            } label: {
                                SalaryRow(salary: salary)
                            }
                            .buttonStyle(.plain)
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
                        presentedForm = .new
                    } label: {
                        Label("新增", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $presentedForm) { item in
                NavigationStack {
                    switch item {
                    case .new:
                        SalaryFormView()
                    case .edit(let salary):
                        SalaryFormView(salary: salary)
                    }
                }
            }
        }
    }
}

#Preview {
    SalaryListView()
        .modelContainer(for: [Salary.self], inMemory: true)
}
