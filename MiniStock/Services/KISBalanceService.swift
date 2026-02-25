import Foundation

final class KISBalanceService {
    static let shared = KISBalanceService()

    private let baseURL = "https://openapi.koreainvestment.com:9443"

    func fetchBalance(isRetry: Bool = false) async throws -> (holdings: [BalanceHolding], summary: BalanceSummary) {
        let token = try await KISAuthService.shared.getToken()

        guard let appKey = KeychainService.load(key: .appKey),
              let appSecret = KeychainService.load(key: .appSecret),
              let accountNumber = KeychainService.load(key: .accountNumber),
              !accountNumber.isEmpty
        else {
            throw KISError.missingCredentials
        }

        let cano = String(accountNumber.prefix(8))

        var components = URLComponents(string: "\(baseURL)/uapi/domestic-stock/v1/trading/inquire-balance")!
        components.queryItems = [
            URLQueryItem(name: "CANO", value: cano),
            URLQueryItem(name: "ACNT_PRDT_CD", value: "01"),
            URLQueryItem(name: "AFHR_FLPR_YN", value: "N"),
            URLQueryItem(name: "INQR_DVSN", value: "02"),
            URLQueryItem(name: "UNPR_DVSN", value: "01"),
            URLQueryItem(name: "FUND_STTL_ICLD_YN", value: "N"),
            URLQueryItem(name: "FNCG_AMT_AUTO_RDPT_YN", value: "N"),
            URLQueryItem(name: "PRCS_DVSN", value: "00"),
            URLQueryItem(name: "CTX_AREA_FK100", value: ""),
            URLQueryItem(name: "CTX_AREA_NK100", value: ""),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(appKey, forHTTPHeaderField: "appkey")
        request.setValue(appSecret, forHTTPHeaderField: "appsecret")
        request.setValue("TTTC8434R", forHTTPHeaderField: "tr_id")
        request.setValue("P", forHTTPHeaderField: "custtype")

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
            if msgCd.hasPrefix("EGW"), !isRetry {
                await KISAuthService.shared.invalidateToken()
                return try await fetchBalance(isRetry: true)
            }
            throw KISError.quoteFailed("\(msgCd): \(msg)")
        }

        let output1 = json["output1"] as? [[String: Any]] ?? []
        let output2 = json["output2"] as? [[String: Any]] ?? []

        let holdings = output1.compactMap { BalanceHolding.from(apiResponse: $0) }
        let summary = output2.first.map { BalanceSummary.from(output2: $0) } ?? .zero

        return (holdings, summary)
    }
}
