import SwiftUI

struct SettingsPanelView: View {
    @Bindable var store: StockStore
    @State private var appKey = ""
    @State private var appSecret = ""
    @State private var testResult: TestResult?
    @State private var isTesting = false
    @Environment(\.dismiss) private var dismiss

    enum TestResult {
        case success
        case failure(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Settings")
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

            VStack(alignment: .leading, spacing: 8) {
                Text("API Configuration")
                    .font(.popoverRate)
                    .foregroundStyle(Color.textSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("App Key")
                        .font(.hint)
                        .foregroundStyle(Color.textSecondary)
                    SecureField("36-character key", text: $appKey)
                        .textFieldStyle(.plain)
                        .font(.popoverLabel)
                        .foregroundStyle(Color.textPrimary)
                        .padding(6)
                        .background(Color.tileFlatBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("App Secret")
                        .font(.hint)
                        .foregroundStyle(Color.textSecondary)
                    SecureField("180-character secret", text: $appSecret)
                        .textFieldStyle(.plain)
                        .font(.popoverLabel)
                        .foregroundStyle(Color.textPrimary)
                        .padding(6)
                        .background(Color.tileFlatBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            HStack(spacing: 8) {
                Button(action: testConnection) {
                    HStack(spacing: 4) {
                        if isTesting {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Test Connection")
                    }
                    .font(.buttonFont)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.tileFlatBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(appKey.isEmpty || appSecret.isEmpty || isTesting)

                if let result = testResult {
                    switch result {
                    case .success:
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .font(.hint)
                            .foregroundStyle(Color.accentFall)
                    case .failure(let msg):
                        Label(msg, systemImage: "xmark.circle.fill")
                            .font(.hint)
                            .foregroundStyle(Color.indicatorError)
                    }
                }
            }

            Divider()
                .background(Color.widgetBorder)

            HStack {
                Spacer()
                Button("Save") { saveCredentials() }
                    .font(.buttonFont)
                    .foregroundStyle(Color.widgetBackground)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(Color.tileRiseText)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .buttonStyle(.plain)
                    .disabled(appKey.isEmpty || appSecret.isEmpty)
            }

            Link("How to get API keys",
                 destination: URL(string: "https://apiportal.koreainvestment.com/apiservice")!)
                .font(.hint)
                .foregroundStyle(Color.tileRiseText)
        }
        .padding()
        .frame(width: 300)
        .background(Color.widgetBackground)
        .onAppear {
            appKey = KeychainService.load(key: .appKey) ?? ""
            appSecret = KeychainService.load(key: .appSecret) ?? ""
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        Task {
            do {
                try KeychainService.save(key: .appKey, value: appKey)
                try KeychainService.save(key: .appSecret, value: appSecret)
                await KISAuthService.shared.invalidateToken()
                _ = try await KISAuthService.shared.getToken()
                testResult = .success
            } catch {
                testResult = .failure("Failed")
            }
            isTesting = false
        }
    }

    private func saveCredentials() {
        do {
            try KeychainService.save(key: .appKey, value: appKey)
            try KeychainService.save(key: .appSecret, value: appSecret)
            Task { await store.refreshAll() }
            dismiss()
        } catch {
            testResult = .failure("Save failed")
        }
    }
}
