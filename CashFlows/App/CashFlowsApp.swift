import SwiftData
import SwiftUI

@main
struct CashFlowsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Salary.self, DebtPlan.self, Repayment.self, RecurringExpense.self])
    }
}
