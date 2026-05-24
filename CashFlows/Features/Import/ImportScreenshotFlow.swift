import PhotosUI
import SwiftUI

struct ImportScreenshotFlow: View {
    @Environment(\.dismiss) private var dismiss
    @State private var config = LLMConfig.shared

    @State private var platformChoice: PlatformChoice = .huabei
    @State private var customPlatform: String = ""

    @State private var photoItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var error: String?
    @State private var draft: DebtPlanDraft?
    @State private var draftSource: LLMBillParser.Source = .regex

    var body: some View {
        NavigationStack {
            Group {
                if let draft {
                    DebtFormView(draft: draft)
                        .safeAreaInset(edge: .top) { sourceBanner }
                } else {
                    pickerStage
                        .navigationTitle("从截图识别")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("取消") { dismiss() }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Source banner shown above the prefilled form

    @ViewBuilder
    private var sourceBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: draftSource == .llm ? "sparkles" : "doc.text.viewfinder")
            Text(draftSource == .llm ? "LLM 已识别，请核对" : "本地解析已识别，请核对")
                .font(.footnote.weight(.medium))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background((draftSource == .llm ? Color.accentColor : Color.secondary).opacity(0.12))
        .foregroundStyle(draftSource == .llm ? Color.accentColor : Color.secondary)
    }

    // MARK: - Stage 1: pick platform + photo

    @ViewBuilder
    private var pickerStage: some View {
        Form {
            Section("分期平台") {
                Picker("平台", selection: $platformChoice) {
                    ForEach(PlatformChoice.allCases) { choice in
                        Text(choice.label).tag(choice)
                    }
                }
                .pickerStyle(.menu)

                if platformChoice == .other {
                    TextField("自定义平台名（如 微粒贷）", text: $customPlatform)
                        .textInputAutocapitalization(.never)
                }
            }

            Section {
                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text(isProcessing ? "识别中…" : "从相册选择截图")
                        Spacer()
                    }
                }
                .disabled(isProcessing || resolvedPlatform.isEmpty)

                if isProcessing {
                    HStack {
                        ProgressView()
                        Text(config.isReady ? "正在调用 LLM 抽取字段…" : "正在本地解析…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("上传账单截图")
            } footer: {
                if config.isReady {
                    Text("已启用 LLM 增强识别（模型：\(config.model)）。OCR 文本会发到你配置的接口。")
                } else {
                    Text("未启用 LLM 识别，使用本地正则解析（准确度较低）。可在「设置 → LLM 增强识别」配置。")
                }
            }

            if let error {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.pink)
                        .font(.callout)
                }
            }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task { await process(item: newItem) }
        }
    }

    // MARK: - Processing pipeline

    private func process(item: PhotosPickerItem) async {
        isProcessing = true
        error = nil
        defer { isProcessing = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                error = "无法读取这张图片，换一张试试"
                return
            }
            let observations = try await OCRService.recognizeText(from: image)
            if observations.isEmpty {
                error = "没识别到任何文字，请换一张更清晰的截图"
                return
            }
            let (parsed, source) = await LLMBillParser.parse(
                observations: observations,
                platform: resolvedPlatform,
                config: config
            )
            draftSource = source
            draft = parsed
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private var resolvedPlatform: String {
        switch platformChoice {
        case .other: customPlatform.trimmingCharacters(in: .whitespaces)
        default: platformChoice.label
        }
    }
}

/// Common Chinese installment platforms surfaced in the picker.
enum PlatformChoice: String, CaseIterable, Identifiable {
    case huabei = "花呗"
    case jiebei = "借呗"
    case jdBaitiao = "京东白条"
    case jdJintiao = "京东金条"
    case zhaoshangCard = "招商银行信用卡"
    case jianshangCard = "建设银行信用卡"
    case gongshangCard = "工商银行信用卡"
    case nongshangCard = "农业银行信用卡"
    case zhongguoCard = "中国银行信用卡"
    case jiaotongCard = "交通银行信用卡"
    case meituanYuefu = "美团月付"
    case other = "其他"

    var id: String { rawValue }
    var label: String { rawValue }
}

#Preview {
    ImportScreenshotFlow()
        .modelContainer(for: [DebtPlan.self, Repayment.self], inMemory: true)
}
