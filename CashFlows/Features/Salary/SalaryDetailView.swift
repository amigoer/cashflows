import SwiftData
import SwiftUI

struct SalaryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var salary: Salary

    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            Section {
                heroCard
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listSectionSpacing(.compact)

            if salary.hasBreakdown {
                chartSection
                breakdownSection
            }

            infoSection

            Section {
                Button("删除此条记录", role: .destructive) {
                    showDeleteConfirm = true
                }
            }
        }
        .navigationTitle("工资详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("编辑") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                SalaryFormView(salary: salary)
            }
        }
        .confirmationDialog(
            "确定删除这条工资记录？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                modelContext.delete(salary)
                dismiss()
            }
            Button("取消", role: .cancel) { }
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("实发金额")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            AmountText(cents: salary.amountCents, tone: .income, size: .hero)
            HStack(spacing: 6) {
                Text(salary.period.displayName)
                Text("·").foregroundStyle(.tertiary)
                Text(DateFormat.long(salary.paidAt))
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 18))
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartSection: some View {
        Section {
            SalaryBreakdownChart(salary: salary)
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        } header: {
            Text("构成比例")
        }
    }

    // MARK: - Breakdown

    @ViewBuilder
    private var breakdownSection: some View {
        Section {
            breakdownRow(label: "税前金额", cents: salary.grossAmountCents, emphasis: .top)
            if salary.socialInsuranceCents > 0 {
                breakdownRow(label: "社保", cents: -salary.socialInsuranceCents)
            }
            if salary.housingFundCents > 0 {
                breakdownRow(label: "公积金", cents: -salary.housingFundCents)
            }
            if salary.incomeTaxCents > 0 {
                breakdownRow(label: "个税", cents: -salary.incomeTaxCents)
            }
            if salary.additionalDeductionCents > 0 {
                breakdownRow(label: "专项附加扣除", cents: -salary.additionalDeductionCents)
            }
            if salary.otherDeductionCents > 0 {
                breakdownRow(label: "其他", cents: -salary.otherDeductionCents)
            }
            breakdownRow(label: "扣除合计", cents: -salary.totalDeductionCents, emphasis: .subtotal)
            breakdownRow(label: "实发金额", cents: salary.amountCents, emphasis: .total)
        } header: {
            Text("工资构成")
        } footer: {
            if salary.grossAmountCents > 0 {
                let ratio = Double(salary.amountCents) / Double(salary.grossAmountCents)
                Text("到手率 \(String(format: "%.1f%%", ratio * 100)) · 扣除占税前 \(String(format: "%.1f%%", (1 - ratio) * 100))")
            }
        }
    }

    private enum RowEmphasis {
        case normal, top, subtotal, total
    }

    private func breakdownRow(label: String, cents: Int, emphasis: RowEmphasis = .normal) -> some View {
        HStack {
            Text(label)
                .font(emphasis == .normal ? .body : .body.weight(.semibold))
                .foregroundStyle(labelColor(for: emphasis))
            Spacer()
            Text(Money.format(cents: cents, signed: cents < 0))
                .font(emphasis == .normal ? .body : .body.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(amountColor(for: cents, emphasis: emphasis))
        }
    }

    private func labelColor(for emphasis: RowEmphasis) -> Color {
        switch emphasis {
        case .normal: .secondary
        case .top, .subtotal, .total: .primary
        }
    }

    private func amountColor(for cents: Int, emphasis: RowEmphasis) -> Color {
        if emphasis == .total {
            return .green
        }
        if cents < 0 {
            return .pink
        }
        if cents > 0 {
            return .primary
        }
        return .secondary
    }

    // MARK: - Info

    private var infoSection: some View {
        Section("信息") {
            LabeledContent("发放周期", value: salary.period.displayName)
            LabeledContent("到账日期", value: DateFormat.long(salary.paidAt))
            if let note = salary.note, !note.isEmpty {
                LabeledContent("备注") {
                    Text(note).multilineTextAlignment(.trailing)
                }
            }
            LabeledContent("创建时间", value: DateFormat.long(salary.createdAt))
        }
    }
}

#Preview {
    NavigationStack {
        SalaryDetailView(salary: Salary(
            amountCents: 10_000_00,
            paidAt: .now,
            period: .monthly,
            note: "月薪 + 半年奖",
            grossAmountCents: 15_000_00,
            socialInsuranceCents: 1_500_00,
            housingFundCents: 1_800_00,
            incomeTaxCents: 500_00,
            additionalDeductionCents: 1_200_00,
            otherDeductionCents: 0
        ))
    }
    .modelContainer(for: [Salary.self], inMemory: true)
}
