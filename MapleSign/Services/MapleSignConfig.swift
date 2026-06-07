//
//  MapleSignConfig.swift
//  MapleSign
//

import Foundation

enum MapleSignConfig {
	static let bundleIdentifier = "net.maplesign.app"
	static let website = "https://maplesign.net"
	static let githubRepo = "https://github.com/macdirtycow/MapleSign"
	static let altStoreRepo = "https://raw.githubusercontent.com/macdirtycow/MapleSign/refs/heads/main/repo.json"
	/// Semi-local install manifest proxy. Switch to maplesign.net when EU endpoint is deployed.
	static let plistProxyBase = "https://api.palera.in/genPlist"
	static let sslPackURL = "https://backloop.dev/pack.json"
}
