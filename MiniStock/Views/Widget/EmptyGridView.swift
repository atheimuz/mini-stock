import SwiftUI

struct EmptyGridView: View {
    let message: String
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(message)
                .font(.hint)
                .foregroundStyle(Color.textSecondary)

            if let action {
                Button(action: action) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.textSecondary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .frame(minHeight: 120)
    }
}
