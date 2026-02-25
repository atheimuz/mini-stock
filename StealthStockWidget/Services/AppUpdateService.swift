import Foundation
import AppKit

enum UpdateStatus: Equatable {
    case idle
    case checking
    case upToDate
    case available(version: String, downloadURL: URL)
    case downloading(progress: Double)
    case installing
    case failed(String)
}

enum UpdateError: LocalizedError {
    case noAppInDMG
    case installFailed(String)
    case processFailed(String)
    case developmentBuild

    var errorDescription: String? {
        switch self {
        case .noAppInDMG: return "DMG에서 앱을 찾을 수 없습니다"
        case .installFailed(let msg): return "설치 실패: \(msg)"
        case .processFailed(let msg): return "프로세스 실패: \(msg)"
        case .developmentBuild: return "개발 빌드에서는 업데이트할 수 없습니다"
        }
    }
}

private struct GitHubRelease: Decodable {
    let tag_name: String
    let assets: [GitHubAsset]
}

private struct GitHubAsset: Decodable {
    let name: String
    let browser_download_url: String
}

@Observable
final class AppUpdateService: NSObject {
    static let shared = AppUpdateService()

    private let owner = "atheimuz"
    private let repo = "mini-stock"

    var status: UpdateStatus = .idle

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private var downloadContinuation: CheckedContinuation<URL, Error>?

    // MARK: - Check for Update

    func checkForUpdate() async {
        status = .checking

        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/releases/latest"
        guard let url = URL(string: urlString) else {
            status = .failed("잘못된 URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                status = .failed("GitHub API 오류")
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latestVersion = release.tag_name.hasPrefix("v")
                ? String(release.tag_name.dropFirst())
                : release.tag_name

            guard isVersion(latestVersion, newerThan: currentVersion) else {
                status = .upToDate
                return
            }

            guard let dmgAsset = release.assets.first(where: { $0.name.hasSuffix(".dmg") }),
                  let downloadURL = URL(string: dmgAsset.browser_download_url)
            else {
                status = .failed("릴리스에 DMG 파일 없음")
                return
            }

            status = .available(version: latestVersion, downloadURL: downloadURL)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    // MARK: - Download and Install

    func downloadAndInstall(url: URL) async {
        guard !Bundle.main.bundlePath.contains(".build") else {
            status = .failed("개발 빌드에서는 업데이트 불가")
            return
        }

        status = .downloading(progress: 0)

        do {
            let localURL = try await downloadDMG(from: url)
            status = .installing
            try await installFromDMG(at: localURL)
            restartApp()
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    // MARK: - Private

    private func downloadDMG(from url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            self.downloadContinuation = continuation
            let session = URLSession(
                configuration: .default,
                delegate: self,
                delegateQueue: nil
            )
            session.downloadTask(with: url).resume()
        }
    }

    private func installFromDMG(at dmgPath: URL) async throws {
        let mountPoint = FileManager.default.temporaryDirectory
            .appendingPathComponent("StealthStockWidgetUpdate").path

        // Clean up any previous mount
        try? await runProcess("/usr/bin/hdiutil", arguments: ["detach", mountPoint, "-force"])

        // Mount DMG
        try await runProcess(
            "/usr/bin/hdiutil",
            arguments: ["attach", dmgPath.path, "-nobrowse", "-mountpoint", mountPoint]
        )

        defer {
            Task {
                try? await runProcess("/usr/bin/hdiutil", arguments: ["detach", mountPoint, "-force"])
                try? FileManager.default.removeItem(at: dmgPath)
            }
        }

        // Find .app in mounted DMG
        let contents = try FileManager.default.contentsOfDirectory(atPath: mountPoint)
        guard let appName = contents.first(where: { $0.hasSuffix(".app") }) else {
            throw UpdateError.noAppInDMG
        }

        let sourceApp = "\(mountPoint)/\(appName)"
        let currentAppPath = Bundle.main.bundlePath
        let backupPath = currentAppPath + ".bak"

        // Backup current app
        try? FileManager.default.removeItem(atPath: backupPath)
        try FileManager.default.moveItem(atPath: currentAppPath, toPath: backupPath)

        // Copy new app
        do {
            try FileManager.default.copyItem(atPath: sourceApp, toPath: currentAppPath)
        } catch {
            // Rollback
            try? FileManager.default.removeItem(atPath: currentAppPath)
            try? FileManager.default.moveItem(atPath: backupPath, toPath: currentAppPath)
            throw UpdateError.installFailed(error.localizedDescription)
        }

        // Remove backup
        try? FileManager.default.removeItem(atPath: backupPath)
    }

    private func restartApp() {
        let appPath = Bundle.main.bundlePath
        let script = "sleep 1; open \"\(appPath)\""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        try? process.run()

        DispatchQueue.main.async {
            NSApplication.shared.terminate(nil)
        }
    }

    private func runProcess(_ path: String, arguments: [String]) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw UpdateError.processFailed("\(path) exited with \(process.terminationStatus)")
        }
    }

    private func isVersion(_ new: String, newerThan current: String) -> Bool {
        let newParts = new.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(newParts.count, currentParts.count) {
            let n = i < newParts.count ? newParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if n > c { return true }
            if n < c { return false }
        }
        return false
    }
}

// MARK: - URLSessionDownloadDelegate

extension AppUpdateService: URLSessionDownloadDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("StealthStockWidget-update.dmg")
        try? FileManager.default.removeItem(at: dest)

        do {
            try FileManager.default.moveItem(at: location, to: dest)
            downloadContinuation?.resume(returning: dest)
        } catch {
            downloadContinuation?.resume(throwing: error)
        }
        downloadContinuation = nil
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0
        Task { @MainActor in
            self.status = .downloading(progress: progress)
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            downloadContinuation?.resume(throwing: error)
            downloadContinuation = nil
        }
    }
}
