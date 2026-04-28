import Foundation

actor MiniMaxService {
    private let apiKey: String
    private let baseURL: String
    private let model: String

    init(apiKey: String = APIKeys.miniMaxAPIKey,
         baseURL: String = Constants.API.miniMaxBaseURL,
         model: String = Constants.API.miniMaxModel) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
    }

    func chat(systemPrompt: String, userPrompt: String) async throws -> String {
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]

        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": 1000,
            "temperature": 0.7
        ]

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        #if DEBUG
        print("📤 MiniMax Request:")
        print("  URL: \(url)")
        print("  Model: \(model)")
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("  Body: \(bodyString.prefix(500))")
        }
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)

        #if DEBUG
        print("📥 MiniMax Response:")
        print("  Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("  Body: \(responseString.prefix(500))")
        }
        #endif

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.noContent
        }

        return content
    }
}

// MARK: - Error Types

enum AIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 API 地址"
        case .invalidResponse:
            return "服务器响应无效"
        case .apiError(let statusCode, let message):
            return "API 错误 (\(statusCode)): \(message)"
        case .noContent:
            return "未能获取到有效回复"
        }
    }
}