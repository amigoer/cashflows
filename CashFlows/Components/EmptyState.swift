import SwiftUI

struct EmptyState: View {
    let title: String
    var description: String? = nil
    var systemImage: String = "tray"
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            if let description {
                Text(description)
            }
        } actions: {
            if let action, let actionLabel {
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    EmptyState(
        title: "还没有工资记录",
        description: "记录每笔工资的到账时间和金额，帮你算清本月可支配现金流。",
        systemImage: "banknote",
        action: {},
        actionLabel: "添加第一笔工资"
    )
}
