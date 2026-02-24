import SwiftUI

struct SearchResultRowView: View {
    let stock: StockInfo
    let isAdded: Bool
    let isFull: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name)
                    .font(.popoverPrice)
                    .foregroundStyle(Color.textPrimary)
                Text("\(stock.code) · \(stock.market)")
                    .font(.popoverLabel)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            if isAdded {
                Image(systemName: "checkmark")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.accentFall)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(isFull ? Color.textSecondary : Color.tileRiseText)
                }
                .buttonStyle(.plain)
                .disabled(isFull)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
