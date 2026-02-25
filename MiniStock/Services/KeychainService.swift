import Foundation

// UserDefaults 기반 저장 (서명 없는 개발 빌드에서 Keychain 반복 경고 회피)
enum KeychainService {
    enum Key: String {
        case appKey = "kis_app_key"
        case appSecret = "kis_app_secret"
        case accountNumber = "kis_account_number"
    }

    static func save(key: Key, value: String) throws {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    static func load(key: Key) -> String? {
        UserDefaults.standard.string(forKey: key.rawValue)
    }

    static func delete(key: Key) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }

    static var hasCredentials: Bool {
        load(key: .appKey) != nil && load(key: .appSecret) != nil
    }

    static var hasAccountNumber: Bool {
        guard let account = load(key: .accountNumber) else { return false }
        return !account.isEmpty
    }
}

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Save failed: \(status)"
        }
    }
}
