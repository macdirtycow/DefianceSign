//
//  FR.swift
//  Feather
//
//  Created by samara on 22.04.2025.
//

import Foundation.NSURL
import UIKit.UIImage
import Security
import Zsign
import NimbleJSON
import AltSourceKit
import IDeviceSwift

enum FR {
	static func handlePackageFile(
		_ ipa: URL,
		download: Download? = nil,
		completion: @escaping (Error?) -> Void
	) {
		Task.detached {
			let handler = AppFileHandler(file: ipa, download: download)
			
			do {
				try await handler.copy()
				try await handler.extract()
				try await handler.move()
				try await handler.addToDatabase()
                
                                try? await handler.clean()
				await MainActor.run {
					completion(nil)
				}
			} catch {
				try await handler.clean()
				await MainActor.run {
					completion(error)
				}
			}
		}
	}
	
	static func signPackageFile(
		_ app: AppInfoPresentable,
		using options: Options,
		icon: UIImage?,
		certificate: CertificatePair?,
		completion: @escaping (Error?) -> Void
	) {
		Task.detached {
			let handler = SigningHandler(app: app, options: options)
			if !options.onlyModify {
				handler.appCertificate = certificate
			}
			handler.appIcon = icon
			
			do {
				try await handler.copy()
				try await handler.modify()
                try? await handler.clean()
				
				await MainActor.run {
					completion(nil)
				}
			} catch {
				try? await handler.clean()
				await MainActor.run {
					completion(error)
				}
			}
		}
	}
	
	static func handleCertificateFiles(
		p12URL: URL,
		provisionURL: URL,
		p12Password: String,
		certificateName: String,
		completion: @escaping (Error?) -> Void
	) {
		Task.detached {
			let handler = CertificateFileHandler(
				key: p12URL,
				provision: provisionURL,
				password: p12Password,
				nickname: certificateName.isEmpty ? nil : certificateName
			)
			
			do {
				try await handler.copy()
				try await handler.addToDatabase()
				await MainActor.run {
					completion(nil)
				}
			} catch {
				await MainActor.run {
					completion(error)
				}
			}
		}
	}
	
	
	static func checkPasswordForCertificate(
		for key: URL,
		with password: String,
		using provision: URL
	) -> Bool {
		if _pkcs12PasswordIsValid(at: key, password: password) {
			return true
		}
		
		guard FileManager.default.fileExists(atPath: key.path),
			  FileManager.default.fileExists(atPath: provision.path) else {
			return false
		}
		
		defer {
			password_check_fix_WHAT_THE_FUCK_free(provision.path)
		}
		
		password_check_fix_WHAT_THE_FUCK(provision.path)
		
		if (!p12_password_check(key.path, password)) {
			return false
		}
		
		return true
	}
	
	private static func _pkcs12PasswordIsValid(at url: URL, password: String) -> Bool {
		guard let data = try? Data(contentsOf: url), data.count > 32 else { return false }
		let options = [kSecImportExportPassphrase as String: password] as CFDictionary
		var items: CFArray?
		return SecPKCS12Import(data as CFData, options, &items) == errSecSuccess
	}
	
	static func checkPasswordForCertificateData(
		p12Data: Data,
		provisionData: Data,
		password: String
	) -> Bool {
		let tempDir = FileManager.default.temporaryDirectory
		let tempP12 = tempDir.appendingPathComponent("temp_cert.p12")
		let tempProvision = tempDir.appendingPathComponent("temp_provision.mobileprovision")
		
		defer {
			try? FileManager.default.removeItem(at: tempP12)
			try? FileManager.default.removeItem(at: tempProvision)
		}
		
		do {
			try p12Data.write(to: tempP12)
			try provisionData.write(to: tempProvision)
			
			return checkPasswordForCertificate(for: tempP12, with: password, using: tempProvision)
		} catch {
			print("Error creating temporary files for password check: \(error)")
			return false
		}
	}
	
	static func movePairing(_ url: URL) {
		let fileManager = FileManager.default
		let dest = URL.documentsDirectory.appendingPathComponent("pairingFile.plist")

		try? fileManager.removeFileIfNeeded(at: dest)
		
		try? fileManager.copyItem(at: url, to: dest)
		
		HeartbeatManager.shared.start(true)
	}
	
	#if SERVER
	static func downloadSSLCertificates(
		from urlString: String,
		completion: @escaping (Bool) -> Void
	) {
		let generator = UINotificationFeedbackGenerator()
		generator.prepare()
		
		NBFetchService().fetch(from: urlString) { (result: Result<ServerPackModel, Error>) in
			switch result {
			case .success(let pack):
				do {
					let serverDir = URL.documentsDirectory.appendingPathComponent("App").appendingPathComponent("Server")
					let pemURL = serverDir.appendingPathComponent("server.pem")
					let crtURL = serverDir.appendingPathComponent("server.crt")
					let commonNameURL = serverDir.appendingPathComponent("commonName.txt")
					
					try FileManager.default.createDirectoryIfNeeded(at: serverDir)
					try pack.key.write(to: pemURL, atomically: true, encoding: .utf8)
					try pack.cert.write(to: crtURL, atomically: true, encoding: .utf8)
					try pack.info.domains.commonName.write(to: commonNameURL, atomically: true, encoding: .utf8)
					
					generator.notificationOccurred(.success)
					completion(true)
				} catch {
					completion(false)
				}
			case .failure(_):
				completion(false)
			}
		}
	}
	#endif
	
	static func handleSource(
		_ urlString: String,
		silent: Bool = false,
		competion: @escaping () -> Void
	) {
		guard let url = URL(string: urlString) else { return }
		
		NBFetchService().fetch<ASRepository>(from: url) { (result: Result<ASRepository, Error>) in
			switch result {
			case .success(let data):
				let id = data.id ?? url.absoluteString
				
				if !Storage.shared.sourceExists(id) {
					Storage.shared.addSource(url, repository: data, id: id) { _ in
						competion()
					}
				} else if !silent {
					DispatchQueue.main.async {
						UIAlertController.showAlertWithOk(title: "Error", message: "Repository already added.")
					}
				}
			case .failure(let error):
				if !silent {
					DispatchQueue.main.async {
						UIAlertController.showAlertWithOk(title: "Error", message: error.localizedDescription)
					}
				} else {
					print("DefianceSign: skipped built-in source \(urlString): \(error.localizedDescription)")
				}
			}
		}
	}
}

private enum CertificateHandlerError: Error {
	case invalidCertificate
}
