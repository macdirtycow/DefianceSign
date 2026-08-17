//
//  Storage+Certificate.swift
//  Feather
//
//  Created by samara on 16.04.2025.
//

import CoreData
import UIKit.UIImpactFeedbackGenerator
import ZsignSwift

// MARK: - Class extension: certificate
extension Storage {
	func addCertificate(
		uuid: String,
		password: String? = nil,
		nickname: String? = nil,
		ppq: Bool = false,
		expiration: Date,
		p12Data: Data? = nil,
		provisionData: Data? = nil,
		completion: @escaping (Error?) -> Void
	) {
		let work = {
			let generator = UIImpactFeedbackGenerator(style: .light)
			
			let new = CertificatePair(context: self.context)
			new.uuid = uuid
			new.date = Date()
			new.password = password
			if let password {
				KeychainService.savePassword(password, for: uuid)
			}
			new.ppQCheck = ppq
			new.expiration = expiration
			new.nickname = nickname
			new.revoked = false
			new.p12Data = p12Data
			new.provisionData = provisionData
			
			self.saveContext()
			generator.impactOccurred()
			completion(nil)
		}
		
		if Thread.isMainThread {
			work()
		} else {
			DispatchQueue.main.async(execute: work)
		}
	}
	
	func revokagedCertificate(for cert: CertificatePair) {
		guard !cert.revoked else { return }
		print("Checking revokage for \(cert.nickname ?? "Unknown")")
		
		let provisionPath = getFile(.provision, from: cert)?.path ?? ""
		let p12Path = getFile(.certificate, from: cert)?.path ?? ""
		let password = certificatePassword(for: cert)
		
		guard !provisionPath.isEmpty, !p12Path.isEmpty else { return }
		
		Zsign.checkRevokage(
			provisionPath: provisionPath,
			p12Path: p12Path,
			p12Password: password
		) { (status, _, _) in
			if status == 1 {
				DispatchQueue.main.async {
					cert.revoked = true
					Storage.shared.saveContext()
				}
			}
		}
	}
	
	func getProvisionFileDecoded(for cert: CertificatePair) -> Certificate? {
		if let url = getFile(.provision, from: cert) {
			if let decoded = CertificateReader(url).decoded {
				return decoded
			}
		}
		
		if let data = cert.provisionData {
			return CertificateReader.parseData(data)
		}
		
		return nil
	}
	
	func deleteCertificate(for cert: CertificatePair) {
		performOnContext {
			do {
				if let uuid = cert.uuid {
					KeychainService.deletePassword(for: uuid)
				}
				if cert.p12Data == nil && cert.provisionData == nil {
					if let url = self.getUuidDirectory(for: cert) {
						try FileManager.default.removeItem(at: url)
					}
				} else if let url = self.getUuidDirectory(for: cert) {
					try? FileManager.default.removeItem(at: url)
				}
				self.context.delete(cert)
				self.saveContext()
			} catch {
				print(error)
			}
		}
	}
	
	enum FileRequest: String {
		case certificate = "p12"
		case provision = "mobileprovision"
	}
	
	func getFile(_ type: FileRequest, from cert: CertificatePair) -> URL? {
		if let url = getUuidDirectory(for: cert),
		   let existing = FileManager.default.getPath(in: url, for: type.rawValue) {
			return existing
		}
		
		guard let uuid = cert.uuid else { return nil }
		let blob: Data?
		switch type {
		case .certificate: blob = cert.p12Data
		case .provision: blob = cert.provisionData
		}
		guard let blob else { return nil }
		
		let destDir = FileManager.default.certificates(uuid)
		try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
		let dest = destDir.appendingPathComponent("cert.\(type.rawValue)")
		if !FileManager.default.fileExists(atPath: dest.path) {
			try? blob.write(to: dest)
		}
		return FileManager.default.fileExists(atPath: dest.path) ? dest : nil
	}
	
	func getUuidDirectory(for cert: CertificatePair) -> URL? {
		guard let uuid = cert.uuid else {
			return nil
		}
		
		return FileManager.default.certificates(uuid)
	}
}
