import Foundation

final class StockSearchService {
    private var allStocks: [StockInfo] = []

    init() {
        loadCSV()
    }

    private func loadCSV() {
        guard let url = Bundle.module.url(forResource: "krx_stocks", withExtension: "csv"),
              let content = try? String(contentsOf: url, encoding: .utf8)
        else { return }

        let lines = content.components(separatedBy: .newlines)
        allStocks = lines.dropFirst().compactMap { line -> StockInfo? in
            let cols = line.components(separatedBy: ",")
            guard cols.count >= 3 else { return nil }
            let code = cols[0].trimmingCharacters(in: .whitespaces)
            let name = cols[1].trimmingCharacters(in: .whitespaces)
            let market = cols[2].trimmingCharacters(in: .whitespaces)
            guard !code.isEmpty else { return nil }
            return StockInfo(code: code, name: name, market: market)
        }
    }

    func findByCode(_ code: String) -> StockInfo? {
        allStocks.first { $0.code == code }
    }

    func search(query: String) -> [StockInfo] {
        guard !query.isEmpty else { return [] }
        let lowered = query.lowercased()
        return allStocks.filter { stock in
            stock.name.lowercased().contains(lowered) ||
            stock.code.contains(lowered)
        }
    }
}
