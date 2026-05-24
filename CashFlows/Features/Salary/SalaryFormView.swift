import SwiftData
import SwiftUI

struct SalaryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var salary: Salary?

    @State private var amountCents: Int?
    @State private var paidAt: Date
    @State private var period: SalaryPeriod
    @State private var note: String
    @State private var showDeleteConfirm = false

    init(salary: Salary? = nil) {
        self.salary = salary
        _amountCents = State(initialValue: salary?.amountCents)
        _paidAt = State(initialValue: salary?.paidAt ?? .now)
        _period = State(initialValue: salary?.period ?? .monthly)
        _note = State(initialValue: salary?.note ?? "")
    }

    var body: some View {
        Form {
            Section("金额") {
                MoneyField(cents: $amountCents)
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
                Button("保存", action: save)
                    .disabled(amountCents == nil || amountCents == 0)
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

    private func save() {
        guard let amountCents else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = trimmedNote.isEmpty ? nil : trimmedNote

        if let salary {
            salary.amountCents = amountCents
            salary.paidAt = paidAt
            salary.period = period
            salary.note = noteValue
        } else {
            let new = Salary(
                amountCents: amountCents,
                paidAt: paidAt,
                period: period,
                note: noteValue
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

#Preview {
    NavigationStack {
        SalaryFormView()
    }
    .modelContainer(for: [Salary.self], inMemory: true)
}
