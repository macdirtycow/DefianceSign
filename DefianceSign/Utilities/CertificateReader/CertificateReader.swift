//
//  CertificateReader.swift
//  Feather
//
//  Created by samara on 16.04.2025.
//

import Foundation

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
	
	static func parseData(_ data: Data) -> Certificate? {
		guard let plistData = extractPlist(from: data) else {
			print("Provisioning profile plist not found")
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
	
	/// CMS-wrapped .mobileprovision files must not be fed raw to PropertyListDecoder:
	/// the XML parser on iOS 16.1.x aborts on the CMS trailer and on the Apple DTD.
	static func extractPlist(from data: Data) -> Data? {
		if data.starts(with: Data("bplist".utf8)) {
			return data
		}
		guard let xml = xmlPlist(from: data) else { return nil }
		return binaryPlist(fromXML: xml) ?? xml
	}
	
	private static func xmlPlist(from data: Data) -> Data? {
		let xmlStart = Data("<?xml".utf8)
		let plistStart = Data("<plist".utf8)
		let xmlEnd = Data("</plist>".utf8)
		
		let start = data.range(of: xmlStart) ?? data.range(of: plistStart)
		guard let start else { return nil }
		guard let end = data.range(of: xmlEnd, in: start.lowerBound..<data.endIndex) else {
			return nil
		}
		
		var xml = data.subdata(in: start.lowerBound..<end.upperBound)
		if var text = String(data: xml, encoding: .utf8) ?? String(data: xml, encoding: .ascii) {
			while let doctype = text.range(of: "<!DOCTYPE", options: .caseInsensitive),
				  let close = text[doctype.lowerBound...].range(of: ">") {
				text.removeSubrange(doctype.lowerBound...close.upperBound)
			}
			if let utf8 = text.data(using: .utf8) {
				xml = utf8
			}
		}
		return xml
	}
	
	private static func binaryPlist(fromXML xml: Data) -> Data? {
		guard let object = try? PropertyListSerialization.propertyList(from: xml, options: [], format: nil) else {
			return nil
		}
		return try? PropertyListSerialization.data(fromPropertyList: object, format: .binary, options: 0)
	}
}
