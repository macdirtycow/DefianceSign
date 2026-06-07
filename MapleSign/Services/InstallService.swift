//
//  InstallService.swift
//  MapleSign
//
//  Installation method selection for on-device IPA installs.
//

import Foundation

enum InstallMethod: Int {
	case server = 0
	case idevice = 1

	static var current: InstallMethod {
		let raw = UserDefaults.standard.integer(forKey: "Feather.installationMethod")
		return InstallMethod(rawValue: raw) ?? .server
	}
}

enum InstallService {
	static var methodDescription: String {
		switch InstallMethod.current {
		case .server:
			return String.localized("Uses a local HTTPS server and itms-services:// to install signed IPAs.")
		case .idevice:
			return String.localized("Uses VPN tunnel and AFC to install directly via installd.")
		}
	}
}
