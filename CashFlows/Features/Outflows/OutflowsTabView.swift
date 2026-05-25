import SwiftData
import SwiftUI

enum OutflowSection: String, CaseIterable, Identifiable {
    case debts = "债务"
    case expenses = "固定开销"

    var id: String { rawValue }
}

struct OutflowsTabView: View {
    @State private var section: OutflowSection = .debts

    @State private var showNewDebt = false
    @State private var showImport = false
    @State private var showNewExpense = false
    @State private var editingExpense: RecurringExpense?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("分组", selection: $section) {
                    ForEach(OutflowSection.allCases) { sec in
                        Text(sec.rawValue).tag(sec)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)

                contentView
            }
            .navigationTitle("支出")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    addMenu
                }
            }
            .navigationDestination(for: DebtPlan.self) { plan in
                DebtDetailView(plan: plan)
            }
            .sheet(isPresented: $showNewDebt) {
                NavigationStack { DebtFormView() }
            }
            .sheet(isPresented: $showImport) {
                ImportScreenshotFlow()
            }
            .sheet(isPresented: $showNewExpense) {
                NavigationStack { RecurringExpenseFormView() }
            }
            .sheet(item: $editingExpense) { exp in
                NavigationStack { RecurringExpenseFormView(expense: exp) }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch section {
        case .debts:
            DebtListContent(
                onImportTap: { showImport = true },
                onManualAddTap: { showNewDebt = true }
            )
        case .expenses:
            RecurringExpenseListContent(
                presentedExpense: $editingExpense,
                onAddTap: { showNewExpense = true }
            )
        }
    }

    @ViewBuilder
    private var addMenu: some View {
        switch section {
        case .debts:
            Menu {
                Button { showImport = true } label: {
                    Label("从截图识别", systemImage: "doc.text.viewfinder")
                }
                Button { showNewDebt = true } label: {
                    Label("手动录入", systemImage: "square.and.pencil")
                }
            } label: {
                Label("新增", systemImage: "plus")
            }
        case .expenses:
            Button { showNewExpense = true } label: {
                Label("新增", systemImage: "plus")
            }
        }
    }
}

#Preview {
    OutflowsTabView()
        .modelContainer(for: [DebtPlan.self, Repayment.self, RecurringExpense.self], inMemory: true)
}
