import SwiftUI

/// Compact money input for use inside Form's `LabeledContent` rows.
/// Unlike `MoneyField`, this one doesn't render the ¥ prefix or padding —
/// it's just a right-aligned decimal TextField bound to an optional cents value.
struct InlineMoneyField: View {
    @Binding var cents: Int?
    var placeholder: String = "0.00"

    @State private var text: String = ""

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .onAppear {
                syncFromBinding()
            }
            .onChange(of: cents) { _, _ in
                syncFromBinding()
            }
            .onChange(of: text) { _, newValue in
                let cleaned = newValue.filter { "0123456789.".contains($0) }
                if cleaned != newValue {
                    text = cleaned
                    return
                }
                if cleaned.isEmpty {
                    cents = nil
                } else {
                    cents = Money.parse(cleaned)
                }
            }
    }

    private func syncFromBinding() {
        let display: String
        if let cents {
            display = String(format: "%.2f", Double(cents) / 100)
        } else {
            display = ""
        }
        if text != display {
            text = display
        }
    }
}
