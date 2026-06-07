//
//  DefianceSignConfig.swift
//  DefianceSign
//

import Foundation

struct OptionalLibrarySource: Identifiable {
	let id: String
	let name: String
	let url: String
	let description: String
}

enum DefianceSignConfig {
	static let bundleIdentifier = "net.defiancesign.app"
	static let website = "https://defiancesign.com"
	static let githubRepo = "https://github.com/macdirtycow/DefianceSign"
	static let altStoreRepo = "https://raw.githubusercontent.com/macdirtycow/DefianceSign/refs/heads/main/repo.json"
	static let plistProxyBase = "https://api.palera.in/genPlist"
	static let sslPackURL = "https://backloop.dev/pack.json"

	/// Optional community sources from Feather/Ksign forks — user adds manually.
	static let optionalLibrarySources: [OptionalLibrarySource] = [
		OptionalLibrarySource(
			id: "ksign",
			name: "Ksign Apps",
			url: "https://raw.githubusercontent.com/Nyasami/Ksign/refs/heads/main/repo.json",
			description: "Apps from the Ksign community repo"
		),
		OptionalLibrarySource(
			id: "feather",
			name: "Feather Apps",
			url: "https://github.com/khcrysalis/Feather/raw/main/app-repo.json",
			description: "Curated apps from the Feather project"
		),
		OptionalLibrarySource(
			id: "sidecommunity",
			name: "SideStore Community",
			url: "https://community-apps.sidestore.io/sidecommunity.json",
			description: "Popular community apps for sideloading"
		),
		OptionalLibrarySource(
			id: "apptesters",
			name: "AppTesters",
			url: "https://repository.apptesters.org",
			description: "Beta and tweaked apps from AppTesters"
		),
	]
}
