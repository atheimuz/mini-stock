import SwiftUI

struct UndoToastView: View {
    @Bindable var store: StockStore

    @State private var progress: Double = 1.0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Removed")
                    .font(.toast)
                    .foregroundStyle(Color.toastText)

                Spacer()

                Button("Undo") {
                    store.undoRemove()
                }
                .font(.toast)
                .foregroundStyle(Color.toastAction)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.toastAction.opacity(0.3))
                    .frame(width: geometry.size.width * progress)
            }
            .frame(height: 2)
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.toastBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.linear(duration: 5)) {
                progress = 0
            }
        }
        .onDisappear {
            progress = 1.0
        }
    }
}
