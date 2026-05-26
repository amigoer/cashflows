import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var exportSheet: ExportItem?
    @State private var showImportPicker = false
    @State private var importConfirm: URL?
    @State private var feedback: Feedback?
    @State private var showMockConfirm = false
    @State private var showWipeConfirm = false
    @State private var notificationConfig = NotificationConfig.shared
    @State private var notificationDenied = false

    private struct ExportItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    private struct Feedback: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var body: some View {
        NavigationStack {
            List {
                Section("数据") {
                    Button {
                        exportJson()
                    } label: {
                        SettingsRow(
                            systemImage: "square.and.arrow.up",
                            title: "导出 JSON",
                            subtitle: "完整备份所有数据（推荐）"
                        )
                    }
                    Button {
                        exportCsv()
                    } label: {
                        SettingsRow(
                            systemImage: "tablecells",
                            title: "导出 CSV",
                            subtitle: "导出三张表方便在 Excel 查看"
                        )
                    }
                    Button(role: .destructive) {
                        showImportPicker = true
                    } label: {
                        SettingsRow(
                            systemImage: "square.and.arrow.down",
                            title: "导入 JSON",
                            subtitle: "从备份文件恢复（会覆盖现有数据）",
                            tint: .pink
                        )
                    }
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))

                Section {
                    Text("所有数据仅存在你的设备本地，不上传任何服务器。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)

                Section {
                    Toggle("还款提醒", isOn: $notificationConfig.repaymentRemindersEnabled)
                        .onChange(of: notificationConfig.repaymentRemindersEnabled) { _, newValue in
                            Task { await applyNotificationToggle(enabled: newValue) }
                        }
                    if notificationConfig.repaymentRemindersEnabled {
                        Picker("提前", selection: $notificationConfig.leadDays) {
                            Text("当天").tag(0)
                            Text("1 天").tag(1)
                            Text("2 天").tag(2)
                            Text("3 天").tag(3)
                        }
                        .onChange(of: notificationConfig.leadDays) { _, _ in
                            Task { await reschedule() }
                        }
                    }
                } header: {
                    Text("提醒")
                } footer: {
                    Text(notificationFooter)
                }

                Section("识别") {
                    NavigationLink {
                        LLMSettingsView(config: LLMConfig.shared)
                    } label: {
                        SettingsRow(
                            systemImage: "sparkles",
                            title: "LLM 增强识别",
                            subtitle: LLMConfig.shared.isReady
                                ? "已配置 · \(LLMConfig.shared.model)"
                                : "用自己的 API Key 让识别更准"
                        )
                    }
                }

                Section("关于") {
                    HStack {
                        Text("现金流")
                        Spacer()
                        Text("v" + appVersion).foregroundStyle(.secondary)
                    }
                }

                Section("调试") {
                    Button {
                        showMockConfirm = true
                    } label: {
                        SettingsRow(
                            systemImage: "wand.and.stars",
                            title: "重置为示例数据",
                            subtitle: "清空当前数据，插入 2026-05 起 18 个月的样本"
                        )
                    }
                    Button(role: .destructive) {
                        showWipeConfirm = true
                    } label: {
                        SettingsRow(
                            systemImage: "trash",
                            title: "清空所有数据",
                            subtitle: "无法恢复",
                            tint: .pink
                        )
                    }
                }
            }
            .navigationTitle("设置")
            .sheet(item: $exportSheet) { item in
                ShareSheet(items: [item.url])
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importConfirm = url
                    }
                case .failure(let error):
                    feedback = Feedback(title: "导入失败", message: error.localizedDescription)
                }
            }
            .confirmationDialog(
                "导入会覆盖所有现有数据，继续吗？",
                isPresented: Binding(get: { importConfirm != nil }, set: { if !$0 { importConfirm = nil } }),
                titleVisibility: .visible
            ) {
                if let url = importConfirm {
                    Button("覆盖并导入", role: .destructive) {
                        importConfirm = nil
                        performImport(from: url)
                    }
                }
                Button("取消", role: .cancel) { importConfirm = nil }
            }
            .alert(item: $feedback) { f in
                Alert(title: Text(f.title), message: Text(f.message), dismissButton: .default(Text("好")))
            }
            .confirmationDialog(
                "重置并插入示例数据？现有所有数据会被清空。",
                isPresented: $showMockConfirm,
                titleVisibility: .visible
            ) {
                Button("重置并插入", role: .destructive) {
                    do {
                        try MockData.resetWithSamples(in: modelContext)
                        feedback = Feedback(title: "已插入示例数据", message: "包含 18 个月工资 + 7 个分期/固定支出")
                    } catch {
                        feedback = Feedback(title: "插入失败", message: error.localizedDescription)
                    }
                }
                Button("取消", role: .cancel) { }
            }
            .confirmationDialog(
                "清空所有数据？此操作无法撤销。",
                isPresented: $showWipeConfirm,
                titleVisibility: .visible
            ) {
                Button("清空", role: .destructive) {
                    do {
                        try MockData.wipeAll(in: modelContext)
                        feedback = Feedback(title: "已清空", message: "所有数据已删除")
                    } catch {
                        feedback = Feedback(title: "清空失败", message: error.localizedDescription)
                    }
                }
                Button("取消", role: .cancel) { }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    // MARK: - Notifications

    private var notificationFooter: String {
        if notificationDenied {
            return "已被系统拒绝。请前往「设置 → 通知 → 现金流」手动开启。"
        }
        if notificationConfig.repaymentRemindersEnabled {
            let dayLabel = notificationConfig.leadDays == 0 ? "当天" : "提前 \(notificationConfig.leadDays) 天"
            return "\(dayLabel)上午 9 点本地提醒，下一期到期前自动通知。"
        }
        return "开启后会在还款到期前自动提醒，本地通知不联网。"
    }

    private func applyNotificationToggle(enabled: Bool) async {
        if enabled {
            let granted = await NotificationService.requestAuthorization()
            if !granted {
                notificationDenied = true
                notificationConfig.repaymentRemindersEnabled = false
                feedback = Feedback(
                    title: "通知权限被拒",
                    message: "前往「设置 → 通知 → 现金流」开启通知权限后再试。"
                )
                return
            }
            notificationDenied = false
            await reschedule()
        } else {
            await NotificationService.cancelAll()
        }
    }

    private func reschedule() async {
        let repayments = (try? modelContext.fetch(FetchDescriptor<Repayment>())) ?? []
        await NotificationService.rescheduleAll(
            repayments: repayments,
            leadDays: notificationConfig.leadDays
        )
    }

    private func exportJson() {
        do {
            let payload = try ExportService.collect(from: modelContext)
            let data = try ExportService.encodeJson(payload)
            let url = try writeTemp(data: data, name: "cashflows-\(stamp()).json")
            exportSheet = ExportItem(url: url)
        } catch {
            feedback = Feedback(title: "导出失败", message: error.localizedDescription)
        }
    }

    private func exportCsv() {
        do {
            let payload = try ExportService.collect(from: modelContext)
            let csv = ExportService.encodeCsv(payload)
            guard let data = csv.data(using: .utf8) else { return }
            let url = try writeTemp(data: data, name: "cashflows-\(stamp()).csv")
            exportSheet = ExportItem(url: url)
        } catch {
            feedback = Feedback(title: "导出失败", message: error.localizedDescription)
        }
    }

    private func performImport(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let payload = try ExportService.decodeJson(data)
            try ExportService.restore(from: payload, into: modelContext)
            feedback = Feedback(
                title: "导入完成",
                message: "工资 \(payload.salaries.count) · 债务 \(payload.debtPlans.count) · 还款 \(payload.repayments.count)"
            )
        } catch {
            feedback = Feedback(title: "导入失败", message: error.localizedDescription)
        }
    }

    private func writeTemp(data: Data, name: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: url)
        try data.write(to: url)
        return url
    }

    private func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmm"
        return f.string(from: .now)
    }
}

private struct SettingsRow: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.callout)
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.15), in: .rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [Salary.self, DebtPlan.self, Repayment.self], inMemory: true)
}
