import Foundation

final class KISQuoteService {
    static let shared = KISQuoteService()

    private let baseURL = "https://openapi.koreainvestment.com:9443"

    func fetchQuote(code: String, isRetry: Bool = false) async throws -> StockQuote {
        let token = try await KISAuthService.shared.getToken()

        guard let appKey = KeychainService.load(key: .appKey),
              let appSecret = KeychainService.load(key: .appSecret)
        else {
            throw KISError.missingCredentials
        }

        var components = URLComponents(string: "\(baseURL)/uapi/domestic-stock/v1/quotations/inquire-price")!
        components.queryItems = [
            URLQueryItem(name: "FID_COND_MRKT_DIV_CODE", value: "J"),
            URLQueryItem(name: "FID_INPUT_ISCD", value: code),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(appKey, forHTTPHeaderField: "appkey")
        request.setValue(appSecret, forHTTPHeaderField: "appsecret")
        request.setValue("FHKST01010100", forHTTPHeaderField: "tr_id")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            throw KISError.quoteFailed("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw KISError.invalidResponse
        }

        let rtCd = json["rt_cd"] as? String ?? ""
        if rtCd != "0" {
            let msg = json["msg1"] as? String ?? "Unknown error"
            let msgCd = json["msg_cd"] as? String ?? ""
            // 토큰 에러 시 1회 재시도
            if msgCd.hasPrefix("EGW"), !isRetry {
                await KISAuthService.shared.invalidateToken()
                return try await fetchQuote(code: code, isRetry: true)
            }
            throw KISError.quoteFailed("\(msgCd): \(msg)")
        }

        guard let output = json["output"] as? [String: Any],
              let quote = StockQuote.from(apiResponse: output, code: code)
        else {
            throw KISError.invalidResponse
        }

        return quote
    }

    func fetchStockInfo(code: String) async throws -> (StockInfo, StockQuote) {
        let token = try await KISAuthService.shared.getToken()

        guard let appKey = KeychainService.load(key: .appKey),
              let appSecret = KeychainService.load(key: .appSecret)
        else { throw KISError.missingCredentials }

        var components = URLComponents(string: "\(baseURL)/uapi/domestic-stock/v1/quotations/inquire-price")!
        components.queryItems = [
            URLQueryItem(name: "FID_COND_MRKT_DIV_CODE", value: "J"),
            URLQueryItem(name: "FID_INPUT_ISCD", value: code),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(appKey, forHTTPHeaderField: "appkey")
        request.setValue(appSecret, forHTTPHeaderField: "appsecret")
        request.setValue("FHKST01010100", forHTTPHeaderField: "tr_id")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
        else { throw KISError.quoteFailed("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)") }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw KISError.invalidResponse
        }

        let rtCd = json["rt_cd"] as? String ?? ""
        if rtCd != "0" {
            let msg = json["msg1"] as? String ?? "Unknown error"
            let msgCd = json["msg_cd"] as? String ?? ""
            throw KISError.quoteFailed("\(msgCd): \(msg)")
        }

        guard let output = json["output"] as? [String: Any],
              let quote = StockQuote.from(apiResponse: output, code: code)
        else { throw KISError.invalidResponse }

        let nameFields = ["hts_kor_isnm", "kor_isnm"]
        let rawName = nameFields
            .compactMap { output[$0] as? String }
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? ""
        var name = rawName.trimmingCharacters(in: .whitespaces)

        if name.isEmpty {
            name = (try? await fetchStockName(code: code)) ?? code
        }

        let marketRaw = (output["rprs_mrkt_kor_name"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        let market = marketRaw.contains("코스닥") ? "KOSDAQ" : "KOSPI"

        return (StockInfo(code: code, name: name, market: market), quote)
    }

    private func fetchStockName(code: String) async throws -> String {
        let token = try await KISAuthService.shared.getToken()

        guard let appKey = KeychainService.load(key: .appKey),
              let appSecret = KeychainService.load(key: .appSecret)
        else { throw KISError.missingCredentials }

        var components = URLComponents(string: "\(baseURL)/uapi/domestic-stock/v1/quotations/search-stock-info")!
        components.queryItems = [
            URLQueryItem(name: "PDNO", value: code),
            URLQueryItem(name: "PRDT_TYPE_CD", value: "300"),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(appKey, forHTTPHeaderField: "appkey")
        request.setValue(appSecret, forHTTPHeaderField: "appsecret")
        request.setValue("CTPF1002R", forHTTPHeaderField: "tr_id")

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let output = json["output"] as? [String: Any]
        else { throw KISError.invalidResponse }

        let name = (output["prdt_abrv_name"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        if !name.isEmpty { return name }

        let fullName = (output["prdt_name"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        if !fullName.isEmpty { return fullName }

        throw KISError.invalidResponse
    }

    func fetchQuotes(codes: [String]) async -> [String: StockQuote] {
        var results: [String: StockQuote] = [:]
        for code in codes {
            try? await Task.sleep(for: .milliseconds(50)) // Rate limit
            if let quote = try? await fetchQuote(code: code) {
                results[code] = quote
            }
        }
        return results
    }
}
