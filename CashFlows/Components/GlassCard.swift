import SwiftUI

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 18
    var tint: Color? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .glassEffect(
                tint.map { .regular.tint($0.opacity(0.4)) } ?? .regular,
                in: .rect(cornerRadius: cornerRadius)
            )
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.93, green: 0.95, blue: 0.99), Color(red: 0.85, green: 0.9, blue: 0.97)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("净现金流").font(.caption).foregroundStyle(.secondary)
                    AmountText(cents: 8_888_00, tone: .income, size: .hero)
                }
            }
            .padding()
        }
    }
}
