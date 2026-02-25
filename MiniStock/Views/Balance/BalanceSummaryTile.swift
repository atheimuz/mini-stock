import SwiftUI

struct BalanceSummaryTile: View {
    let summary: BalanceSummary

    var body: some View {
        HStack {
            Text("총 수익")
                .font(.hint)
                .foregroundStyle(Color.white)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedProfitLoss)
                    .font(.widgetTitle)
                    .foregroundStyle(profitColor)

                Text(formattedProfitRate)
                    .font(.hint)
                    .foregroundStyle(profitColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("총 수익 \(formattedProfitLoss), 수익률 \(formattedProfitRate)")
    }

    private var profitColor: Color {
        switch summary.direction {
        case .rise: .tileRiseText
        case .fall: .tileFallText
        case .flat: .tileFlatText
        }
    }

    private var backgroundColor: Color {
        switch summary.direction {
        case .rise: .tileRiseBackground
        case .fall: .tileFallBackground
        case .flat: .tileFlatBackground
        }
    }

    private var formattedProfitLoss: String {
        let sign = summary.totalProfitLoss > 0 ? "+" : ""
        return "\(sign)\(formatNumber(summary.totalProfitLoss))원"
    }

    private var formattedProfitRate: String {
        String(format: "%+.2f%%", summary.totalProfitRate)
    }

    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
