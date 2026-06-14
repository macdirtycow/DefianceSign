//
//  SettingsView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct SettingsView: View {
    @AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var _certificates: FetchedResults<CertificatePair>
    
    private var selectedCertificate: CertificatePair? {
        guard
            _storedSelectedCert >= 0,
            _storedSelectedCert < _certificates.count
        else {
            return nil
        }
        return _certificates[_storedSelectedCert]
    }
    
    
	private let _githubUrl = DefianceSignConfig.githubRepo
	private let _websiteUrl = DefianceSignConfig.website
	// MARK: Body
    var body: some View {
		NBNavigationView(.localized("Settings")) {
			Form {
				Section {
					DefianceSignBrandHeader(subtitle: "v\(Bundle.main.version)")
				}
				.listRowBackground(Color.clear)
				.listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

				SettingsDonationCellView()

				_feedback()
				
				Section {
                    NavigationLink(destination: AppIconView()) {
                        Label(.localized("App Icon"), systemImage: "app.badge")
                    }
					NavigationLink(destination: AppearanceView()) {
                        Label(.localized("Appearance"), systemImage: "paintbrush")
                    }
				}
                
                NBSection(.localized("Certificates")) {
                    
                    if let cert = selectedCertificate {
                        CertificatesCellView(cert: cert)
                    } else {
                        Text(.localized("No Certificate"))
                            .font(.footnote)
                            .foregroundColor(.disabled())
                    }
                    NavigationLink(destination: CertificatesView()) {
                        Label(.localized("Certificates"), systemImage: "signature")
                    }
                 
                } footer: {
                    Text(.localized("Add and manage certificates used for signing applications."))
                }
				
				NBSection(.localized("Features")) {
                    NavigationLink(destination: LogsView(manager: LogsManager.shared)) {
                        Label(.localized("Logs"), systemImage: "apple.terminal")
                    }
					NavigationLink(destination: AppFeaturesView()) {
                        Label(.localized("App Features"), systemImage: "sparkles")
                    }
					NavigationLink(destination: ConfigurationView()) {
                        Label(.localized("Signing Options"), systemImage: "gear")
                    }
					NavigationLink(destination: ArchiveView()) {
                        Label(.localized("Archive & Extraction"), systemImage: "archivebox")
                    }
					NavigationLink(destination: InstallationView()) {
                        Label(.localized("Installation"), systemImage: "server.rack")
                    }
				}
				
				_directories()
                
                Section {
                    NavigationLink(destination: ResetView()) {
                        Label(.localized("Reset"), systemImage: "trash")
                    }
                } footer: {
                    Text("Reset the applications sources, certificates, apps, and general contents.")
                }

				Section {
					DefianceSignPoweredByFooter()
				}
				.listRowBackground(Color.clear)
				.listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 12, trailing: 0))
			}
		}
    }
}

// MARK: - View extension
extension SettingsView {
	@ViewBuilder
	private func _feedback() -> some View {
		Section {
			NavigationLink(destination: AboutNyaView()) {
                Label(.localized("About"), systemImage: "info.circle")
            }
			Button(.localized("Website"), systemImage: "globe") {
				UIApplication.open(_websiteUrl)
			}
			Button(.localized("Install without Mac"), systemImage: "safari") {
				UIApplication.open(DefianceSignConfig.installURL)
			}
			Button(.localized("GitHub Repository"), systemImage: "chevron.left.forwardslash.chevron.right") {
				UIApplication.open(_githubUrl)
			}
		}
	}
	
	@ViewBuilder
	private func _directories() -> some View {
		NBSection(.localized("Misc")) {
			Button(.localized("Open Documents"), systemImage: "folder") {
				UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
			}
			Button(.localized("Open Archives"), systemImage: "folder") {
				UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!)
			}
		} footer: {
			Text(.localized("All of DefianceSign files except certificates are contained in the documents directory, here are some quick links to these."))
		}
	}
}
