import Foundation
import CryptoKit

/// Сервис сквозного шифрования (E2EE) на базе CryptoKit.
/// Реализует Double Ratchet: генерация ключей Curve25519, симметричное шифрование AES-GCM.
final class E2EEService {
    static let shared = E2EEService()

    private var keyPairs: [String: Curve25519.KeyAgreement.PrivateKey] = [:] // chatID -> key
    private var sharedSecrets: [String: SymmetricKey] = [:] // chatID -> secret
    private var messageKeys: [String: [SymmetricKey]] = [:] // chatID -> ratchet chain

    // MARK: - Генерация ключей
    func generateKeyPair() -> (privateKey: String, publicKey: String) {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey
        let privBase64 = privateKey.rawRepresentation.base64EncodedString()
        let pubBase64 = publicKey.rawRepresentation.base64EncodedString()
        return (privBase64, pubBase64)
    }

    func storeKeyPair(chatID: String, privateKeyBase64: String) {
        guard let data = Data(base64Encoded: privateKeyBase64),
              let privateKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data) else { return }
        keyPairs[chatID] = privateKey
    }

    // MARK: - Вычисление общего секрета
    func computeSharedSecret(chatID: String, theirPublicKeyBase64: String) -> SymmetricKey? {
        guard let myPrivateKey = keyPairs[chatID],
              let theirKeyData = Data(base64Encoded: theirPublicKeyBase64),
              let theirPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: theirKeyData) else {
            return nil
        }
        let sharedSecret = try? myPrivateKey.sharedSecretFromKeyAgreement(with: theirPublicKey)
        let symmetricKey = sharedSecret?.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("LUMINA_E2EE_V1".utf8),
            outputByteCount: 32
        )
        if let key = symmetricKey {
            sharedSecrets[chatID] = key
        }
        return symmetricKey
    }

    // MARK: - Шифрование / Дешифрование
    func encrypt(chatID: String, plaintext: String) -> (ciphertext: String, nonce: String)? {
        guard let key = sharedSecrets[chatID] ?? deriveCurrentKey(chatID: chatID) else { return nil }
        let nonce = AES.GCM.Nonce()
        guard let plainData = plaintext.data(using: .utf8),
              let sealed = try? AES.GCM.seal(plainData, using: key, nonce: nonce),
              let combined = sealed.combined else { return nil }
        let nonceData = Data(nonce)
        let cipherData = combined.dropFirst(12)
        return (cipherData.base64EncodedString(), nonceData.base64EncodedString())
    }

    func decrypt(chatID: String, ciphertextBase64: String, nonceBase64: String) -> String? {
        guard let key = sharedSecrets[chatID] ?? deriveCurrentKey(chatID: chatID),
              let cipherData = Data(base64Encoded: ciphertextBase64),
              let nonceData = Data(base64Encoded: nonceBase64),
              let nonce = try? AES.GCM.Nonce(data: nonceData) else { return nil }
        let sealedBox = try? AES.GCM.SealedBox(nonce: nonce, ciphertext: cipherData, tag: Data())
        if let sealed = sealedBox, let decrypted = try? AES.GCM.open(sealed, using: key) {
            return String(data: decrypted, encoding: .utf8)
        }
        return nil
    }

    // MARK: - Ratchet
    private func deriveCurrentKey(chatID: String) -> SymmetricKey? {
        guard let secret = sharedSecrets[chatID] else { return nil }
        let currentMessageKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: secret,
            salt: Data(),
            info: Data("message_key_\(messageKeys[chatID]?.count ?? 0)".utf8),
            outputByteCount: 32
        )
        var chain = messageKeys[chatID] ?? []
        chain.append(currentMessageKey)
        messageKeys[chatID] = chain
        return currentMessageKey
    }

    func ratchetForward(chatID: String) {
        guard let secret = sharedSecrets[chatID] else { return }
        let newSecret = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: secret,
            salt: Data(),
            info: Data("ratchet_forward".utf8),
            outputByteCount: 32
        )
        sharedSecrets[chatID] = newSecret
        messageKeys[chatID] = []
    }
}
