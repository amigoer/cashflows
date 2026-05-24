import Foundation

enum LLMError: LocalizedError {
    case notConfigured
    case invalidEndpoint
    case http(Int, String)
    case decoding(String)
    case empty
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "LLM 未配置"
        case .invalidEndpoint: "接口地址不合法"
        case .http(let code, let body):
            "服务返回 \(code)：\(body.prefix(160))"
        case .decoding(let msg):
            "解析返回数据失败：\(msg)"
        case .empty:
            "服务返回空内容"
        case .network(let e):
            "网络错误：\(e.localizedDescription)"
        }
    }
}

/// Minimal OpenAI-compatible chat completions client.
/// Targets `POST {endpoint}/chat/completions` with `Authorization: Bearer {key}`.
/// Works with OpenAI, DeepSeek, Qwen/DashScope, Kimi, GLM, Doubao, Ollama, etc.
enum LLMService {
    private struct ChatRequest: Encodable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let response_format: ResponseFormat?

        struct Message: Encodable {
            let role: String
            let content: String
        }

        struct ResponseFormat: Encodable {
            let type: String
        }
    }

    private struct ChatResponse: Decodable {
        let choices: [Choice]

        struct Choice: Decodable {
            let message: Message
        }

        struct Message: Decodable {
            let content: String?
        }
    }

    /// Sends a request and returns the assistant's raw response content (typically JSON when
    /// `expectsJson` is true).
    static func chat(
        systemPrompt: String,
        userPrompt: String,
        config: LLMConfig.Snapshot,
        expectsJson: Bool = true
    ) async throws -> String {
        guard !config.endpoint.isEmpty, !config.apiKey.isEmpty, !config.model.isEmpty else {
            throw LLMError.notConfigured
        }
        guard let url = makeURL(base: config.endpoint, path: "chat/completions") else {
            throw LLMError.invalidEndpoint
        }

        let body = ChatRequest(
            model: config.model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt),
            ],
            temperature: 0,
            response_format: expectsJson ? .init(type: "json_object") : nil
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 60

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LLMError.network(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw LLMError.http(http.statusCode, body)
        }

        let parsed: ChatResponse
        do {
            parsed = try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            throw LLMError.decoding(error.localizedDescription)
        }

        guard let content = parsed.choices.first?.message.content, !content.isEmpty else {
            throw LLMError.empty
        }
        return content
    }

    /// Lightweight connectivity probe: sends a tiny prompt and returns true on success.
    static func ping(config: LLMConfig.Snapshot) async throws -> String {
        try await chat(
            systemPrompt: "You are a connectivity test endpoint.",
            userPrompt: "Reply with the single word: pong",
            config: config,
            expectsJson: false
        )
    }

    private static func makeURL(base: String, path: String) -> URL? {
        let trimmed = base.trimmingCharacters(in: .whitespaces)
        let withoutTrailingSlash = trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
        return URL(string: "\(withoutTrailingSlash)/\(path)")
    }
}
