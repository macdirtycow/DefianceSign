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
			ZStack {
				RoundedRectangle(cornerRadius: compact ? 10 : 13, style: .continuous)
					.fill(
						LinearGradient(
							colors: [
								Color.defianceAccent.opacity(0.22),
								Color.defianceAccent.opacity(0.06)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: compact ? 40 : 52, height: compact ? 40 : 52)

				Image("DefianceSignLogo")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: compact ? 30 : 40, height: compact ? 30 : 40)
					.clipShape(RoundedRectangle(cornerRadius: compact ? 7 : 9, style: .continuous))
			}

			VStack(alignment: .leading, spacing: 3) {
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
		.padding(compact ? 10 : 14)
		.background {
			RoundedRectangle(cornerRadius: 16, style: .continuous)
				.fill(Color.defianceSurface.opacity(0.55))
				.overlay {
					RoundedRectangle(cornerRadius: 16, style: .continuous)
						.strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
				}
		}
		.padding(.vertical, compact ? 2 : 4)
	}
}

struct DefianceSignPoweredByFooter: View {
	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Powered by")
				.font(.caption)
				.foregroundStyle(.tertiary)
				.textCase(.uppercase)
				.tracking(0.6)

			HStack(spacing: 10) {
				_partnerChip(title: "Qadbak", subtitle: "Hosting", url: DefianceSignConfig.qadbakURL)
				_partnerChip(title: "Omiiba", subtitle: "Software", url: DefianceSignConfig.omiibaURL)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.vertical, 4)
	}

	@ViewBuilder
	private func _partnerChip(title: String, subtitle: String, url: URL) -> some View {
		Button {
			UIApplication.shared.open(url)
		} label: {
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.subheadline.weight(.semibold))
					.foregroundStyle(.primary)
				Text(subtitle)
					.font(.caption2)
					.foregroundStyle(.secondary)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.horizontal, 12)
			.padding(.vertical, 10)
			.background {
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.fill(Color.defianceSurface.opacity(0.7))
					.overlay {
						RoundedRectangle(cornerRadius: 12, style: .continuous)
							.strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
					}
			}
		}
		.buttonStyle(.plain)
	}
}

extension Color {
	static let defianceAccent = Color(red: 123/255, green: 159/255, blue: 232/255)
	static let defianceBackground = Color(red: 10/255, green: 10/255, blue: 15/255)
	static let defianceSurface = Color(red: 22/255, green: 18/255, blue: 28/255)
}
