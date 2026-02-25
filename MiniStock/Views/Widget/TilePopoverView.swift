import SwiftUI

struct TilePopoverView: View {
    let stock: StockInfo
    let quote: StockQuote?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stock.name)
                .font(.popoverName)
                .foregroundStyle(Color.textPrimary)

            if let quote {
                Text(formattedPrice(quote.currentPrice))
                    .font(.popoverPrice)
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: 4) {
                    Text(formattedChange(quote.priceChange))
                        .font(.popoverRate)
                        .foregroundStyle(accentColor(quote.direction))

                    Text("(\(String(format: "%.2f", quote.changeRate))%)")
                        .font(.popoverRate)
                        .foregroundStyle(accentColor(quote.direction))
                }
            } else {
                Text("Loading...")
                    .font(.popoverLabel)
                    .foregroundStyle(Color.textSecondary)
            }

            Text("\(stock.code) · \(stock.market)")
                .font(.popoverLabel)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(12)
        .background(Color.widgetBackground)
    }

    private func formattedPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: price)) ?? "\(price)") + "원"
    }

    private func formattedChange(_ change: Int) -> String {
        if change > 0 { return "+\(change)" }
        return "\(change)"
    }

    private func accentColor(_ direction: PriceDirection) -> Color {
        switch direction {
        case .rise: return .accentRise
        case .fall: return .accentFall
        case .flat: return .accentFlat
        }
    }
}
