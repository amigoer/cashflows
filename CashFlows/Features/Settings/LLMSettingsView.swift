import SwiftUI

struct LLMSettingsView: View {
    @Bindable var config: LLMConfig

    @State private var selectedPreset: LLMPreset?
    @State private var testStatus: TestStatus = .idle
    @State private var pingTask: Task<Void, Never>?

    private enum TestStatus {
        case idle
        case running
        case ok(String)
        case failed(String)
    }

    var body: some View {
        Form {
            Section {
                Toggle("启用 LLM 增强识别", isOn: $config.enabled)
            } footer: {
                Text("启用后，从截图识别分期时会把 OCR 文本发送到你配置的 LLM 服务做结构化抽取。关闭则只用本地正则解析。")
            }

            Section("快速预设") {
                Picker("选择服务商", selection: $selectedPreset) {
                    Text("自定义").tag(LLMPreset?.none)
                    ForEach(LLMPreset.allCases) { preset in
                        Text(preset.rawValue).tag(LLMPreset?.some(preset))
                    }
                }
                .pickerStyle(.menu)

                if let selectedPreset {
                    Button("应用预设") {
                        config.endpoint = selectedPreset.endpoint
                        config.model = selectedPreset.suggestedModel
                    }
                }
            }

            Section("接口") {
                LabeledContent("接口地址") {
                    TextField("https://api.deepseek.com/v1", text: $config.endpoint)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("API Key") {
                    SecureField("sk-…", text: $config.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("模型") {
                    TextField("deepseek-chat", text: $config.model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.trailing)
                }
            }

            Section {
                Button(action: runTest) {
                    HStack {
                        Text(testButtonLabel)
                        Spacer()
                        statusIcon
                    }
                }
                .disabled(!canTest || isRunning)

                if case .ok(let body) = testStatus {
                    Text("响应：\(body)").font(.footnote).foregroundStyle(.secondary)
                } else if case .failed(let message) = testStatus {
                    Text(message).font(.footnote).foregroundStyle(.pink)
                }
            } header: {
                Text("连接测试")
            } footer: {
                Text("发送一条 ping 消息验证 endpoint / API Key / 模型名是否正确。可能产生少量 token 费用。")
            }

            Section("隐私") {
                Text("• 我们只把 OCR 文本发到你配置的接口，不会发送截图原图。\n• API Key 存放在 iOS 钥匙串中，不会上传任何服务器。\n• 关闭此功能后，App 完全不联网。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("LLM 识别配置")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { pingTask?.cancel() }
    }

    private var canTest: Bool {
        !config.endpoint.trimmingCharacters(in: .whitespaces).isEmpty
            && !config.apiKey.trimmingCharacters(in: .whitespaces).isEmpty
            && !config.model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var isRunning: Bool {
        if case .running = testStatus { return true }
        return false
    }

    private var testButtonLabel: String {
        switch testStatus {
        case .running: "测试中…"
        case .ok: "重新测试"
        case .failed: "重新测试"
        case .idle: "测试连接"
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch testStatus {
        case .idle: EmptyView()
        case .running: ProgressView()
        case .ok: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.pink)
        }
    }

    private func runTest() {
        let snapshot = config.snapshot()
        testStatus = .running
        pingTask?.cancel()
        pingTask = Task {
            do {
                let reply = try await LLMService.ping(config: snapshot)
                await MainActor.run {
                    testStatus = .ok(reply.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            } catch {
                let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                await MainActor.run {
                    testStatus = .failed(msg)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LLMSettingsView(config: LLMConfig.shared)
    }
}
