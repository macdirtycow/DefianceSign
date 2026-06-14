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
			let patchKey = "patchNotesShown_\(Bundle.main.version)"
			if !UserDefaults.standard.bool(forKey: patchKey) {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					_showPatchNotes()
					UserDefaults.standard.set(true, forKey: patchKey)
				}
			}
		}
	}
	
	private func _showPatchNotes() {
		UIAlertController.showAlertWithOk(
			title: .localized("DefianceSign \(Bundle.main.version)"),
			message: .localized("What's new in v1.1.4:\n\n- Refreshed Settings header and About screen\n- Donate via PayPal (Settings & About)\n- Install without Mac link in Settings\n- Powered by Qadbak & Omiiba credits\n\nDefianceSign remains open source — import your own certificate and sign IPAs on-device."),
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
