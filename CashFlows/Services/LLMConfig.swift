import Foundation
import Observation

/// User-configured Bring-Your-Own-Key LLM endpoint settings.
/// API key is stored in the Keychain; the rest in UserDefaults.
@MainActor
@Observable
final class LLMConfig {
    static let shared = LLMConfig()

    private enum Keys {
        static let endpoint = "llm.endpoint"
        static let model = "llm.model"
        static let apiKey = "llm.apiKey"
        static let enabled = "llm.enabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.endpoint = defaults.string(forKey: Keys.endpoint) ?? ""
        self.model = defaults.string(forKey: Keys.model) ?? ""
        self.apiKey = Keychain.get(Keys.apiKey) ?? ""
        self.enabled = defaults.bool(forKey: Keys.enabled)
    }

    var endpoint: String {
        didSet { defaults.set(endpoint, forKey: Keys.endpoint) }
    }

    var model: String {
        didSet { defaults.set(model, forKey: Keys.model) }
    }

    var apiKey: String {
        didSet { Keychain.set(apiKey, forKey: Keys.apiKey) }
    }

    var enabled: Bool {
        didSet { defaults.set(enabled, forKey: Keys.enabled) }
    }

    var isReady: Bool {
        enabled
            && !endpoint.trimmingCharacters(in: .whitespaces).isEmpty
            && !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
            && !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// One-shot snapshot for use in background tasks where mutating the @Observable is undesirable.
    func snapshot() -> Snapshot {
        Snapshot(endpoint: endpoint, apiKey: apiKey, model: model)
    }

    struct Snapshot: Sendable {
        let endpoint: String
        let apiKey: String
        let model: String
    }
}

/// Curated set of providers that all speak OpenAI-compatible chat completions.
enum LLMPreset: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case deepseek = "DeepSeek"
    case qwen = "通义千问 (DashScope)"
    case kimi = "Moonshot Kimi"
    case glm = "智谱 GLM"
    case doubao = "豆包 (火山方舟)"
    case ollama = "Ollama (本机)"

    var id: String { rawValue }

    var endpoint: String {
        switch self {
        case .openai: "https://api.openai.com/v1"
        case .deepseek: "https://api.deepseek.com/v1"
        case .qwen: "https://dashscope.aliyuncs.com/compatible-mode/v1"
        case .kimi: "https://api.moonshot.cn/v1"
        case .glm: "https://open.bigmodel.cn/api/paas/v4"
        case .doubao: "https://ark.cn-beijing.volces.com/api/v3"
        case .ollama: "http://localhost:11434/v1"
        }
    }

    var suggestedModel: String {
        switch self {
        case .openai: "gpt-4o-mini"
        case .deepseek: "deepseek-chat"
        case .qwen: "qwen-plus"
        case .kimi: "moonshot-v1-8k"
        case .glm: "glm-4-flash"
        case .doubao: "doubao-1-5-pro-32k-250115"
        case .ollama: "qwen2.5:7b"
        }
    }
}
