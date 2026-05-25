import SwiftUI

struct RootView: View {
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
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Salary.self, DebtPlan.self, Repayment.self], inMemory: true)
}
