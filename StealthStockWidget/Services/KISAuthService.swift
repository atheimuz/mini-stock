import Foundation

actor KISAuthService {
    static let shared = KISAuthService()

    private var cachedToken: String?
    private var tokenExpiry: Date?

    private let baseURL = "https://openapi.koreainvestment.com:9443"

    func getToken() async throws -> String {
        if let token = cachedToken, let expiry = tokenExpiry, Date() < expiry {
            return token
        }
        return try await fetchNewToken()
    }

    private func fetchNewToken() async throws -> String {
        guard let appKey = KeychainService.load(key: .appKey),
              let appSecret = KeychainService.load(key: .appSecret)
        else {
            throw KISError.missingCredentials
        }

        let url = URL(string: "\(baseURL)/oauth2/tokenP")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "client_credentials",
            "appkey": appKey,
            "appsecret": appSecret,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            throw KISError.authFailed
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String
        else {
            throw KISError.invalidResponse
        }

        cachedToken = token
        tokenExpiry = Date().addingTimeInterval(23 * 3600) // ~23h
        return token
    }

    func invalidateToken() {
        cachedToken = nil
        tokenExpiry = nil
    }
}

enum KISError: LocalizedError {
    case missingCredentials
    case authFailed
    case invalidResponse
    case quoteFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials: return "API credentials not configured"
        case .authFailed: return "Authentication failed"
        case .invalidResponse: return "Invalid response from server"
        case .quoteFailed(let msg): return "Quote failed: \(msg)"
        }
    }
}
