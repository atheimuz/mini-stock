import Foundation
import SwiftUI

@Observable
final class StockStore {
    // MARK: - State
    var watchedStocks: [WatchedStock] = []
    var quotes: [String: StockQuote] = [:]
    var isRefreshing = false
    var lastRefreshTime: Date?
    var hasError = false
    var showSearch = false
    var showSettings = false

    // MARK: - Undo
    var undoItem: UndoItem?

    // MARK: - Onboarding
    var hasShownHoverHint: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hoverHintShown) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hoverHintShown) }
    }
    var showHoverHint = false

    // MARK: - Services
    let searchService = StockSearchService()
    private var refreshTimer: Timer?

    private enum Keys {
        static let watchedStocks = "watched_stocks"
        static let hoverHintShown = "hover_hint_shown"
    }

    static let maxStocks = 20
    static let refreshInterval: TimeInterval = 300 // 5 minutes

    init() {
        loadStocks()
        startTimer()
    }

    // MARK: - Stock Management

    func addStock(_ stock: StockInfo) {
        guard watchedStocks.count < Self.maxStocks else { return }
        guard !watchedStocks.contains(where: { $0.stock.code == stock.code }) else { return }

        let watched = WatchedStock(stock: stock, order: watchedStocks.count)
        watchedStocks.append(watched)
        saveStocks()

        if !hasShownHoverHint && watchedStocks.count == 1 {
            showHoverHint = true
            hasShownHoverHint = true
        }

        Task { await refreshSingle(code: stock.code) }
    }

    func addStockByCode(_ code: String) async throws {
        guard watchedStocks.count < Self.maxStocks else { return }
        guard !watchedStocks.contains(where: { $0.stock.code == code }) else { return }
        let (apiInfo, quote) = try await KISQuoteService.shared.fetchStockInfo(code: code)

        let info: StockInfo
        if let csvStock = searchService.findByCode(code) {
            info = StockInfo(code: code, name: csvStock.name, market: csvStock.market)
        } else {
            info = apiInfo
        }

        addStock(info)
        quotes[code] = quote
    }

    func removeStock(code: String) {
        guard let index = watchedStocks.firstIndex(where: { $0.stock.code == code }) else { return }
        let removed = watchedStocks.remove(at: index)
        let removedQuote = quotes.removeValue(forKey: code)
        reorderStocks()
        saveStocks()

        undoItem = UndoItem(
            stock: removed,
            quote: removedQuote,
            index: index
        )

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            if self.undoItem?.stock.stock.code == code {
                self.undoItem = nil
            }
        }
    }

    func undoRemove() {
        guard let item = undoItem else { return }
        let index = min(item.index, watchedStocks.count)
        watchedStocks.insert(item.stock, at: index)
        if let quote = item.quote {
            quotes[item.stock.stock.code] = quote
        }
        reorderStocks()
        saveStocks()
        undoItem = nil
    }

    func updateLabel(code: String, label: String) {
        guard let index = watchedStocks.firstIndex(where: { $0.stock.code == code }) else { return }
        watchedStocks[index].stock.customLabel = label.isEmpty ? nil : label
        saveStocks()
    }

    func moveStock(from source: IndexSet, to destination: Int) {
        watchedStocks.move(fromOffsets: source, toOffset: destination)
        reorderStocks()
        saveStocks()
    }

    // MARK: - Refresh

    func refreshAll() async {
        guard KeychainService.hasCredentials else { return }
        isRefreshing = true
        hasError = false

        let codes = watchedStocks.map(\.stock.code)
        let newQuotes = await KISQuoteService.shared.fetchQuotes(codes: codes)

        if newQuotes.isEmpty && !codes.isEmpty {
            hasError = true
        } else {
            for (code, quote) in newQuotes {
                quotes[code] = quote
            }
            lastRefreshTime = Date()
        }
        isRefreshing = false
    }

    private func refreshSingle(code: String) async {
        guard KeychainService.hasCredentials else { return }
        if let quote = try? await KISQuoteService.shared.fetchQuote(code: code) {
            quotes[code] = quote
        }
    }

    // MARK: - Timer

    func startTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refreshAll() }
        }
        Task { await refreshAll() }
    }

    func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Persistence

    private func saveStocks() {
        if let data = try? JSONEncoder().encode(watchedStocks) {
            UserDefaults.standard.set(data, forKey: Keys.watchedStocks)
        }
    }

    private func loadStocks() {
        guard let data = UserDefaults.standard.data(forKey: Keys.watchedStocks),
              let stocks = try? JSONDecoder().decode([WatchedStock].self, from: data)
        else { return }
        watchedStocks = stocks
    }

    private func reorderStocks() {
        for i in watchedStocks.indices {
            watchedStocks[i].order = i
        }
    }

    // MARK: - Helpers

    func direction(for code: String) -> PriceDirection {
        quotes[code]?.direction ?? .flat
    }

    var isConfigured: Bool {
        KeychainService.hasCredentials
    }
}

struct UndoItem {
    let stock: WatchedStock
    let quote: StockQuote?
    let index: Int
}
