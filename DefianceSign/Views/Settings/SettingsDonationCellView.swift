//
//  SettingsDonationCellView.swift
//  DefianceSign
//

import SwiftUI
import NimbleViews

struct SettingsDonationCellView: View {
	var body: some View {
		Section {
			VStack(spacing: 16) {
				_header()

				_benefit(
					.localized("Keep it free & open"),
					.localized("DefianceSign is open source. Donations help pay for hosting, certificates, and future updates."),
					systemName: "heart.fill"
				)

				_benefit(
					.localized("Can't donate?"),
					.localized("Star the repo or tell a friend — that helps just as much."),
					systemName: "star.fill"
				)

				VStack(spacing: 10) {
					_primaryButton(
						.localized("Donate"),
						systemName: "gift.fill",
						url: DefianceSignConfig.donationURL
					)
					_secondaryButton(
						.localized("Star on GitHub"),
						systemName: "star",
						url: DefianceSignConfig.githubRepoURL
					)
				}
				.padding(.top, 4)
			}
			.padding(.vertical, 10)
		}
		.listRowBackground(Color.clear)
		.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
	}

	@ViewBuilder
	private func _header() -> some View {
		VStack(spacing: 10) {
			ZStack {
				Circle()
					.fill(
						RadialGradient(
							colors: [
								Color.defianceAccent.opacity(0.3),
								Color.defianceAccent.opacity(0.04)
							],
							center: .center,
							startRadius: 2,
							endRadius: 42
						)
					)
					.frame(width: 72, height: 72)

				Image("DefianceSignLogo")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 52, height: 52)
					.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
			}

			Text(.localized("Support DefianceSign"))
				.font(.title3.weight(.semibold))

			Text(.localized("Powered by volunteers — your support keeps the installer online."))
				.font(.caption)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 8)
		}
		.frame(maxWidth: .infinity)
	}

	@ViewBuilder
	private func _benefit(
		_ title: String,
		_ desc: String,
		systemName: String
	) -> some View {
		HStack(alignment: .top, spacing: 12) {
			Image(systemName: systemName)
				.font(.system(size: 22))
				.foregroundStyle(Color.defianceAccent)
				.frame(width: 28, alignment: .center)
				.padding(.top, 2)

			NBTitleWithSubtitleView(
				title: title,
				subtitle: desc,
				linelimit: 0
			)
		}
		.padding(12)
		.background {
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(Color.defianceSurface.opacity(0.55))
				.overlay {
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
				}
		}
	}

	@ViewBuilder
	private func _primaryButton(_ title: String, systemName: String, url: URL) -> some View {
		Button {
			UIApplication.shared.open(url)
		} label: {
			Label(title, systemImage: systemName)
				.font(.subheadline.weight(.semibold))
				.frame(maxWidth: .infinity)
				.frame(height: 44)
				.background(
					LinearGradient(
						colors: [Color.defianceAccent, Color.defianceAccent.opacity(0.75)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.foregroundStyle(.white)
				.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
		}
		.buttonStyle(.plain)
	}

	@ViewBuilder
	private func _secondaryButton(_ title: String, systemName: String, url: URL) -> some View {
		Button {
			UIApplication.shared.open(url)
		} label: {
			Label(title, systemImage: systemName)
				.font(.subheadline.weight(.medium))
				.frame(maxWidth: .infinity)
				.frame(height: 42)
				.background {
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
				}
		}
		.buttonStyle(.plain)
	}
}
