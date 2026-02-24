import Foundation

enum PriceDirection: String, Codable {
    case rise
    case fall
    case flat
}

struct StockInfo: Identifiable, Codable, Hashable {
    let code: String
    let name: String
    let market: String
    var customLabel: String?

    var id: String { code }

    var displayLabel: String {
        customLabel ?? String(name.prefix(1))
    }
}

struct StockQuote {
    let code: String
    let currentPrice: Int
    let priceChange: Int
    let changeRate: Double
    let direction: PriceDirection

    static func from(apiResponse output: [String: Any], code: String) -> StockQuote? {
        guard
            let priceStr = output["stck_prpr"] as? String,
            let price = Int(priceStr),
            let changeStr = output["prdy_vrss"] as? String,
            let change = Int(changeStr),
            let rateStr = output["prdy_ctrt"] as? String,
            let rate = Double(rateStr),
            let signStr = output["prdy_vrss_sign"] as? String
        else { return nil }

        let direction: PriceDirection = switch signStr {
        case "1", "2": .rise
        case "4", "5": .fall
        default: .flat
        }

        return StockQuote(
            code: code,
            currentPrice: price,
            priceChange: change,
            changeRate: rate,
            direction: direction
        )
    }
}

struct WatchedStock: Identifiable, Codable {
    var stock: StockInfo
    var order: Int

    var id: String { stock.id }
}
