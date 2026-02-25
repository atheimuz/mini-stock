import Foundation

struct BalanceHolding: Identifiable {
    let code: String
    let name: String
    let holdingQty: Int
    let avgPrice: Int
    let purchaseAmount: Int
    let currentPrice: Int
    let evalAmount: Int
    let profitLoss: Int
    let profitRate: Double
    let direction: PriceDirection

    var id: String { code }

    static func from(apiResponse output: [String: Any]) -> BalanceHolding? {
        guard
            let code = output["pdno"] as? String,
            !code.isEmpty,
            let qtyStr = output["hldg_qty"] as? String,
            let qty = Int(qtyStr),
            qty > 0
        else { return nil }

        let rawName = (output["prdt_name"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        let name = rawName.isEmpty ? code : rawName

        let avgPrice = Int(Double(output["pchs_avg_pric"] as? String ?? "0") ?? 0)
        let purchaseAmount = Int(output["pchs_amt"] as? String ?? "0") ?? 0
        let currentPrice = Int(output["prpr"] as? String ?? "0") ?? 0
        let evalAmount = Int(output["evlu_amt"] as? String ?? "0") ?? 0
        let profitLoss = Int(output["evlu_pfls_amt"] as? String ?? "0") ?? 0
        let profitRate = Double(output["evlu_pfls_rt"] as? String ?? "0") ?? 0

        let direction: PriceDirection
        if profitLoss > 0 {
            direction = .rise
        } else if profitLoss < 0 {
            direction = .fall
        } else {
            direction = .flat
        }

        return BalanceHolding(
            code: code,
            name: name,
            holdingQty: qty,
            avgPrice: avgPrice,
            purchaseAmount: purchaseAmount,
            currentPrice: currentPrice,
            evalAmount: evalAmount,
            profitLoss: profitLoss,
            profitRate: profitRate,
            direction: direction
        )
    }
}

struct BalanceSummary {
    let totalPurchaseAmount: Int
    let totalEvalAmount: Int
    let totalProfitLoss: Int
    let totalProfitRate: Double
    let direction: PriceDirection

    static let zero = BalanceSummary(
        totalPurchaseAmount: 0,
        totalEvalAmount: 0,
        totalProfitLoss: 0,
        totalProfitRate: 0,
        direction: .flat
    )

    static func from(output2: [String: Any]) -> BalanceSummary {
        let purchaseAmount = Int(output2["pchs_amt_smtl_amt"] as? String ?? "0") ?? 0
        let evalAmount = Int(output2["evlu_amt_smtl_amt"] as? String ?? "0") ?? 0
        let profitLoss = Int(output2["evlu_pfls_smtl_amt"] as? String ?? "0") ?? 0

        let profitRate: Double
        if purchaseAmount > 0 {
            profitRate = Double(profitLoss) / Double(purchaseAmount) * 100
        } else {
            profitRate = 0
        }

        let direction: PriceDirection
        if profitLoss > 0 {
            direction = .rise
        } else if profitLoss < 0 {
            direction = .fall
        } else {
            direction = .flat
        }

        return BalanceSummary(
            totalPurchaseAmount: purchaseAmount,
            totalEvalAmount: evalAmount,
            totalProfitLoss: profitLoss,
            totalProfitRate: profitRate,
            direction: direction
        )
    }
}
