import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    private func query(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Constants.appName
        ]
    }

    func save(_ value: String, for key: String) {
        guard let data = value.data(using: .utf8) else { return }
        var query = query(for: key)
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        SecItemAdd(query as CFDictionary, nil)
    }

    func get(_ key: String) -> String? {
        var query = query(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(_ key: String) {
        let query = query(for: key)
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Токены
    var authToken: String? {
        get { get("auth_token") }
        set { if let v = newValue { save(v, for: "auth_token") } else { delete("auth_token") } }
    }

    var refreshToken: String? {
        get { get("refresh_token") }
        set { if let v = newValue { save(v, for: "refresh_token") } else { delete("refresh_token") } }
    }

    var currentUserID: String? {
        get { get("current_user_id") }
        set { if let v = newValue { save(v, for: "current_user_id") } else { delete("current_user_id") } }
    }

    var privateKey: String? {
        get { get("e2ee_private_key") }
        set { if let v = newValue { save(v, for: "e2ee_private_key") } else { delete("e2ee_private_key") } }
    }

    var publicKey: String? {
        get { get("e2ee_public_key") }
        set { if let v = newValue { save(v, for: "e2ee_public_key") } else { delete("e2ee_public_key") } }
    }

    var pinCode: String? {
        get { get("pin_code") }
        set { if let v = newValue { save(v, for: "pin_code") } else { delete("pin_code") } }
    }
}
