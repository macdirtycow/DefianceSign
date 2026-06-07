//
//  KeychainService.swift
//  MapleSign
//

import Foundation
import Security

enum KeychainService {
	private static let service = "net.maplesign.app.certificates"

	static func savePassword(_ password: String, for certificateUUID: String) {
		let account = certificateUUID
		let data = Data(password.utf8)

		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
		]

		SecItemDelete(query as CFDictionary)

		var attributes = query
		attributes[kSecValueData as String] = data
		attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

		let status = SecItemAdd(attributes as CFDictionary, nil)
		if status != errSecSuccess {
			print("KeychainService: failed to save password for \(certificateUUID), status \(status)")
		}
	}

	static func loadPassword(for certificateUUID: String) -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: certificateUUID,
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne,
		]

		var result: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		guard status == errSecSuccess, let data = result as? Data else {
			return nil
		}
		return String(data: data, encoding: .utf8)
	}

	static func deletePassword(for certificateUUID: String) {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: certificateUUID,
		]
		SecItemDelete(query as CFDictionary)
	}
}

extension Storage {
	func certificatePassword(for cert: CertificatePair) -> String {
		guard let uuid = cert.uuid else { return "" }

		if let keychainPassword = KeychainService.loadPassword(for: uuid) {
			return keychainPassword
		}

		if let legacyPassword = cert.password, !legacyPassword.isEmpty {
			KeychainService.savePassword(legacyPassword, for: uuid)
			cert.password = nil
			saveContext()
			return legacyPassword
		}

		return ""
	}
}
