//
//  MapleSignBrandHeader.swift
//  MapleSign
//

import SwiftUI

struct MapleSignBrandHeader: View {
	var subtitle: String? = nil
	var compact: Bool = false

	var body: some View {
		HStack(spacing: compact ? 10 : 14) {
			Image("MapleSignLogo")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: compact ? 36 : 48, height: compact ? 36 : 48)
				.clipShape(RoundedRectangle(cornerRadius: compact ? 8 : 11, style: .continuous))
				.shadow(color: Color.mapleAccent.opacity(0.35), radius: 8, y: 4)

			VStack(alignment: .leading, spacing: 2) {
				Text("MapleSign")
					.font(compact ? .headline : .title2)
					.fontWeight(.bold)
					.foregroundStyle(Color.mapleAccent)

				if let subtitle {
					Text(subtitle)
						.font(.caption)
						.foregroundStyle(.secondary)
				} else {
					Text("Veilig signen op je device")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}

			Spacer(minLength: 0)
		}
		.padding(.vertical, compact ? 4 : 8)
	}
}

extension Color {
	static let mapleAccent = Color(red: 196/255, green: 92/255, blue: 38/255)
	static let mapleBackground = Color(red: 15/255, green: 20/255, blue: 25/255)
	static let mapleSurface = Color(red: 26/255, green: 34/255, blue: 45/255)
}
