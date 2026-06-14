//
//  AboutNyaView.swift
//  DefianceSign
//
//  Created by Nagata Asami on 23/5/25.
//

import SwiftUI
import NimbleViews
import NimbleJSON

// MARK: - View
struct AboutNyaView: View {
	private let _dataService = NBFetchService()
	
	@State private var shouldShowPatchNotes = false
	
	// MARK: Body
	var body: some View {
		NBList(.localized("About")) {
            Section {
                VStack(spacing: 14) {
					ZStack {
						Circle()
							.fill(
								RadialGradient(
									colors: [
										Color.defianceAccent.opacity(0.35),
										Color.defianceAccent.opacity(0.05)
									],
									center: .center,
									startRadius: 4,
									endRadius: 56
								)
							)
							.frame(width: 112, height: 112)

                    Image("DefianceSignLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
					}

                    Text("DefianceSign")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 4) {
                        Text("Version")
                        Text(Bundle.main.version)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    
                    Button {
                        _showPatchNotes()
                    } label: {
                        Text("Show patch notes").bg()
                    }
                    .font(.footnote)
                    .padding(.top, 2)
                    .tint(.accent)
                }
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(EmptyView())
			
			NBSection(.localized("Credits")) {
				_credit(name: "DefianceSign", desc: "Project", github: "macdirtycow")
			}

			Section {
				Button {
					UIApplication.shared.open(DefianceSignConfig.donationURL)
				} label: {
					Label(.localized("Donate"), systemImage: "heart.fill")
				}
			}

			Section {
				DefianceSignPoweredByFooter()
			}
			.listRowBackground(Color.clear)
			
			NBSection("Special thanks!") {
				Group {
					Text(.localized("Based on Feather and Ksign — open-source sideloading tools."))
						.foregroundStyle(.secondary)
						.padding(.vertical, 2)
				}
				.transition(.slide)
			}
            
            NBSection("Acknowledgements") {
                NavigationLink(destination: AboutView()) {
                    HStack {
                        Text("About the original Feather")
                        Spacer()
                    }
                }
            } footer: {
                Text(Bundle.main.bundleIdentifier ?? "")
            }
		}
		.onAppear {
			// Show patch notes when navigating to this view if they haven't been shown before
			if !UserDefaults.standard.bool(forKey: "patchNotesShown") {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					_showPatchNotes()
					UserDefaults.standard.set(true, forKey: "patchNotesShown")
				}
			}
		}
	}
	
	private func _showPatchNotes() {
		UIAlertController.showAlertWithOk(
			title: .localized("DefianceSign \(Bundle.main.version)"),
			message: .localized("DefianceSign is a secure, open-source IPA signer for iPhone and iPad.\n\n- Import your own Apple Developer certificate\n- Sign and install IPA files on-device\n- No bundled certificates or telemetry\n- Based on Feather and Ksign"),
			isCancel: true,
			thankYou: true
		)
	}
}

// MARK: - Extension: view
extension AboutNyaView {
	@ViewBuilder
	private func _credit(
		name: String?,
		desc: String?,
		github: String
	) -> some View {
		FRIconCellView(
			title: name ?? github,
			subtitle: desc ?? "",
			iconUrl: URL(string: "https://github.com/\(github).png")!,
			trailing: AnyView(
				Image(systemName: "arrow.up.right")
					.foregroundStyle(.secondary)
			)
		)
		.onTapGesture {
			if let url = URL(string: "https://github.com/\(github)") {
				UIApplication.shared.open(url)
			}
		}
	}
}
