import SwiftUI

struct SearchPanelView: View {
    @Bindable var store: StockStore
    @State private var query = ""
    @State private var results: [StockInfo] = []
    @State private var isAddingByCode = false
    @State private var codeAddFailed = false
    @Environment(\.dismiss) private var dismiss

    private var isCodeQuery: Bool {
        query.count == 6 && query.allSatisfy(\.isNumber)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Search")
                    .font(.popoverName)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            TextField("Name or code", text: $query)
                .textFieldStyle(.plain)
                .font(.popoverPrice)
                .foregroundStyle(Color.textPrimary)
                .padding(8)
                .background(Color.tileFlatBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .onChange(of: query) { _, newValue in
                    results = store.searchService.search(query: newValue)
                }

            if results.isEmpty && !query.isEmpty {
                if isCodeQuery {
                    VStack(spacing: 8) {
                        Button(action: addByCode) {
                            HStack(spacing: 6) {
                                if isAddingByCode {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 13))
                                }
                                Text("코드로 추가: \(query)")
                                    .font(.popoverLabel)
                            }
                            .foregroundStyle(Color.tileRiseText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.tileRiseText.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(isAddingByCode)

                        if codeAddFailed {
                            Text("종목을 찾을 수 없습니다")
                                .font(.hint)
                                .foregroundStyle(Color.indicatorError)
                        }
                    }
                    .padding(.top, 16)
                } else {
                    Text("No results")
                        .font(.hint)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 20)
                }
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(results) { stock in
                        SearchResultRowView(
                            stock: stock,
                            isAdded: store.watchedStocks.contains { $0.stock.code == stock.code },
                            isFull: store.watchedStocks.count >= StockStore.maxStocks
                        ) {
                            store.addStock(stock)
                        }
                    }
                }
            }
            .frame(minHeight: 200, maxHeight: 500)

            HStack {
                Spacer()
                Text("\(store.watchedStocks.count)/\(StockStore.maxStocks)")
                    .font(.hint)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding()
        }
        .frame(width: 280)
        .background(Color.widgetBackground)
    }

    private func addByCode() {
        let code = query
        isAddingByCode = true
        codeAddFailed = false
        Task {
            do {
                try await store.addStockByCode(code)
                dismiss()
            } catch {
                codeAddFailed = true
            }
            isAddingByCode = false
        }
    }
}
