//
//  Certificate.swift
//  feather
//
//  Created by samara on 5/18/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import Foundation

// MARK: - Certificate (Mobileprovision file)
struct Certificate: Codable {
	var AppIDName: String
	var ApplicationIdentifierPrefix: [String]?
	var CreationDate: Date
	var Platform: [String]
	var IsXcodeManaged: Bool?
	var DeveloperCertificates: [Data]?
	var derEncodedProfile: Data?
	var PPQCheck: Bool?
	var Entitlements: [String: AnyCodable]?
	var ExpirationDate: Date
	var Name: String
	var ProvisionsAllDevices: Bool?
	var ProvisionedDevices: [String]?
	var TeamIdentifier: [String]
	var TeamName: String
	var TimeToLive: Int
	var UUID: String
	var Version: Int

	enum CodingKeys: String, CodingKey {
		case AppIDName
		case ApplicationIdentifierPrefix
		case CreationDate
		case Platform
		case IsXcodeManaged
		case DeveloperCertificates
		case PPQCheck
		case Entitlements
		case ExpirationDate
		case Name
		case ProvisionsAllDevices
		case ProvisionedDevices
		case TeamIdentifier
		case TeamName
		case TimeToLive
		case UUID
		case Version
		case derEncodedProfile = "DER-Encoded-Profile"
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		AppIDName = try container.decodeIfPresent(String.self, forKey: .AppIDName) ?? "Unknown"
		ApplicationIdentifierPrefix = try container.decodeIfPresent([String].self, forKey: .ApplicationIdentifierPrefix)
		CreationDate = try container.decodeIfPresent(Date.self, forKey: .CreationDate) ?? Date()
		
		if let platforms = try? container.decode([String].self, forKey: .Platform) {
			Platform = platforms
		} else if let platform = try? container.decode(String.self, forKey: .Platform) {
			Platform = [platform]
		} else {
			Platform = []
		}
		
		IsXcodeManaged = try container.decodeIfPresent(Bool.self, forKey: .IsXcodeManaged)
		DeveloperCertificates = try container.decodeIfPresent([Data].self, forKey: .DeveloperCertificates)
		derEncodedProfile = try container.decodeIfPresent(Data.self, forKey: .derEncodedProfile)
		PPQCheck = try container.decodeIfPresent(Bool.self, forKey: .PPQCheck)
		Entitlements = try? container.decode([String: AnyCodable].self, forKey: .Entitlements)
		ExpirationDate = try container.decodeIfPresent(Date.self, forKey: .ExpirationDate) ?? Date()
		Name = try container.decodeIfPresent(String.self, forKey: .Name) ?? "Unknown"
		ProvisionsAllDevices = try container.decodeIfPresent(Bool.self, forKey: .ProvisionsAllDevices)
		ProvisionedDevices = try container.decodeIfPresent([String].self, forKey: .ProvisionedDevices)
		TeamIdentifier = try container.decodeIfPresent([String].self, forKey: .TeamIdentifier) ?? []
		TeamName = try container.decodeIfPresent(String.self, forKey: .TeamName) ?? "Unknown"
		TimeToLive = try container.decodeIfPresent(Int.self, forKey: .TimeToLive) ?? 0
		UUID = try container.decodeIfPresent(String.self, forKey: .UUID) ?? ""
		Version = try container.decodeIfPresent(Int.self, forKey: .Version) ?? 0
	}
}
