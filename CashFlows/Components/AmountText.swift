import SwiftUI

struct AmountText: View {
    enum Tone {
        case neutral, income, expense, auto
    }

    enum Size {
        case small, medium, large, hero

        var font: Font {
            switch self {
            case .small: .system(size: 14, weight: .medium, design: .rounded)
            case .medium: .system(size: 17, weight: .semibold, design: .rounded)
            case .large: .system(size: 24, weight: .bold, design: .rounded)
            case .hero: .system(size: 34, weight: .bold, design: .rounded)
            }
        }
    }

    let cents: Int
    var tone: Tone = .auto
    var size: Size = .medium
    var signed: Bool = false
    var showSymbol: Bool = true

    var body: some View {
        Text(Money.format(cents: cents, showSymbol: showSymbol, signed: signed))
            .font(size.font)
            .monospacedDigit()
            .foregroundStyle(color)
    }

    private var color: Color {
        let resolved: Tone = {
            guard tone == .auto else { return tone }
            if cents > 0 { return .income }
            if cents < 0 { return .expense }
            return .neutral
        }()
        switch resolved {
        case .income: return .green
        case .expense: return .pink
        case .neutral, .auto: return .primary
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        AmountText(cents: 1_234_56, tone: .income, size: .hero)
        AmountText(cents: -500_00, tone: .expense, size: .large)
        AmountText(cents: 100_00, size: .medium)
    }
    .padding()
}
