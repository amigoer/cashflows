import SwiftData
import SwiftUI

struct RecurringExpenseFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var expense: RecurringExpense?

    @State private var categoryChoice: ExpenseCategory
    @State private var customCategory: String
    @State private var amountCents: Int?
    @State private var startMonth: Date
    @State private var hasEnd: Bool
    @State private var endMonth: Date
    @State private var note: String
    @State private var showDeleteConfirm = false

    init(expense: RecurringExpense? = nil) {
        self.expense = expense
        let cat = expense.flatMap { ExpenseCategory(rawValue: $0.category) }
        _categoryChoice = State(initialValue: cat ?? .rent)
        _customCategory = State(initialValue: cat == nil ? (expense?.category ?? "") : "")
        _amountCents = State(initialValue: expense?.amountCents)
        _startMonth = State(initialValue: expense?.startMonth ?? Self.monthStart(of: .now))
        _hasEnd = State(initialValue: expense?.endMonth != nil)
        _endMonth = State(initialValue: expense?.endMonth ?? Self.monthStart(of: Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now))
        _note = State(initialValue: expense?.note ?? "")
    }

    private static func monthStart(of date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }

    var body: some View {
        Form {
            Section("分类") {
                Picker("分类", selection: $categoryChoice) {
                    ForEach(ExpenseCategory.allCases) { cat in
                        Label(cat.label, systemImage: cat.symbol).tag(cat)
                    }
                }
                .pickerStyle(.menu)

                if categoryChoice == .other {
                    TextField("自定义分类（如 健身房）", text: $customCategory)
                        .textInputAutocapitalization(.never)
                }
            }

            Section("每月金额") {
                MoneyField(cents: $amountCents)
            }

            Section("起止月份") {
                DatePicker("从",
                           selection: $startMonth,
                           displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "zh_CN"))

                Toggle("设置结束月份", isOn: $hasEnd)

                if hasEnd {
                    DatePicker("到",
                               selection: $endMonth,
                               in: startMonth...,
                               displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }
            }

            Section("备注（选填）") {
                TextField("备注", text: $note, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            if expense != nil {
                Section {
                    Button("删除此项", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
        }
        .navigationTitle(expense == nil ? "新增固定开销" : "编辑固定开销")
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
            "删除该项后，关联的现金流统计会立即更新。",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive, action: deleteAndDismiss)
            Button("取消", role: .cancel) { }
        }
    }

    private var resolvedCategory: String {
        switch categoryChoice {
        case .other: customCategory.trimmingCharacters(in: .whitespaces)
        default: categoryChoice.label
        }
    }

    private var isValid: Bool {
        !resolvedCategory.isEmpty && (amountCents ?? 0) > 0
    }

    private func save() {
        guard isValid, let amountCents else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = trimmedNote.isEmpty ? nil : trimmedNote
        let startMonthValue = Self.monthStart(of: startMonth)
        let endMonthValue: Date? = hasEnd ? Self.monthStart(of: endMonth) : nil

        if let expense {
            expense.category = resolvedCategory
            expense.amountCents = amountCents
            expense.startMonth = startMonthValue
            expense.endMonth = endMonthValue
            expense.note = noteValue
        } else {
            let new = RecurringExpense(
                category: resolvedCategory,
                amountCents: amountCents,
                startMonth: startMonthValue,
                endMonth: endMonthValue,
                note: noteValue
            )
            modelContext.insert(new)
        }
        dismiss()
    }

    private func deleteAndDismiss() {
        if let expense {
            modelContext.delete(expense)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        RecurringExpenseFormView()
    }
    .modelContainer(for: [RecurringExpense.self], inMemory: true)
}
