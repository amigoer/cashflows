import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var notificationConfig = NotificationConfig.shared

    var body: some View {
        TabView {
            Tab("总览", systemImage: "chart.pie") {
                DashboardView()
            }
            Tab("工资", systemImage: "banknote") {
                SalaryListView()
            }
            Tab("支出", systemImage: "creditcard") {
                OutflowsTabView()
            }
            Tab("日历", systemImage: "calendar") {
                CalendarScreen()
            }
            Tab("设置", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .task {
            await refreshNotificationsIfNeeded()
        }
    }

    private func refreshNotificationsIfNeeded() async {
        guard notificationConfig.repaymentRemindersEnabled else {
            await NotificationService.cancelAll()
            return
        }
        let repayments = (try? modelContext.fetch(FetchDescriptor<Repayment>())) ?? []
        await NotificationService.rescheduleAll(
            repayments: repayments,
            leadDays: notificationConfig.leadDays
        )
    }
}

#Preview {
    RootView()
        .modelContainer(
            for: [Salary.self, DebtPlan.self, Repayment.self, RecurringExpense.self],
            inMemory: true
        )
}
