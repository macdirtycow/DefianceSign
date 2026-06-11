//
//  DefianceSignBrandHeader.swift
//  DefianceSign
//

import SwiftUI

struct DefianceSignBrandHeader: View {
	var subtitle: String? = nil
	var compact: Bool = false

	var body: some View {
		HStack(spacing: compact ? 10 : 14) {
			Image("DefianceSignLogo")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: compact ? 36 : 48, height: compact ? 36 : 48)
				.clipShape(RoundedRectangle(cornerRadius: compact ? 8 : 11, style: .continuous))
				.shadow(color: Color.defianceAccent.opacity(0.18), radius: 6, y: 2)

			VStack(alignment: .leading, spacing: 2) {
				Text("DefianceSign")
					.font(compact ? .headline : .title2)
					.fontWeight(.semibold)
					.foregroundStyle(.primary)

				if let subtitle {
					Text(subtitle)
						.font(.caption)
						.foregroundStyle(.secondary)
				} else {
					Text("Secure on-device IPA signing")
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
	static let defianceAccent = Color(red: 123/255, green: 159/255, blue: 232/255)
	static let defianceBackground = Color(red: 10/255, green: 10/255, blue: 15/255)
	static let defianceSurface = Color(red: 22/255, green: 18/255, blue: 28/255)
}
