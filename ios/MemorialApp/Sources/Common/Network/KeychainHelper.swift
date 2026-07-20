import Foundation
import Security

struct KeychainHelper {
    private static let service = "com.pawlight.app"
    private static let tokenKey = "jwt_token"
    private static let userIdDefaultsKey = "userId"

    static func saveToken(_ token: String) {
        save(key: tokenKey, value: token)
    }

    static func loadToken() -> String? {
        load(key: tokenKey)
    }

    static func deleteToken() {
        delete(key: tokenKey)
        UserDefaults.standard.removeObject(forKey: userIdDefaultsKey)
    }

    static func saveUserId(_ id: String) {
        UserDefaults.standard.set(id, forKey: userIdDefaultsKey)
    }

    static func loadUserId() -> String? {
        UserDefaults.standard.string(forKey: userIdDefaultsKey)
    }

    private static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        SecItemAdd(attrs as CFDictionary, nil)
    }

    private static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
