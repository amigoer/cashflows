import SwiftData
import SwiftUI

struct SalaryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var salary: Salary?

    // Common
    @State private var paidAt: Date
    @State private var period: SalaryPeriod
    @State private var note: String
    @State private var showDeleteConfirm = false

    // Mode toggle
    @State private var showBreakdown: Bool

    // Net-only mode
    @State private var netAmountCents: Int?

    // Breakdown mode
    @State private var grossAmountCents: Int?
    @State private var socialInsuranceCents: Int?
    @State private var housingFundCents: Int?
    @State private var incomeTaxCents: Int?
    @State private var additionalDeductionCents: Int?
    @State private var otherDeductionCents: Int?

    init(salary: Salary? = nil) {
        self.salary = salary
        let hasBreakdown = salary?.hasBreakdown ?? false
        _showBreakdown = State(initialValue: hasBreakdown)
        _paidAt = State(initialValue: salary?.paidAt ?? .now)
        _period = State(initialValue: salary?.period ?? .monthly)
        _note = State(initialValue: salary?.note ?? "")

        if hasBreakdown {
            _netAmountCents = State(initialValue: nil)
            _grossAmountCents = State(initialValue: salary?.grossAmountCents)
            _socialInsuranceCents = State(initialValue: nonZero(salary?.socialInsuranceCents))
            _housingFundCents = State(initialValue: nonZero(salary?.housingFundCents))
            _incomeTaxCents = State(initialValue: nonZero(salary?.incomeTaxCents))
            _additionalDeductionCents = State(initialValue: nonZero(salary?.additionalDeductionCents))
            _otherDeductionCents = State(initialValue: nonZero(salary?.otherDeductionCents))
        } else {
            _netAmountCents = State(initialValue: salary?.amountCents)
            _grossAmountCents = State(initialValue: nil)
            _socialInsuranceCents = State(initialValue: nil)
            _housingFundCents = State(initialValue: nil)
            _incomeTaxCents = State(initialValue: nil)
            _additionalDeductionCents = State(initialValue: nil)
            _otherDeductionCents = State(initialValue: nil)
        }
    }

    var body: some View {
        Form {
            Section {
                Toggle("录入工资构成（扣除明细）", isOn: $showBreakdown)
            } footer: {
                Text(showBreakdown
                     ? "输入税前金额和五险一金 / 个税等扣除项，实发金额会自动计算。"
                     : "如需记录税前 / 五险一金 / 个税等扣除明细，请打开上方开关。")
            }

            if showBreakdown {
                Section("税前金额") {
                    MoneyField(cents: $grossAmountCents)
                }
                Section("扣除明细") {
                    deductionRow(label: "社保（养老+医疗+失业）", cents: $socialInsuranceCents)
                    deductionRow(label: "公积金", cents: $housingFundCents)
                    deductionRow(label: "个税", cents: $incomeTaxCents)
                    deductionRow(label: "专项附加扣除", cents: $additionalDeductionCents)
                    deductionRow(label: "其他", cents: $otherDeductionCents)
                }
                Section {
                    HStack {
                        Text("扣除合计")
                            .foregroundStyle(.secondary)
                        Spacer()
                        AmountText(cents: -totalDeductions, tone: .expense, size: .small)
                    }
                    HStack {
                        Text("实发金额")
                            .font(.body.weight(.semibold))
                        Spacer()
                        AmountText(cents: computedNet, tone: .income, size: .medium)
                    }
                }
            } else {
                Section("金额") {
                    MoneyField(cents: $netAmountCents)
                }
            }

            Section("到账日期") {
                DatePicker("", selection: $paidAt, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "zh_CN"))
            }

            Section("发放周期") {
                Picker("发放周期", selection: $period) {
                    ForEach(SalaryPeriod.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("备注（选填）") {
                TextField("备注", text: $note, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            if salary != nil {
                Section {
                    Button("删除此条记录", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
        }
        .navigationTitle(salary == nil ? "新增工资" : "编辑工资")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: save).disabled(!isValid)
            }
        }
        .confirmationDialog(
            "确定删除这条工资记录？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive, action: deleteAndDismiss)
            Button("取消", role: .cancel) { }
        }
    }

    private func deductionRow(label: String, cents: Binding<Int?>) -> some View {
        LabeledContent {
            InlineMoneyField(cents: cents)
        } label: {
            Text(label).foregroundStyle(.secondary)
        }
    }

    // MARK: - Derived values

    private var totalDeductions: Int {
        (socialInsuranceCents ?? 0)
            + (housingFundCents ?? 0)
            + (incomeTaxCents ?? 0)
            + (additionalDeductionCents ?? 0)
            + (otherDeductionCents ?? 0)
    }

    private var computedNet: Int {
        max(0, (grossAmountCents ?? 0) - totalDeductions)
    }

    private var isValid: Bool {
        if showBreakdown {
            return (grossAmountCents ?? 0) > 0 && computedNet > 0
        } else {
            return (netAmountCents ?? 0) > 0
        }
    }

    // MARK: - Save / delete

    private func save() {
        guard isValid else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = trimmedNote.isEmpty ? nil : trimmedNote

        let amount: Int
        let gross: Int
        let social: Int
        let fund: Int
        let tax: Int
        let extra: Int
        let other: Int

        if showBreakdown {
            amount = computedNet
            gross = grossAmountCents ?? 0
            social = socialInsuranceCents ?? 0
            fund = housingFundCents ?? 0
            tax = incomeTaxCents ?? 0
            extra = additionalDeductionCents ?? 0
            other = otherDeductionCents ?? 0
        } else {
            amount = netAmountCents ?? 0
            gross = 0
            social = 0
            fund = 0
            tax = 0
            extra = 0
            other = 0
        }

        if let salary {
            salary.amountCents = amount
            salary.paidAt = paidAt
            salary.period = period
            salary.note = noteValue
            salary.grossAmountCents = gross
            salary.socialInsuranceCents = social
            salary.housingFundCents = fund
            salary.incomeTaxCents = tax
            salary.additionalDeductionCents = extra
            salary.otherDeductionCents = other
        } else {
            let new = Salary(
                amountCents: amount,
                paidAt: paidAt,
                period: period,
                note: noteValue,
                grossAmountCents: gross,
                socialInsuranceCents: social,
                housingFundCents: fund,
                incomeTaxCents: tax,
                additionalDeductionCents: extra,
                otherDeductionCents: other
            )
            modelContext.insert(new)
        }
        dismiss()
    }

    private func deleteAndDismiss() {
        if let salary {
            modelContext.delete(salary)
        }
        dismiss()
    }
}

private func nonZero(_ value: Int?) -> Int? {
    guard let value, value > 0 else { return nil }
    return value
}

#Preview {
    NavigationStack {
        SalaryFormView()
    }
    .modelContainer(for: [Salary.self], inMemory: true)
}
