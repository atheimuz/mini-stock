import SwiftUI

struct SettingsPanelView: View {
    @Bindable var store: StockStore
    @State private var appKey = ""
    @State private var appSecret = ""
    @State private var showAppKey = false
    @State private var showAppSecret = false
    @State private var testResult: TestResult?
    @State private var isTesting = false
    private func close() { store.showSettings = false }

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
                Button(action: { close() }) {
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
                    secretField("36-character key", text: $appKey, isRevealed: $showAppKey)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("App Secret")
                        .font(.hint)
                        .foregroundStyle(Color.textSecondary)
                    secretField("180-character secret", text: $appSecret, isRevealed: $showAppSecret)
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

            updateSection

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

    private var updater: AppUpdateService { AppUpdateService.shared }

    private var updateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("App Update")
                .font(.popoverRate)
                .foregroundStyle(Color.textSecondary)

            HStack {
                Text("v\(updater.currentVersion)")
                    .font(.popoverLabel)
                    .foregroundStyle(Color.textSecondary)

                Spacer()

                updateStatusView
            }
        }
    }

    @ViewBuilder
    private var updateStatusView: some View {
        switch updater.status {
        case .idle:
            Button(action: { Task { await updater.checkForUpdate() } }) {
                Text("Check for Updates")
                    .font(.buttonFont)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.tileFlatBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

        case .checking:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.small)
                Text("확인 중...")
                    .font(.hint)
                    .foregroundStyle(Color.textSecondary)
            }

        case .upToDate:
            Label("최신 버전", systemImage: "checkmark.circle.fill")
                .font(.hint)
                .foregroundStyle(Color.accentFall)

        case .available(let version, let url):
            Button(action: { Task { await updater.downloadAndInstall(url: url) } }) {
                Text("v\(version) 업데이트")
                    .font(.buttonFont)
                    .foregroundStyle(Color.widgetBackground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.tileRiseText)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

        case .downloading(let progress):
            VStack(alignment: .trailing, spacing: 2) {
                ProgressView(value: progress)
                    .frame(width: 100)
                Text("\(Int(progress * 100))%")
                    .font(.hint)
                    .foregroundStyle(Color.textSecondary)
            }

        case .installing:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.small)
                Text("설치 중...")
                    .font(.hint)
                    .foregroundStyle(Color.textSecondary)
            }

        case .failed(let msg):
            HStack(spacing: 6) {
                Label("실패", systemImage: "xmark.circle.fill")
                    .font(.hint)
                    .foregroundStyle(Color.indicatorError)
                    .help(msg)
                Button(action: { Task { await updater.checkForUpdate() } }) {
                    Text("재시도")
                        .font(.hint)
                        .foregroundStyle(Color.tileRiseText)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func secretField(_ placeholder: String, text: Binding<String>, isRevealed: Binding<Bool>) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.popoverLabel)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.leading, 2)
            }
            HStack(spacing: 4) {
                if isRevealed.wrappedValue {
                    TextField("", text: text)
                } else {
                    SecureField("", text: text)
                }
                Button { isRevealed.wrappedValue.toggle() } label: {
                    Image(systemName: isRevealed.wrappedValue ? "eye.slash" : "eye")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .textFieldStyle(.plain)
        .font(.popoverLabel)
        .foregroundStyle(Color.textPrimary)
        .padding(6)
        .background(Color.tileFlatBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
            close()
        } catch {
            testResult = .failure("Save failed")
        }
    }
}
