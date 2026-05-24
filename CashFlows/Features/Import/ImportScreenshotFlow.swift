import PhotosUI
import SwiftUI

struct ImportScreenshotFlow: View {
    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var error: String?
    @State private var draft: DebtPlanDraft?

    var body: some View {
        NavigationStack {
            Group {
                if let draft {
                    DebtFormView(draft: draft)
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

    @ViewBuilder
    private var pickerStage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(spacing: 6) {
                Text("上传分期账单截图")
                    .font(.title3.bold())
                Text("自动识别平台、本金、期数、月供、首期还款日。所有识别都在你的手机本地进行。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if isProcessing {
                ProgressView("识别中…").padding(.top, 8)
            }

            if let error {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                Label(isProcessing ? "识别中" : "从相册选择截图", systemImage: "photo")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isProcessing)
            .padding(.horizontal, 24)

            Spacer()
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task { await process(item: newItem) }
        }
    }

    private func process(item: PhotosPickerItem) async {
        isProcessing = true
        error = nil
        defer { isProcessing = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                error = "无法读取这张图片，换一张试试"
                return
            }
            let observations = try await OCRService.recognizeText(from: image)
            if observations.isEmpty {
                error = "没识别到任何文字，请换一张更清晰的截图"
                return
            }
            draft = BillParser.parse(observations: observations)
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    ImportScreenshotFlow()
        .modelContainer(for: [DebtPlan.self, Repayment.self], inMemory: true)
}
