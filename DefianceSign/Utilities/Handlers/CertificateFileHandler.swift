//
//  CertificateFileHandler.swift
//  Feather
//
//  Created by samara on 15.04.2025.
//

import Foundation

final class CertificateFileHandler: NSObject {
	private let _fileManager = FileManager.default
	private let _uuid = UUID().uuidString
	
	private let _key: URL
	private let _provision: URL
	private let _keyPassword: String?
	private let _certNickname: String?
	
	private var _certPair: Certificate?
	private var _p12Data: Data?
	private var _provisionData: Data?
	
	init(
		key: URL,
		provision: URL,
		password: String? = nil,
		nickname: String? = nil
	) {
		self._key = key
		self._provision = provision
		self._keyPassword = password
		self._certNickname = nickname
		
		self._p12Data = try? Data(contentsOf: key)
		self._provisionData = try? Data(contentsOf: provision)
		self._certPair = nil
		
		super.init()
	}
	
	func copy() async throws {
		guard _certPair != nil || _provisionData != nil else {
			throw CertificateFileHandlerError.certNotValid
		}
		
		let destinationURL = try await _directory()
		try _fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
		
		let p12Dest = destinationURL.appendingPathComponent("cert.p12")
		let provisionDest = destinationURL.appendingPathComponent("cert.mobileprovision")
		
		if let p12Data = _p12Data {
			try p12Data.write(to: p12Dest)
		} else {
			try _fileManager.copyItem(at: _key, to: p12Dest)
			_p12Data = try? Data(contentsOf: p12Dest)
		}
		
		if let provisionData = _provisionData {
			try provisionData.write(to: provisionDest)
		} else {
			try _fileManager.copyItem(at: _provision, to: provisionDest)
			_provisionData = try? Data(contentsOf: provisionDest)
		}
	}
	
	func addToDatabase() async throws {
		if _certPair == nil, let provisionData = _provisionData {
			_certPair = await Task { @MainActor in
				CertificateReader.parseData(provisionData)
			}.value
		}
		
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			Storage.shared.addCertificate(
				uuid: _uuid,
				password: _keyPassword,
				nickname: _certNickname,
				ppq: _certPair?.PPQCheck ?? false,
				expiration: _certPair?.ExpirationDate ?? Date(),
				p12Data: _p12Data,
				provisionData: _provisionData
			) { error in
				if let error {
					continuation.resume(throwing: error)
				} else {
					print("[\(self._uuid)] Added to database")
					continuation.resume()
				}
			}
		}
	}
	
	private func _directory() async throws -> URL {
		_fileManager.certificates(_uuid)
	}
}

private enum CertificateFileHandlerError: Error {
	case certNotValid
}
