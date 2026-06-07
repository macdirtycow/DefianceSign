//
//  DefianceSignLocale.swift
//  DefianceSign
//

import Foundation

enum DefianceSignLocale {
	/// Force English UI regardless of device language (matches v1.0.0 English catalog).
	static func applyEnglish() {
		UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
		UserDefaults.standard.set(["en"], forKey: "AppleLocale")
		UserDefaults.standard.synchronize()
	}
}
