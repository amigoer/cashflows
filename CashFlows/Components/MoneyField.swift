import SwiftUI

struct MoneyField: View {
    @Binding var cents: Int?
    var placeholder: String = "0.00"

    @State private var text: String = ""

    var body: some View {
        HStack(spacing: 6) {
            Text("¥")
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .onAppear {
                    if let cents { text = String(format: "%.2f", Double(cents) / 100) }
                }
                .onChange(of: text) { _, newValue in
                    let cleaned = newValue.filter { "0123456789.".contains($0) }
                    if cleaned != newValue { text = cleaned; return }
                    cents = Money.parse(cleaned)
                }
        }
        .padding(.vertical, 6)
    }
}
