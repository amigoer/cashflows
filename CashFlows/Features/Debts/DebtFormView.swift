import SwiftData
import SwiftUI

struct DebtFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var plan: DebtPlan?

    @State private var platform: String
    @State private var principalCents: Int?
    @State private var totalPeriodsText: String
    @State private var monthlyPaymentCents: Int?
    @State private var firstDueDate: Date
    @State private var aprText: String
    @State private var note: String
    @State private var showDeleteConfirm = false

    init(plan: DebtPlan? = nil) {
        self.plan = plan
        _platform = State(initialValue: plan?.platform ?? "")
        _principalCents = State(initialValue: plan?.principalCents)
        _totalPeriodsText = State(initialValue: plan.map { String($0.totalPeriods) } ?? "")
        _monthlyPaymentCents = State(initialValue: plan?.monthlyPaymentCents)
        _firstDueDate = State(initialValue: plan?.firstDueDate ?? .now)
        _aprText = State(initialValue: plan.flatMap { $0.aprBps > 0 ? String(format: "%.2f", Double($0.aprBps) / 100) : nil } ?? "")
        _note = State(initialValue: plan?.note ?? "")
    }

    /// Initializer used by the OCR import flow to pre-fill the form with a draft.
    init(draft: DebtPlanDraft) {
        self.plan = nil
        _platform = State(initialValue: draft.platform)
        _principalCents = State(initialValue: draft.principalCents)
        _totalPeriodsText = State(initialValue: draft.totalPeriods.map { String($0) } ?? "")
        _monthlyPaymentCents = State(initialValue: draft.monthlyPaymentCents)
        _firstDueDate = State(initialValue: draft.firstDueDate ?? .now)
        _aprText = State(initialValue: draft.aprBps.map { String(format: "%.2f", Double($0) / 100) } ?? "")
        _note = State(initialValue: draft.note ?? "")
    }

    var body: some View {
        Form {
            Section("平台") {
                TextField("花呗 / 京东白条 / 信用卡分期 …", text: $platform)
            }

            Section("本金") {
                MoneyField(cents: $principalCents)
            }

            Section("期数与月供") {
                HStack {
                    Text("总期数")
                    Spacer()
                    TextField("12", text: $totalPeriodsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: totalPeriodsText) { _, new in
                            let cleaned = new.filter { $0.isNumber }
                            if cleaned != new { totalPeriodsText = cleaned }
                        }
                }
                HStack {
                    Text("月供")
                    Spacer()
                    MoneyField(cents: $monthlyPaymentCents)
                        .frame(maxWidth: 200)
                }
            }

            Section("首期还款日") {
                DatePicker("", selection: $firstDueDate, displayedComponents: .date)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "zh_CN"))
            }

            Section("年化利率（选填，%）") {
                TextField("例如 8.4", text: $aprText)
                    .keyboardType(.decimalPad)
            }

            Section("备注（选填）") {
                TextField("备注", text: $note, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            if plan != nil {
                Section {
                    Button("删除此分期", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
        }
        .navigationTitle(plan == nil ? "新增分期" : "编辑分期")
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
            "删除该笔债务会同时删除其全部还款计划，确定继续？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive, action: deleteAndDismiss)
            Button("取消", role: .cancel) { }
        }
    }

    private var totalPeriods: Int { Int(totalPeriodsText) ?? 0 }

    private var aprBps: Int {
        let trimmed = aprText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let v = Double(trimmed) else { return 0 }
        return Int((v * 100).rounded())
    }

    private var isValid: Bool {
        !platform.trimmingCharacters(in: .whitespaces).isEmpty
            && (principalCents ?? 0) > 0
            && totalPeriods > 0
            && (monthlyPaymentCents ?? 0) > 0
    }

    private func save() {
        guard let principalCents, let monthlyPaymentCents, isValid else { return }
        let trimmedPlatform = platform.trimmingCharacters(in: .whitespaces)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = trimmedNote.isEmpty ? nil : trimmedNote

        if let plan {
            plan.platform = trimmedPlatform
            plan.principalCents = principalCents
            plan.totalPeriods = totalPeriods
            plan.monthlyPaymentCents = monthlyPaymentCents
            plan.firstDueDate = firstDueDate
            plan.aprBps = aprBps
            plan.note = noteValue
        } else {
            let new = DebtPlan(
                platform: trimmedPlatform,
                principalCents: principalCents,
                totalPeriods: totalPeriods,
                monthlyPaymentCents: monthlyPaymentCents,
                firstDueDate: firstDueDate,
                aprBps: aprBps,
                note: noteValue
            )
            modelContext.insert(new)
            let repayments = RepaymentScheduler.generate(
                totalPeriods: totalPeriods,
                monthlyPaymentCents: monthlyPaymentCents,
                firstDueDate: firstDueDate
            )
            for r in repayments {
                r.debtPlan = new
                modelContext.insert(r)
            }
        }
        dismiss()
    }

    private func deleteAndDismiss() {
        if let plan {
            modelContext.delete(plan)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        DebtFormView()
    }
    .modelContainer(for: [DebtPlan.self, Repayment.self], inMemory: true)
}
