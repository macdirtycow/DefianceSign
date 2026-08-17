//
//  CertificateReader.swift
//  Feather
//
//  Created by samara on 16.04.2025.
//

import UIKit

class CertificateReader: NSObject {
	let file: URL?
	var decoded: Certificate?
	
	init(_ file: URL?) {
		self.file = file
		super.init()
		self.decoded = self._readAndDecode()
	}
	
	private func _readAndDecode() -> Certificate? {
		guard let file = file else { return nil }
		
		do {
			let fileData = try Data(contentsOf: file)
			return Self.parseData(fileData)
		} catch {
			print("Error reading certificate file: \(error.localizedDescription)")
			return nil
		}
	}
	
	// Static method to parse certificate data directly
	static func parseData(_ data: Data) -> Certificate? {
		guard let plistData = extractPlist(from: data) else {
			print("XML start not found")
			return nil
		}
		
		do {
			let decoder = PropertyListDecoder()
			return try decoder.decode(Certificate.self, from: plistData)
		} catch {
			print("Error extracting certificate: \(error.localizedDescription)")
			return nil
		}
	}
	
	/// CMS-wrapped .mobileprovision files have a binary signature after `</plist>`.
	/// Feeding that trailer to PropertyListDecoder crashes the XML parser on iOS 16.1.x.
	static func extractPlist(from data: Data) -> Data? {
		let xmlStart = Data("<?xml".utf8)
		let xmlEnd = Data("</plist>".utf8)
		
		if let start = data.range(of: xmlStart) {
			if let end = data.range(of: xmlEnd, in: start.lowerBound..<data.endIndex) {
				return data.subdata(in: start.lowerBound..<end.upperBound)
			}
			return data.subdata(in: start.lowerBound..<data.endIndex)
		}
		
		if data.starts(with: Data("bplist".utf8)) {
			return data
		}
		
		return nil
	}
}
