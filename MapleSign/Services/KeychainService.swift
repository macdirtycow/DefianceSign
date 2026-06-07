//
//  KeychainService.swift
//  MapleSign
//

import Foundation
import Security

enum KeychainService {
	private static let service = "net.maplesign.app.certificates"

	@discardableResult
	static func savePassword(_ password: String, for certificateUUID: String) -> Bool {
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
		attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

		let status = SecItemAdd(attributes as CFDictionary, nil)
		if status != errSecSuccess {
			print("KeychainService: failed to save password for \(certificateUUID), status \(status)")
			return false
		}
		return true
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

		if let legacyPassword = cert.password {
			KeychainService.savePassword(legacyPassword, for: uuid)
			return legacyPassword
		}

		return ""
	}

	func migrateCertificatePasswordsIfNeeded() {
		let request = CertificatePair.fetchRequest()
		guard let certificates = try? context.fetch(request) else { return }

		for cert in certificates {
			guard let uuid = cert.uuid else { continue }

			if KeychainService.loadPassword(for: uuid) != nil {
				continue
			}

			if let legacyPassword = cert.password {
				KeychainService.savePassword(legacyPassword, for: uuid)
			}
		}
	}
}
