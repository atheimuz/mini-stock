import SwiftUI

struct BalanceRowView: View {
    let holding: BalanceHolding

    var body: some View {
        VStack(spacing: 1) {
            // Row 1: 종목명 | 평가손익 | 보유수량 | 매입단가
            HStack(spacing: 0) {
                Text(holding.name)
                    .font(.widgetTitle)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(formatNumber(holding.profitLoss))
                    .font(.widgetTitle)
                    .foregroundStyle(profitColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("\(holding.holdingQty)")
                    .font(.hint)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text(formatNumber(holding.avgPrice))
                    .font(.hint)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Row 2: (공백) | 수익률 | 평가금액 | 현재가
            HStack(spacing: 0) {
                Text("")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(String(format: "%+.2f%%", holding.profitRate))
                    .font(.hint)
                    .foregroundStyle(profitColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text(formatNumber(holding.evalAmount))
                    .font(.hint)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text(formatNumber(holding.currentPrice))
                    .font(.hint)
                    .foregroundStyle(profitColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(holding.name), 수익 \(formatNumber(holding.profitLoss))원, \(String(format: "%+.2f%%", holding.profitRate))")
    }

    private var profitColor: Color {
        switch holding.direction {
        case .rise: .tileRiseText
        case .fall: .tileFallText
        case .flat: .tileFlatText
        }
    }

    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
